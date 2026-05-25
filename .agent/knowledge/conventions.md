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

## 环境变量归类
- `NIXOS_OZONE_WL` → desktop
- `QT_IM_MODULE` / `XMODIFIERS` → desktop/fcitx5 (输入法)
- `TERMINAL` → home (用户偏好)
- `XDG_DATA_DIRS` (flatpak) → services

## Git 提交
- 提交信息语言不限，与仓库历史风格一致即可
- 每次验证通过后提交一个步骤
