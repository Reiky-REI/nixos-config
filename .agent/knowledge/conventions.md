# 编码约定

## Nix 格式
- 使用 2 空格缩进
- `{ ... }: {` 左大括号留空格
- import 路径使用相对路径 (从使用文件出发)
- 函数参数按字母顺序排序: `config, lib, pkgs, ...`

## 模块命名
- 目录下 default.nix 作为入口
- 文件名小写 + 连字符: `fcitx5.nix`, `go-musicfox.nix`
- 与 NixOS 选项名一致: `mdp.nix` → `mpd.nix` 因为选项是 `services.mpd`

## 分层规则
- 系统层模块只放 NixOS options (`services.*`, `programs.*`, `hardware.*`, `boot.*` 等)
- home-manager options (`home.packages`, `home.file`, `programs.waybar` 等) 放在 home 层
- `environment.sessionVariables` 按语义拆分到对应模块
- 后台 daemon (polkit-gnome, swaync, swayidle 等) 放在系统 modules，不放在 home

## Home 分类规则
- **desktop/** — WM/compositor 配置 + 启动器 + 壁纸 + 相关 UI 组件
- **apps/** — GUI 用户应用 (浏览器/通讯/媒体/办公)
- **tools/** — CLI 工具 (搜索/查看/监控/系统工具)
- **editors/** — 编辑器 (vim/neovide) + 终端复用器 (tmux/zellij) + Git 工具
- **dev/** — 开发语言包
- **shell/** — shell 配置
- **terminal/** — 终端模拟器
- **music/** — 音乐播放器

## 环境变量归类
- `NIXOS_OZONE_WL` → desktop
- `QT_IM_MODULE` / `XMODIFIERS` → desktop/fcitx5 (输入法)
- `TERMINAL` → home (用户偏好)
- `XDG_DATA_DIRS` (flatpak) → services

## Git 提交
- 提交信息语言不限，与仓库历史风格一致即可
- 每次验证通过后提交一个步骤

## 知识记录语言
- 不限语言，**准确无歧义优先**
- 原始问题/原始参考文献/错误日志保持原文（如 kernel commit hash、dmesg 输出、Nix error）
- 中文、英文、混写均可，哪种表达更精确用哪种

## 构建验证流程
- 每次改动后先跑 `dry-activate` 确认配置无语法错误
- 通过后再 `switch` 应用
- 涉及 kernel / systemd unit 的改动后建议 `systemctl reboot`

## AI Agent 工作流
- 操作前必读三份核心文档: `architecture.md` + `conventions.md` + `system-maintenance.md`
- 改 Nix 配置前先验证选项是否存在: `nix eval` / 查 nixpkgs 源码
- 修改 home-manager 选项前确认它是 HM 还是 NixOS 选项 (不要混用)
- 每次 `rebuild switch` 完成后, 将复盘日志追加到 `system-maintenance.md` 末尾的「Session 日志」章节
- 常见坑和经验也写入 `system-maintenance.md` 的对应章节, 不要新建独立文件
