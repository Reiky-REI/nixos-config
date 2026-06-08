---
title: "安装 minl.ai 依赖包"
requester: "home/claude-code"
date: "2026-06-09"
request_id: "2026-06-09-minlai-deps"
priority: "medium"
status: "done"
---

## 申请内容

为用户安装 minl.ai (AI 截图分析工具) 所需的系统级依赖包。

minl.ai 是一个 Linux 桌面 AI 助手,可以通过快捷键触发截图,然后用 AI 分析截图内容。

## 为什么需要

用户希望实现"快捷键触发 AI 截图分析"的功能:
1. 按快捷键 (Super+Shift+A) 触发截图
2. 用 grim + slurp 选择屏幕区域
3. 调用 mimo-v2.5 (Anthropic 兼容 API) 分析截图
4. 通过浮窗显示 AI 回复

minl.ai 支持 Anthropic 兼容 API,可以使用用户已有的 mimo-v2.5 模型。

## 具体方案

需要添加以下 NixOS 包:

```nix
environment.systemPackages = with pkgs; [
  # minl.ai 截图工具依赖
  grim          # Wayland 截图工具
  slurp         # Wayland 区域选择工具
  
  # Python 运行时
  python3
  python3Packages.pip
  
  # minl.ai Python 依赖
  python3Packages.anthropic    # API 调用
  python3Packages.pyqt6        # 浮窗 UI
  python3Packages.pynput       # 快捷键监听
  python3Packages.sounddevice  # 语音输入
  python3Packages.numpy        # 数值计算
];
```

## 预期影响

- 会增加系统包数量 (约 10 个包)
- 会增加磁盘占用 (Python 包较大)
- 不影响现有功能
- 需要用户手动执行 `sudo nixos-rebuild switch` 生效

## 验证方式

```bash
# 1. 构建验证
nixos-rebuild build --flake /etc/nixos#NixMEOW

# 2. 安装后测试
grim -g "$(slurp)" /tmp/test.png  # 测试截图
minlai --screenshot               # 测试 AI 分析

# 3. 快捷键测试
# 按 Super+Shift+A
```

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-09 | 提交 | `pending` → 等待审批 |
| 2026-06-09 | 处理 | `done` → 添加 python3Packages 依赖到 home 层 |

## 关联复盘

- `retros/2026-06-09-minlai-deps.md` — minl.ai 依赖安装复盘
