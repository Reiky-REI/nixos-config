# 复盘: 2026-05-24 仓库分层架构重构

## 目标
将现有单层配置重构为分层清晰、模块化的 NixOS 架构。

## 关键提交
- `a35c905` 重构: 仓库分层架构整理
- `818a35a` fix: 修复终端无法输入中文问题
- `8cba9e7` fix: 添加 GTK_IM_MODULE 环境变量解决终端无法输入中文

## 遇到的坑

### 坑 1: fcitx5-gtk 缺失导致终端无法输入中文
- **现象**: Alacritty/Kitty 中无法切换中文输入法
- **根因**: fcitx5 NixOS module 没有自动添加 fcitx5-gtk 包
- **解决**: 在 `i18n.inputMethod.fcitx5.addons` 中手动添加 `fcitx5-gtk`
- **结果**: ✅ 已解决
- **下次注意**: 新增输入法包时必须同时加 `fcitx5-gtk`

### 坑 2: Wayland 下 GTK_IM_MODULE 需要手动设置
- **现象**: 设了 `waylandFrontend = true` 后仍需 `GTK_IM_MODULE`
- **根因**: NixOS fcitx5 模块的 wayland 模式不自动设此变量
- **解决**: 在 `environment.sessionVariables` 中手动设 `GTK_IM_MODULE = "fcitx"`
- **结果**: ✅ 已解决

## 本次沉淀
- [x] 提炼到 known-issues.md → fcitx5 配置注意事项
