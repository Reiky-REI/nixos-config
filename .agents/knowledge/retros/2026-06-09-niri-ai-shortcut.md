---
date: 2026-06-09
module: home/Reiky-REI/desktop/niri/sections/base.kdl
tags: [niri, ai-screenshot, shortcut, minlai]
layer: home
severity: low
related:
  - ../../requests/2026-06-09-niri-ai-shortcut.md (申请处理)
experience:
  - "ai-screenshot 命令在 ~/.local/bin/ 下，通过 home.sessionVariables PATH 注入，spawn 可直接找到"
  - "hotkey-overlay-title 属性会自动注册到 Mod+Shift+/ 快捷键帮助"
---

## 变更内容

在 niri 配置中添加 AI 截图分析快捷键 (`Mod+Shift+A`)。

## 修改的文件

- `home/Reiky-REI/desktop/niri/sections/base.kdl` — 第 48 行新增 `Mod+Shift+A` 绑定

## 添加的内容

```kdl
Mod+Shift+A hotkey-overlay-title="AI 截图分析" { spawn "ai-screenshot"; }
```

## 决策依据

- `Mod+Shift+A` 与其他截图相关快捷键 (`Mod+G`) 相邻，便于记忆
- `hotkey-overlay-title` 使其自动出现在 `Mod+Shift+/` 帮助中
- `ai-screenshot` 通过 `$HOME/.local/bin:$PATH` 可被 niri 找到

## 验证

- ✅ `nixos-rebuild build --flake /etc/nixos#NixMEOW` 构建成功
- ⏳ 需要用户执行 `sudo .agents/config/rebuild.sh build`
- ⏳ 然后 `niri msg action reload-config` 或重新登录

## 后续步骤

1. 执行 `sudo .agents/config/rebuild.sh build`
2. 执行 `niri msg action reload-config`
3. 按 `Super+Shift+A` 测试 AI 截图分析
