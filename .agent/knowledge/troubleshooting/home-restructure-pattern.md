# Home 目录重组的 Do / Don't

## 背景
2026-05-24 将 `home/Reiky-REI/` 从平铺的 10 个顶级目录重组为分类清晰的 8 个模块。

## 新结构
```
home/Reiky-REI/
├── default.nix         # 精简入口，只放 session vars / cursor / mime
├── desktop/            # WM compositors + UI 组件
│   ├── hyprland/       # Hyprland + waybar + wlogout + hyprlock + scripts
│   ├── niri/           # Niri compositor
│   ├── rofi/           # 应用启动器
│   ├── wallpaper/      # swww + 图片
│   └── noctalia.nix    # Noctalia shell
├── apps/               # GUI 应用 (按功能细拆)
│   ├── browser.nix     # firefox, google-chrome
│   ├── communication.nix  # wechat, qq
│   ├── media.nix       # vlc, spotify, mpv, obs-studio
│   ├── office.nix      # obsidian, logseq, dolphin
│   └── fastfetch.nix
├── tools/              # CLI 工具
│   ├── essentials.nix  # tree, unzip, grim, slurp, wf-recorder 等
│   ├── search.nix      # fzf, fd, ripgrep
│   ├── viewers.nix     # bat, eza, jq, yazi, zoxide
│   └── monitors.nix    # btop, cava
├── editors/            # 编辑器 + 终端复用器 + Git 工具
│   ├── neovim.nix
│   ├── neovide.nix / tmux.nix / zellij.nix
│   └── vscode.nix / zed.nix / lazygit.nix / direnv.nix
├── dev/                # 开发语言包
│   ├── default.nix     # typst, nodejs, python, go, gcc 等
│   └── claude-code.nix
├── shell/              # zsh + p10k
├── terminal/           # kitty + alacritty
└── music/              # ncmpcpp + go-musicfox
```

## Do ✅
1. 用 `cp -r` 复制整个目录 → 新建文件 → 删旧文件（git 自动识别 rename）
2. 每个目录有 `default.nix` 作为入口 import 子模块
3. 拆分 `programs/` 时按功能维度 (apps/tools/editors/dev) 而非按文件数
4. 先 dry-activate 验证 import 链路，发现问题逐个修

## Don't ❌
1. **不要一次改太多又 rebuild** — 拆散 programs 和移动 hyprland 等操作用 git 追踪，先 dry-activate
2. **不要忘记更新 `default.nix` 的 imports** — 旧路径会直接报错
3. **不要把 home-manager 选项当成 NixOS 选项上移** — 验证后再说
4. **不要忽略 git add** — Nix flake 只读 tracked 文件
5. **vim/neovim settings 在 HM 25.11 不再支持大多数 key** — 全部用 `extraConfig`

## 实际碰到的问题
- `nodejs_23` 不存在 → 改 `nodejs`
- tmux `better-mousemode` 不存在 → 删掉
- vim `settings.clipboard`/`cursorcolumn` HM 25.11 不支持 → 全部移入 `extraConfig`
- `luajit` 和 `lua` 的 `luaconf.h` 冲突 → 删 `luajit`
- `softtabstop` 在 HM 25.11 中不存在 → 移入 `extraConfig`
