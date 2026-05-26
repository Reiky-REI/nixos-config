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

## Git 工作流 (多 AI 协作)
- 提交信息语言不限，与仓库历史风格一致即可
- 每次验证通过后提交一个步骤
- **始终在 feature branch 上工作**，禁止直接在 main 上修改
- 开工前执行 `git status` + `git branch` 确认工作区干净
- **OpenCode 提交**使用 `.agents/config/commit.sh`（bot 身份）
- **Claude Code 提交**用 `git -c user.name="claude-code[bot]" -c user.email="claude-code[bot]@users.noreply.github.com" commit`（bot 身份）
- 提交后推送到 origin，由人工或另一个 AI review 后合并到 main

## 多 AI 协作规范
- 两个 AI 都遵守 `.agents/` 下的全部约定
- 修改复杂配置前先读 `known-issues.md` 避免踩坑
- 新知识及时补充到对应知识文件或 `known-issues.md`
- 配置变更后必须写复盘到 `retros/`
