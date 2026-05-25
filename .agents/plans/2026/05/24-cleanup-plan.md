# Plan: 2026-05-24 清理优化

## 需求来源
用户提出 secrets 隔离加强、gitignore 模板化、拼写修复、启动优化、hardware-config 优化

## 完成状态
| # | 操作 | 文件 | 状态 |
|---|------|------|------|
| 1 | gitignore 新增规则 | `.gitignore` | ✅ |
| 2 | 模板: AI plan 格式 | `.agent/plans/TEMPLATE.md` | ✅ |
| 3 | 模板: AI session 格式 | `.agent/sessions/TEMPLATE.md` | ✅ |
| 4 | 模板: age 密钥内容 | `secrets/ai_api_key.age.template` | ✅ |
| 5 | 模板: secrets.nix 格式 | `secrets/TEMPLATE.nix` | ✅ |
| 6 | git rm --cached 用户文件 | plans/ sessions/ secrets/ | ✅ |
| 7 | 修复 nvidia 拼写 | `modules/hardware/gpu/nvidia.nix` | ✅ |
| 8 | 修复 cuda 拼写 | `modules/hardware/gpu/cuda.nix` | ✅ |
| 9 | 启动优化 | `hyprland/autostart.conf` | ✅ |
| 10 | token 逻辑优化 | `.agent/config/env.sh` | ✅ |
| 11 | hw-config 优化 | `hosts/MEOW/hardware.nix` | ✅ |

## Commit 提交后执行
- `nixos-rebuild switch` 验证
- `git push origin main`
