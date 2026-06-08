---
date: 2026-06-09
module: home/Reiky-REI/dev/default.nix
tags: [minlai, python, dependencies, ai-tools]
layer: home
severity: low
related:
  - ../../requests/2026-06-09-minlai-deps.md (申请处理)
experience:
  - "grim/slurp 已在 home 层 tools/essentials.nix 中配置，无需重复添加"
  - "python3 已在 home 层 dev/default.nix 中配置，只需添加 python3Packages.*"
  - "minl.ai 依赖应放在 home 层，符合用户交互应用的分类规范"
---

## 变更内容

为用户安装 minl.ai (AI 截图分析工具) 所需的 Python 依赖包。

## 修改的文件

- `home/Reiky-REI/dev/default.nix` — 添加 python3Packages 依赖

## 添加的包

```nix
# minl.ai 依赖
python3Packages.pip
python3Packages.anthropic    # API 调用 (支持 mimo-v2.5)
python3Packages.pyqt6        # 浮窗 UI
python3Packages.pynput       # 快捷键监听
python3Packages.sounddevice  # 语音输入
python3Packages.numpy        # 数值计算
```

## 决策依据

根据系统分类规范：
- 用户交互应用 → **home 层**
- minl.ai 是用户交互应用，依赖应放在 home 层
- grim/slurp 已在 home 层配置，无需重复
- python3 已在 home 层配置，只需添加 python3Packages.*

## 验证

- ✅ `nixos-rebuild build --flake /etc/nixos#NixMEOW` 构建成功
- ⏳ 需要用户执行 `sudo nixos-rebuild switch` 生效
- ⏳ 安装后测试 `grim -g "$(slurp)" /tmp/test.png` 和 `minlai --screenshot`

## 后续步骤

1. 用户执行 `sudo nixos-rebuild switch`
2. 测试截图功能：`grim -g "$(slurp)" /tmp/test.png`
3. 测试 AI 分析：`minlai --screenshot`
4. 测试快捷键：按 Super+Shift+A
