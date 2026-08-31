#!/etc/profiles/per-user/Reiky-REI/bin/python3
# -*- coding: utf-8 -*-
"""kb-mcp -- NixMEOW 知识库语义检索 MCP server (stdio, 纯标准库)
后端: llama.cpp Qwen3-VL-Embedding-2B (:8081/v1/embeddings)
      + Qwen3-VL-Reranker-2B   (:8082/v1/rerank)
语料: 多根上下文感知 -- KB_ROOT env > cwd 向上最近有效 .agents > 回落
      /etc/nixos 系统库; 收录顶层 AGENTS/SKILLS/MEMORY/CLAUDE.md +
      knowledge/** 与 memory/** 全部 md (frontmatter 感知分块)
管线: 混合召回(向量余弦 top40 + BM25 top20) -> reranker 精排 -> top-k
缓存: tools/kb-mcp/index/index.json (源文件 mtime 签名自动失效重建)
"""
import json, sys, os, re, math, time, base64, array, urllib.request, urllib.error

def _resolve_root():
    # KB 根解析: KB_ROOT env > cwd 向上最近有效 .agents > 回落 /etc/nixos
    env = os.environ.get("KB_ROOT")
    if env:
        return env.rstrip("/")
    d = os.getcwd()
    while True:
        ag = os.path.join(d, ".agents")
        if (os.path.isdir(ag)
                and (os.path.isfile(os.path.join(ag, "AGENTS.md"))
                     or os.path.isdir(os.path.join(ag, "knowledge")))):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return "/etc/nixos"
        d = parent

ROOT      = _resolve_root()
AG        = os.path.join(ROOT, ".agents")
CACHE_DIR = os.environ.get("KB_CACHE_DIR") or os.path.join(AG, "tools", "kb-mcp", "index")
CACHE     = os.path.join(CACHE_DIR, "index.json")
EMBED_URL = os.environ.get("KB_EMBED_URL",  "http://127.0.0.1:8081/v1/embeddings")
RERANK_URL= os.environ.get("KB_RERANK_URL", "http://127.0.0.1:8082/v1/rerank")
def _collect_sources():
    # 通用语料发现: 顶层章程文件 + knowledge/** 与 memory/** 全部 .md(跳过隐藏)
    out = []
    for pat in ["AGENTS.md", "SKILLS.md", "MEMORY.md", "CLAUDE.md",
                "knowledge", "memory"]:
        p = os.path.join(AG, pat)
        if os.path.isdir(p):
            for dirpath, dirnames, filenames in os.walk(p):
                dirnames[:] = sorted(x for x in dirnames if not x.startswith("."))
                for fn in sorted(filenames):
                    if fn.endswith(".md") and not fn.startswith("."):
                        out.append(os.path.relpath(os.path.join(dirpath, fn), AG))
        elif os.path.isfile(p):
            out.append(pat)
    return sorted(set(out))

SOURCES = _collect_sources()
MAX_SNIPPET = 240
STATE = {"chunks": [], "vecs": None, "dim": 0, "bm25": None}

def log(*a):
    print(*a, file=sys.stderr)

# ---------- 语料扫描 ----------
def parse_front(text):
    meta = {}
    if text.startswith("---"):
        m = re.match(r"^---\s*\n(.*?)\n---\s*\n?", text, re.S)
        if m:
            for ln in m.group(1).splitlines():
                if ":" in ln:
                    k, v = ln.split(":", 1)
                    k, v = k.strip(), v.strip()
                    if v.startswith("[") and v.endswith("]"):
                        meta[k] = [x.strip().strip("\"'") for x in v[1:-1].split(",") if x.strip()]
                    else:
                        meta[k] = v.strip("\"'")
            text = text[m.end():]
    return meta, text

def split_long(txt, cap=1500):
    if len(txt) <= cap * 1.4:
        return [txt]
    paras, out, buf = txt.split("\n\n"), [], ""
    for p in paras:
        if buf and len(buf) + len(p) > cap:
            out.append(buf); buf = p
        else:
            buf = (buf + "\n\n" + p) if buf else p
    if buf: out.append(buf)
    return out

