#!/usr/bin/env bash
# proxy — mihomo 代理控制 (on/off/toggle/status/node/panel)
#
# 由 NixOS home-manager 安装 (home/reiky/tools/mihomo.nix), man: `man proxy`
set -euo pipefail

API="${MIHOMO_API:-http://127.0.0.1:9097}"
SECRET="${MIHOMO_SECRET:-set-your-secret}"
AUTH=(-H "Authorization: Bearer ${SECRET}" -H "Content-Type: application/json")
PANEL_URL="http://127.0.0.1:9097/ui/"

engine() {
  systemctl --user is-active mihomo.service 2>/dev/null || echo inactive
}
get_mode() {
  curl -s "${AUTH[@]}" "${API}/configs" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("mode","?"))' 2>/dev/null || echo "?"
}
current_node() {
  curl -s "${AUTH[@]}" "${API}/proxies/%E8%8A%82%E7%82%B9%E9%80%89%E6%8B%A9" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("now","?"))' 2>/dev/null || echo "?"
}
set_mode() {
  curl -s -o /dev/null -X PATCH "${AUTH[@]}" -d "{\"mode\":\"$1\"}" "${API}/configs"
}

switch_node() {
  python3 - "$API" "$SECRET" "${1:-节点选择}" <<'PY'
import concurrent.futures as cf, json, sys, urllib.parse, urllib.request
api, secret, group = sys.argv[1:4]
H = {"Authorization": "Bearer " + secret}

def req(path, method="GET", payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    h = dict(H)
    if data is not None:
        h["Content-Type"] = "application/json"
    r = urllib.request.Request(api + path, headers=h, data=data, method=method)
    with urllib.request.urlopen(r, timeout=30) as resp:
        raw = resp.read()
        return json.loads(raw) if raw else None

d = req("/proxies")["proxies"]
if group not in d:
    print("组不存在:", group); sys.exit(2)

def test(n):
    try:
        q = urllib.parse.quote(n, safe="")
        r = req("/proxies/" + q + "/delay?" + urllib.parse.urlencode(
            {"timeout": "5000", "url": "http://www.gstatic.com/generate_204"}))
        return (r.get("delay") or 99999, n)
    except Exception:
        return (99999, n)

names = [n for n in d[group]["all"]
         if n != "自动选择"
         and not any(x in n for x in ("剩余", "套餐", "到期", "距离"))
         and d.get(n, {}).get("type") not in ("Selector", "URLTest")]
res = []
with cf.ThreadPoolExecutor(max_workers=8) as ex:
    for r in ex.map(test, names):
        res.append(r)
res.sort()
for dl, n in res[:10]:
    print(f"  {dl if dl < 99999 else 'FAIL':>6}  {n}")
good = [x for x in res if x[0] < 99999]
if not good:
    print("无可用节点"); sys.exit(1)
req("/proxies/" + urllib.parse.quote(group, safe=""), "PUT", {"name": good[0][1]})
print("已切换 ->", good[0][1], f"({good[0][0]}ms)")
PY
}

open_panel() {
  if command -v google-chrome-stable >/dev/null 2>&1; then
    google-chrome-stable --app="$PANEL_URL" --class=mihomo-panel >/dev/null 2>&1 &
  else
    xdg-open "$PANEL_URL" >/dev/null 2>&1 &
  fi
}

usage() {
  cat <<'EOF'
proxy — mihomo 代理控制

用法:
  proxy                 查看状态 (同 status)
  proxy on              开启代理 (mode=rule, 按规则分流)
  proxy off             关闭代理 (mode=direct, 全部直连; 引擎不灭)
  proxy toggle          在 on/off 间切换
  proxy status [--json] 查看 引擎/模式/当前节点
  proxy node [组名]     测速并切到最快节点 (默认组: 节点选择)
  proxy panel           打开 Web 面板 (metacubexd 独立窗口)
  proxy restart         重启 mihomo.service
  proxy help            显示本帮助

systemctl (用户级):
  systemctl --user status|start|stop|restart mihomo.service
  systemctl --user enable|disable mihomo.service     # 开机自启

说明:
  - 系统代理环境变量固定指向 127.0.0.1:7897 (HTTP 亦监听 7890)。
  - "关代理"推荐 `proxy off` (direct), 而不是停服务: 停服务会让走代理的
    程序连不上 (env 仍指向 7897)。
  - Web 面板: http://127.0.0.1:9097/ui/
  - 配置: ~/.config/mihomo/config.yaml    面板: ~/.config/mihomo/ui/
  - 状态栏: noctalia 右侧盾牌图标 (左键切 rule/direct, 右键打开面板)
EOF
}

case "${1:-status}" in
  on)
    systemctl --user start mihomo.service 2>/dev/null || true
    set_mode rule
    echo "🟢 代理 ON (rule)  节点: $(current_node)"
    ;;
  off)
    set_mode direct
    echo "⚪ 代理 OFF (direct, 全部直连); 切回: proxy on"
    ;;
  toggle)
    if [ "$(get_mode)" = "direct" ]; then "$0" on; else "$0" off; fi
    ;;
  status)
    if [ "${2:-}" = "--json" ]; then
      python3 - "$(engine)" "$(get_mode)" "$(current_node)" <<'PY'
import json, sys
print(json.dumps({"engine": sys.argv[1], "mode": sys.argv[2], "node": sys.argv[3]}, ensure_ascii=False))
PY
    else
      printf '引擎 : %s\n模式 : %s\n节点 : %s\n面板 : %s\n' \
        "$(engine)" "$(get_mode)" "$(current_node)" "$PANEL_URL"
    fi
    ;;
  node)
    shift
    switch_node "${1:-节点选择}"
    ;;
  panel)
    open_panel
    echo "打开面板: $PANEL_URL"
    ;;
  restart)
    systemctl --user restart mihomo.service
    echo "已重启 mihomo.service"
    ;;
  help | --help | -h)
    usage
    ;;
  *)
    echo "未知参数: $1"
    echo
    usage
    exit 1
    ;;
esac
