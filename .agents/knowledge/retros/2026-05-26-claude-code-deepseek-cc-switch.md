# 复盘: Claude Code + DeepSeek 集成终案（cc-switch 代理方案）

## 背景
之前尝试直接用环境变量配置 Claude Code 接 DeepSeek Anthropic 兼容端点，但遇到 "Not logged in" 问题。根源是 Claude Code 2.1.140 的交互式 REPL 需要走 Anthropic 的 bridge 做 session 验证，DeepSeek 的 `/anthropic` 端点没有这套基础设施。

## 最终方案：cc-switch-cli 本地代理

用 [cc-switch-cli](https://github.com/SaladDay/cc-switch-cli) 做本地代理，Claude Code 连本地代理，代理处理 bridge 验证后转发到 DeepSeek。

### 架构
```
claude → 本地代理 127.0.0.1:15721 → cc-switch proxy → DeepSeek API
```

### 具体操作
| 步骤 | 操作 |
|------|------|
| 1. 安装 | `curl -fsSL ...install.sh \| bash` 安装 `~/.local/bin/cc-switch` |
| 2. 写库 | 直接 sqlite3 插入 DeepSeek provider 到 `~/.cc-switch/cc-switch.db` |
| 3. 切换 | `cc-switch provider switch deepseek` → 自动写 `~/.claude/settings.json` |
| 4. 代理 | `cc-switch proxy enable` → daemon 启动在 127.0.0.1:15721 |
| 5. 环境变量 | `.zshrc` 设 `ANTHROPIC_BASE_URL=http://127.0.0.1:15721` + `ANTHROPIC_AUTH_TOKEN=proxy-placeholder` |
| 6. rebuild | `nixos-rebuild switch` 使 HM 配置生效 |

### 踩坑
1. **`ANTHROPIC_AUTH_TOKEN` vs `ANTHROPIC_API_KEY`**
   - DeepSeek 文档用 `AUTH_TOKEN`，但 2.1.140 中它被当作 OAuth token 处理（`authMethod: oauth_token`），触发 bridge 验证
   - `ANTHROPIC_API_KEY` 是 `authMethod: api_key`，不触发 bridge，但直接连 DeepSeek 仍因 bridge 缺失而 "Not logged in"
2. **环境变量冲突** — cc-switch 的 FAQ 明确指出 shell env var 会覆盖它的配置
3. **`claude --print` 模式一直能用** — 因为非交互模式不走 bridge
4. **`cc-switch provider add` 是交互式的** — 需要 TTY，无法脚本化。改用 sqlite3 直接写库
5. **`nixos-rebuild switch` 在 NVIDIA PRIME 系统上重启 polkit → compositor 丢 DRM master → 黑屏**，需提前注意

### 后续
- cc-switch-cli 已安装到 `~/.local/bin/cc-switch`，如果重建系统要注意备份或纳入 flake
- 考虑把 `cc-switch-cli` 加为 flake input（它自带 flake.nix）
- `~/.claude/settings.json` 由 cc-switch 管理，不要手动改
