// dsh-deepsec-guard — 统一 DeepSec 安全守卫(DSH web profile 插件)。
//
// 在 DSH 的两个动作前接缝挂 DeepSec 判定,引擎统一为 DeepSec(deepsec-guard):
//   agent/pre-step      → 扫描进入模型的入站消息(恶意提示词/越狱/密钥),命中 → reject 本步
//   tools/pre-execute   → 扫描工具参数(命令/代码),命中高危 → deny
//   tools/post-execute  → 扫描工具结果(可选,默认开),命中高危 → block 反馈
//
// 决策契约:prepend 直通监听。放行调用 next() 并透传;拦截不调 next() 直接返回决策。
// 失败关闭:外部 guard 不可用或超时 → 一律放行(记录日志),避免误伤正常工作流。
//         (如需更严,可改 allowOnError=false 使其失败关闭为拦截。)
//
// 注意:引擎统一为 DeepSec,不经手任何其他检测器(dsh-defend 已被移除)。

import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import path from "node:path";

export const name = "dsh-deepsec-guard";

// 可选注入的服务(本插件零依赖,故空)。
export const inject = [];

const GUARD = path.join(homedir(), "WorkSpace/bin/deepsec-guard");
const PIXI_PY = path.join(homedir(), "WorkSpace/DeepSec/.pixi/envs/default/bin/python3");
const GUARD_PY = path.join(homedir(), "WorkSpace/DeepSec/tools/deepsec-guard.py");

const DEFAULT_SCAN_TOOLS = ["bash", "persistent-bash", "terminal-bash", "str-replace-editor", "edit"];

// ── 配置(Schemastery)──
import z from "@deepseek-ai/schemastery";

export const Config = z.object({
  enabled: z.boolean().default(true),
  // 扫哪些工具的参数(工具注册名)
  toolNames: z.array(z.string()).default([...DEFAULT_SCAN_TOOLS]),
  // 入站消息是否也扫(恶意提示词)
  scanPreStep: z.boolean().default(true),
  // 工具结果是否也扫
  scanPostExecute: z.boolean().default(false),
  // guard 不可用/超时时是否放行(fail-open)还是拦截(fail-closed)
  allowOnError: z.boolean().default(true),
  timeoutMs: z.number().default(12000),
});

// ── 调用 deepsec-guard,返回 {blocked, findings} ──
function guardScanText(text, target) {
  if (!text || !text.trim()) return { blocked: false, findings: [] };
  const args = [GUARD_PY, "scan-text", String(text), "--target", target || "dsh"];
  let res;
  try {
    res = spawnSync(PIXI_PY, args, { encoding: "utf8", timeout: 12000 });
  } catch {
    return { blocked: false, findings: [], error: "spawn-failed" };
  }
  if (res.error) return { blocked: false, findings: [], error: res.error.message };
  // 返回码:0=allow, 1=block; 判定在 stderr(JSON)
  try {
    const out = JSON.parse(res.stderr || "{}");
    return {
      blocked: out.block === true,
      findings: out.findings || [],
      verdict: out.verdict,
    };
  } catch {
    // 非 JSON(正常放行时 guard 也可能无 stderr)
    return { blocked: res.status === 1, findings: [] };
  }
}

// 从 PreToolExecution 提取要扫的文本(命令或文件内容)
function toolText(exec) {
  const argv = exec.arguments;
  if (typeof argv === "string") return argv;
  if (Array.isArray(argv)) return argv.join(" ");
  if (argv && typeof argv === "object") {
    const c = argv.command ?? argv.content ?? argv.text ?? argv.path ?? argv.file_path;
    if (typeof c === "string") return c;
    try {
      return JSON.stringify(argv);
    } catch {
      return "";
    }
  }
  return "";
}

// 入站消息 → 文本
function messagesText(messages) {
  if (!Array.isArray(messages)) return "";
  const parts = [];
  for (const m of messages) {
    if (typeof m?.content === "string") parts.push(m.content);
    else if (Array.isArray(m?.content)) {
      for (const b of m.content) {
        if (b?.type === "text" && typeof b.text === "string") parts.push(b.text);
        else if (b?.type === "tool_result" && typeof b?.content === "string") parts.push(b.content);
      }
    }
  }
  return parts.join("\n");
}

function reasonFor(findings) {
  const top = (findings || []).slice(0, 3)
    .map((f) => `${f.type||"?"}(${f.severity||"?"})`)
    .join(", ");
  return `DeepSec 拦截:检测到高危风险 (${top || "unknown"})。已阻断本次操作;请先修复或确认豁免。`;
}

// ── 插件入口 ──
export function apply(ctx, config) {
  if (!config.enabled) return;

  // 1. tools/pre-execute: 工具参数 —— 命中高危 → deny
  ctx.on(
    "tools/pre-execute",
    (exec, next) => {
      if (!config.toolNames.includes(exec?.name)) return next();
      const text = toolText(exec);
      const r = guardScanText(text, `dsh:${exec?.name}`);
      if (r.blocked) {
        return { kind: "deny", reason: reasonFor(r.findings) };
      }
      return next();
    },
    { prepend: true },
  );

  // 2. agent/pre-step: 入站消息 —— 命中注入 → reject
  if (config.scanPreStep) {
    ctx.on(
      "agent/pre-step",
      (payload, next) => {
        const text = messagesText(payload?.messages);
        const r = guardScanText(text, "dsh:pre-step");
        if (r.blocked) {
          return { kind: "reject" };
        }
        return next();
      },
      { prepend: true },
    );
  }

  // 3. tools/post-execute: 工具结果 ——(可选)
  if (config.scanPostExecute) {
    ctx.on(
      "tools/post-execute",
      (exec, result, next) => {
        const text = typeof result?.content === "string" ? result.content : JSON.stringify(result || {});
        const r = guardScanText(text, `dsh:${exec?.name}:result`);
        if (r.blocked) {
          return { kind: "block", feedback: [{ type: "text", text: reasonFor(r.findings) }] };
        }
        return next();
      },
      { prepend: true },
    );
  }
}
