---
title: "通过 home-manager 添加 niri AI 截图快捷键"
requester: "home/claude-code"
date: "2026-06-09"
request_id: "2026-06-09-niri-ai-shortcut-hm"
priority: "medium"
status: "done"
---

## 申请内容

通过 home-manager 配置添加 niri AI 截图快捷键。

## 为什么需要

niri 配置文件是由 home-manager 管理的符号链接,不能直接编辑。需要通过 NixOS 配置来添加快捷键。

## 具体方案

在 home-manager 的 niri 配置中添加:

```nix
programs.niri.settings.binds = {
  "Mod+Shift+A" = {
    hotkey-overlay-title = "AI 截图分析";
    spawn = ["ai-screenshot"];
  };
};
```

或者在现有的 niri 配置模块中添加这个快捷键绑定。

## 预期影响

- 通过 NixOS 配置管理快捷键
- 与现有配置集成
- 需要 `nixos-rebuild switch` 生效

## 验证方式

```bash
# 1. 检查配置
grep -r "Mod+Shift+A" /etc/nixos/

# 2. 重建配置
nixos-rebuild switch --flake /etc/nixos#NixMEOW

# 3. 测试快捷键
# 按 Super+Shift+A
```

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-09 | 提交 | `pending` → 等待审批 |
| 2026-06-09 | 处理完成 | 已通过 `base.kdl` 实现（`programs.niri` HM module 在当前 nixpkgs 中不存在） |

## 关联复盘
<!-- 已通过 2026-06-09-niri-ai-shortcut 复盘覆盖 -->
