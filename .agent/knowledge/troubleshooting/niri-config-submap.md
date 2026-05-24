# Niri submap 导致整个配置失效

## 现象
- Niri 启动后 `spawn-at-startup` 全部不执行
- noctalia / fcitx5 都不启动
- 终端里 `niri validate` 报 `error loading config`

## 根因
Niri **不支持 submap**（截至 26.04 版本）。submap 是 Hyprland 专有概念。

写 Niri config 时把 `submap "close" {}` 嵌在 `binds {}` 里面 + 用了不存在的 action (`switch-to-named-submap`/`switch-to-previous-submap`) → 整个 KDL 解析失败 → Niri 回退默认配置，所有自定义 `spawn-at-startup` 丢失。

## 修复
Niri 窗口关闭保持原始 `Mod+Q repeat=false { close-window; }`。
退出 session 已有确认弹窗 `Mod+Shift+E { quit; }`。

## 教训
1. **改 Niri 配置前先跑 `niri validate`**（必须跑 — KDL 语法极严）
2. Niri 的 action 名和 Hyprland 不同，不要想当然
3. 查 Niri action 列表: 可以看源码或 `niri msg help`
4. KDL 中 `submap` 不是 `binds` 的子节点(即使 niri 将来支持也是顶层节点)

## 相关文档
- Niri 配置语法: https://github.com/YaLTeR/niri/wiki
