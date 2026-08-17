# Retro 2026-08-17 完全体冲刺: 本地Qwen+AstrBot+DSH+opencode 全链路

## 背景
用户目标: NixMEOW 上跑"完全体" — 本地 Qwen 基座 + DSH/AstrBot MCP 互调 + 每文件夹经验体系 + opencode LSP 共享 + 高级权限自启 + MCP bridge。

## 完成清单(cordis 文件/专项)
1. 块A: Qwen3-8B-Q4_K_M + Qwen3-Embedding-0.6B 双实例 llama-cpp(chat 8080 ctx4096 GPU / embedding 8081 CPU) + AstrBot 本地 provider + iris 记忆库本地 embedding(1024维)
2. 块C: init-agents + .agents-templates 多目录落地
3. 块D: opencode-lsp wrapper(XDG 重定向 + PATH 补全) + nixos-guard rule8
4. 任务E: DSH LSP 全覆盖 — bash-language-server + shellcheck(SC1072 实测) + vscode-json-language-server(Trailing comma 实测) + nixd/ts
5. 任务F: opencode-root.service(systemd, 9502, 高级权限自启) — 替换用户手动 tmux
6. 任务G: 公共 MCP bridge(mcp-agents-bridge.service :9503) — 5工具(advanced_exec/read_agents/ask_dsh/astrabot_send/opencode_lsp), AstrBot 1/1 成功, DSH 经 dsh-mcp-client 接入, skill 落地
7. 任务H: skills/opencode-root-channel/SKILL.md + skills/mcp-agents-bridge/SKILL.md
8. 任务I: DSH-TUI 验证 — 修 tui profile cordis.yml 属主(root→Reiky-REI) + PTY 实测进入界面
9. 任务J: dsh-super-injector(active) + mode-boost 热装 + router-standard preset 就位

## 关键经验/踩坑(新)
- root 通道(9502)curl 发命令 stdout 偶发被吞 → 一律 -o 文件落盘再 cat 读稳
- 长 base64 命令分两步: echo > /tmp/x.b64 再 base64 -d > 目标(一次性管道会超限)
- AstrBot mcp_server.json 必须带 transport:streamable_http(缺了报 "missing transport or type field")
- FastMCP 1.29 用 streamable_http_app(不是 .app); AstrBot venv python 可当通用 python(yaml/mcp 都有)
- systemd 服务 User=普通用户(非root)更安全; 高级权限经 9502 按需获取
- dsh 写 profile 需文件属主为用户否则 EACCES(碰过 tui 和 astrabot 两处)
- shellcheck 是 bash-language-server 报语法诊断的前提
- JSON LSP(vscode-json-language-server)需在 opencode.json lsp 注册 .json 扩展; typescript 默认不含 .json
- opencode diagnostics 只对项目根(如 /etc/nixos)内文件生效, /tmp 下返回 {}

## 遗留/待办
- 任务K: Dify 部署(podman-compose + 镜像 + AstrBot dify_agent_runner_provider_id) — 未做, 需用户确认磁盘/网络
- 复盘完成
- 新会话: 读 HANDOFF-2026-08-17-1235-resume.md