def chunks_of(rel, raw):
    meta, body = parse_front(raw)
    lines = body.splitlines()
    secs, cur = [], {"h": "(intro)", "buf": []}
    for ln in lines:
        if re.match(r"^#{2,3}\s+\S", ln):
            secs.append(cur); cur = {"h": ln.lstrip("#").strip(), "buf": [ln]}
        else:
            cur["buf"].append(ln)
    secs.append(cur)
    out = []
    for s in secs:
        txt = "\n".join(s["buf"]).strip()
        if not txt or (len(txt) < 40 and s["h"] == "(intro)"):
            continue
        for piece in split_long(txt):
            out.append({"file": rel, "heading": s["h"], "meta": meta, "text": piece})
    return out

def scan_sources():
    sig_items, all_chunks = [], []
    for src in SOURCES:
        p = os.path.join(AG, src)
        if os.path.isdir(p):
            for fn in sorted(os.listdir(p)):
                if not fn.endswith(".md"): continue
                fp = os.path.join(p, fn)
                st = os.stat(fp)
                sig_items.append("%s|%d|%d" % (src + "/" + fn, st.st_size, int(st.st_mtime)))
                all_chunks += chunks_of(os.path.relpath(fp, AG), open(fp, encoding="utf-8").read())
        elif os.path.isfile(p):
            st = os.stat(p)
            sig_items.append("%s|%d|%d" % (src, st.st_size, int(st.st_mtime)))
            all_chunks += chunks_of(src, open(p, encoding="utf-8").read())
    return hashlib_sig(sig_items), all_chunks

def hashlib_sig(items):
    import hashlib
    return hashlib.sha256("\n".join(items).encode()).hexdigest()[:16]

# ---------- HTTP ----------
def post_json(url, payload, timeout=120):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode())

def embed(texts):
    vecs, B = [], 12
    for i in range(0, len(texts), B):
        d = post_json(EMBED_URL, {"input": texts[i:i+B], "model": "qwen3"})
        vecs += [item["embedding"] for item in d["data"]]
    out = []
    for row in vecs:
        nrm = math.sqrt(sum(x * x for x in row)) or 1.0
        out.append([x / nrm for x in row])
    return out

def rerank(query, docs):
    if not docs: return []
    try:
        d = post_json(RERANK_URL, {"query": query, "documents": docs, "model": "qwen3-reranker"}, 90)
    except urllib.error.HTTPError as e:
        raise RuntimeError("rerank HTTP %d: %s" % (e.code, e.read().decode(errors="replace")[:200]))
    return [(r["index"], r["relevance_score"]) for r in d.get("results", [])]

# ---------- BM25 ----------
TOKEN_RE = re.compile(r"[a-zA-Z0-9_]+|[\u4e00-\u9fff]+")
def toks(s):
    out = []
    for w in TOKEN_RE.findall(s.lower()):
        if "\u4e00" <= w[0] <= "\u9fff":
            out += [w] if len(w) == 1 else [w[i:i+2] for i in range(len(w)-1)]
        elif len(w) > 1:
            out.append(w)
    return out

class BM25:
    def __init__(self, corpus_tokens):
        self.N = len(corpus_tokens)
        self.avgdl = (sum(len(t) for t in corpus_tokens) / max(self.N, 1)) or 1.0
        self.tf, self.df = [], {}
        for tk in corpus_tokens:
            f = {}
            for w in tk: f[w] = f.get(w, 0) + 1
            self.tf.append(f)
            for w in set(tk): self.df[w] = self.df.get(w, 0) + 1
        self.pre = {w: math.log(1 + (self.N - n + 0.5) / (n + 0.5)) for w, n in self.df.items()}
    def search_scored(self, q, topn=24):
        qt = {}
        for w in toks(q): qt[w] = qt.get(w, 0) + 1
        sc = []
        for i, f in enumerate(self.tf):
            dl = sum(f.values()) or 1
            s = sum(qn * self.pre.get(w, 0) * f.get(w, 0) * 2.5 / (f.get(w, 0) + 1.5 * (0.25 + 0.75 * dl / self.avgdl))
                    for w, qn in qt.items())
            if s > 0: sc.append((s, i))
        sc.sort(reverse=True)
        return sc[:topn]
    def search(self, q, topn=20):
        return [i for _, i in self.search_scored(q, topn)]

# ---------- 缓存 ----------
def load_cache():
    if STATE["chunks"]: return
    if os.path.exists(CACHE):
        try:
            d = json.load(open(CACHE))
            if d.get("sig") == current_sig:
                chunks = d["chunks"]
                vec = array.array("f"); vec.frombytes(base64.b64decode(d["vec"]))
                dim = d["dim"]
                if len(vec) == len(chunks) * dim:
                    STATE.update(chunks=chunks, dim=dim)
                    STATE["bm25"] = BM25([toks(c["file"] + " " + c["heading"] + " " + c["text"]) for c in chunks])
                    norm_rows(vec, dim)
                    return
        except Exception as e:
            log("cache load failed:", e)
    ingest()

