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
- 提交信息用中文或英文均可，与仓库历史风格一致
- 每次验证通过后提交一个步骤
