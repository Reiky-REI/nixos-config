# 复盘: Claude Code 安装 + DeepSeek 集成

## 改动

| 文件 | 说明 |
|------|------|
| `home/Reiky-REI/dev/claude-code.nix` | 重写：之前用 `pkgs-unstable.claude-code` + `programs.claude-code`（都不存在），改用 `home.packages = [ pkgs.claude-code ]` |
| `home/Reiky-REI/dev/default.nix` | 加 `imports = [ ./claude-code.nix ]`（之前没 import 导致模块不生效）|
| `home/Reiky-REI/shell/zsh.nix` | agenix key 加载后添加 8 个 `ANTHROPIC_*` / `CLAUDE_CODE_*` 环境变量，全部模型默认 `deepseek-v4-flash` |

## 踩坑

1. **`claude-code` 仅存在于 nixpkgs stable**，unstable 中没有 → 不能用 `pkgs-unstable`
2. **`programs.claude-code` HM 模块不存在**（release-25.11）→ 不能用 HM module 方式，直接加 `home.packages`
3. **Nix `imports` 不自动加 `.nix` 后缀** → `./claude-code` 会报路径不存在，必须写 `./claude-code.nix`
4. **`claude-code.nix` 没有被 `dev/default.nix` import** → 虽然文件存在但从未生效

## 验证
- `claude --version` → 2.1.140
- 环境变量在 `.zshrc` 中，agenix key 解密后自动设置 `ANTHROPIC_AUTH_TOKEN`
