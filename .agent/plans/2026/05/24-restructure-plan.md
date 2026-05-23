# NixOS 重构计划

## 目标
将现有配置重构为清晰、可维护、分层明确的 declarative system architecture。

## 执行清单 (9 步)
1. 创建 `.agent/` 目录结构
2. 修改 `flake.nix`
3. 修复 wiring (hosts/modules/home 的 imports 连通性)
4. 将 hosts 配置拆入对应 modules
5. modules/desktop 中 home-manager 内容移入 home/Reiky-REI/
6. 清理 (mdp→mpd, 去重 i18n, bluetooth 移入 hardware, fcitx5 overlay)
7. 创建 modules/development/
8. 重写 README.md
9. 最终验证 dry-activate

详见 需求.md