def norm_rows(vec, dim):
    for r in range(len(vec) // dim):
        s = math.sqrt(sum(vec[r*dim+j]*vec[r*dim+j] for j in range(dim))) or 1.0
        for j in range(dim): vec[r*dim+j] /= s

current_sig = None

def ingest():
    global current_sig
    sig, chunks = scan_sources()
    current_sig = sig
    t0 = time.time()
    texts = [c["file"] + "\n" + c["heading"] + "\n" + c["text"] for c in chunks]
    log("embedding %d chunks ..." % len(texts))
    flat = embed(texts)
    dim = len(flat[0])
    vec = array.array("f", [x for row in flat for x in row])
    norm_rows(vec, dim)
    STATE.update(chunks=chunks, dim=dim)
    STATE["bm25"] = BM25([toks(c["file"] + " " + c["heading"] + " " + c["text"]) for c in chunks])
    os.makedirs(CACHE_DIR, exist_ok=True)
    tmp = CACHE + ".tmp"
    json.dump({"sig": sig, "dim": dim, "chunks": chunks,
               "vec": base64.b64encode(vec.tobytes()).decode(),
               "built_at": time.strftime("%Y-%m-%dT%H:%M:%S")},
              open(tmp, "w"))
    os.replace(tmp, CACHE)
    log("ingested %d chunks in %.1fs" % (len(chunks), time.time() - t0))

def ensure_fresh():
    global current_sig
    sig, _ = scan_sources()
    if STATE["chunks"] and sig != current_sig:
        log("sources changed, re-ingesting")
        ingest()
    else:
        current_sig = sig
        load_cache()

# ---------- 检索 ----------
def cosine_top(q, n):
    dim, vec, ch = STATE["dim"], STATE["_flat"], STATE["chunks"]
    best = []
    for r in range(len(ch)):
        off = r * dim
        s = 0.0
        for j in range(dim):
            s += vec[off + j] * q[j]
        best.append((s, r))
    best.sort(reverse=True)
    return best[:n]

def kb_search(args):
    ensure_fresh()
    q = args["query"].strip()
    k = int(args.get("k") or 6)
    mod = (args.get("module") or "").lower()
    tag = (args.get("tag") or "").lower()
    if not STATE["chunks"]:
        return "知识库为空: 请先运行 kb_ingest 或检查语料目录。"
    qv = embed([q])[0]
    flat = STATE["_flat"] = STATE.get("_flat") or load_flat()
    cos_pairs = cosine_top(qv, 48)
    bm_raw = STATE["bm25"].search_scored(q, 24)
    bmax = (max((s2 for s2, _ in bm_raw), default=0.0)) or 1.0
    fused = {}
    for s2, r in cos_pairs:
        fused[r] = 0.72 * s2
    for s2, r in bm_raw:
        fused[r] = fused.get(r, 0.0) + 0.28 * (s2 / bmax)
    fsmap, pool = {}, []
    for r, fs in sorted(fused.items(), key=lambda kv: -kv[1]):
        c = STATE["chunks"][r]; m = c.get("meta") or {}
        if mod and mod not in str(m.get("module", "")).lower() and mod not in c["file"].lower():
            continue
        if tag and tag not in " ".join(m.get("tags") or []).lower():
            continue
        pool.append(r); fsmap[r] = fs
        if len(pool) >= 12: break
    if not pool:
        return "过滤条件下无候选(module=%s tag=%s)。" % (mod, tag)
    note = ""
    try:
        rr = rerank(q, [STATE["chunks"][r]["text"][:1200] for r in pool])
        ranked = sorted(((sc, pool[i]) for i, sc in rr), reverse=True)[:k]
    except Exception as e:
        log("rerank failed, fallback to fused order:", e)
        note = "[!] rerank 端点异常(%s)，已按混合召回分排序\n" % e
        ranked = [(fsmap[r], r) for r in pool[:k]]
    lines = [note + "共 %d 候选 -> 精排 top %d:" % (len(pool), len(ranked))]
    for sc, r in ranked:
        c = STATE["chunks"][r]; m = c.get("meta") or {}
        snip = re.sub(r"\s+", " ", c["text"])[:MAX_SNIPPET]
        lines.append("[%0.3f] %s#%s" % (sc, c["file"], c["heading"]))
        mm = {x: m[x] for x in ("date", "module", "severity", "status") if x in m}
        if m.get("tags"): mm["tags"] = m["tags"]
        if mm: lines.append("  meta: %s" % json.dumps(mm, ensure_ascii=False))
        lines.append("  %s" % snip)
    return "\n".join(lines)

def load_flat():
    d = json.load(open(CACHE))
    vec = array.array("f"); vec.frombytes(base64.b64decode(d["vec"]))
    return vec

def kb_ingest(args):
    ingest()
    return "已重建索引: %d chunks, dim=%d" % (len(STATE["chunks"]), STATE["dim"])

def kb_stats(args):
    def health(url):
        try:
            req = urllib.request.Request(url.rsplit("/", 1)[0] + "/health")
            with urllib.request.urlopen(req, timeout=4) as r:
                return "ok(%d)" % r.status
        except Exception as e:
            return "DOWN(%s)" % e.__class__.__name__
    ensure_fresh()
    built = "?"
    try: built = json.load(open(CACHE)).get("built_at", "?")
    except Exception: pass
    return ("root=%s | corpus=%d chunks | dim=%d | index_built=%s\nembed %s | rerank %s"
            % (ROOT, len(STATE["chunks"]), STATE["dim"], built,
               health(EMBED_URL), health(RERANK_URL)))

TOOLS = [
    {"name": "kb_search",
     "description": "语义检索当前上下文知识库(cwd 向上最近 .agents 的经验体系,无则回落系统库): retros/decisions/known-issues/conventions/memory 等。混合向量+BM25 召回,Qwen3-Reranker 精排。查历史事故、既有决策、踩坑、用户偏好时优先用它而非盲猜。",
     "inputSchema": {"type": "object", "properties": {
         "query": {"type": "string", "description": "自然语言问题"},
         "k": {"type": "integer", "description": "返回条数,默认6"},
         "module": {"type": "string", "description": "按 frontmatter module 过滤"},
         "tag": {"type": "string", "description": "按 frontmatter tags 过滤"}},
         "required": ["query"]}},
    {"name": "kb_ingest",
     "description": "强制重建知识库向量索引(通常自动增量,无需手动调用)。",
     "inputSchema": {"type": "object", "properties": {}}},
    {"name": "kb_stats",
     "description": "知识库状态: chunk 数/维度/索引时间/embedding 与 reranker 端点健康。",
     "inputSchema": {"type": "object", "properties": {}}},
]

def dispatch(name, args):
    if name == "kb_search": return kb_search(args or {})
    if name == "kb_ingest": return kb_ingest(args or {})
    if name == "kb_stats":  return kb_stats(args or {})
    raise KeyError(name)

def reply(rid, result=None, error=None):
    msg = {"jsonrpc": "2.0", "id": rid}
    if error is not None: msg["error"] = error
    else: msg["result"] = result
    sys.stdout.write(json.dumps(msg, ensure_ascii=False) + "\n")
    sys.stdout.flush()

def main():
    for line in sys.stdin:
        line = line.strip()
        if not line: continue
        try:
            msg = json.loads(line)
        except Exception:
            continue
        rid, method = msg.get("id"), msg.get("method", "")
        params = msg.get("params") or {}
        try:
            if method == "initialize":
                reply(rid, {"protocolVersion": params.get("protocolVersion", "2024-11-05"),
                            "capabilities": {"tools": {}},
                            "serverInfo": {"name": "kb-mcp", "version": "1.0.0"}})
            elif method == "ping":
                reply(rid, {})
            elif method == "tools/list":
                reply(rid, {"tools": TOOLS})
            elif method == "tools/call":
                name = params.get("name", "")
                try:
                    out = dispatch(name, params.get("arguments"))
                    reply(rid, {"content": [{"type": "text", "text": str(out)}], "isError": False})
                except Exception as e:
                    log("tool %s failed: %s" % (name, e))
                    reply(rid, {"content": [{"type": "text", "text":
                        "ERROR: %s\n提示: 若端点不可用, 检查 systemctl status llama-cpp-embedding llama-cpp-reranker"
                        % e}], "isError": True})
            elif rid is not None:
                reply(rid, error={"code": -32601, "message": "unknown method: " + method})
        except BrokenPipeError:
            return
if __name__ == "__main__":
    main()
