---
date: 2026-09-09
module: flake.nix, pkgs(Reiky-nixpkgs 私源), home/Reiky-REI/apps/browser.nix, home/Reiky-REI/desktop/niri/sections/{base,high}.kdl, home/Reiky-REI/desktop/wallpaper/swww.nix
tags: [zen-browser, firefox, browser, nixpkgs-overlay, 个人私源, flake, hyprland-cleanup, niri, profile-migration, autoPatchelfHook]
layer: home
severity: medium
related:
  - ../known-issues.md (新增: zen-browser 不在 nixpkgs / firefox 系 relrhack / profiles.ini install 锁 / flake dirty 未跟踪文件)
  - 2026-09-01-noctalia-idle-suspend-blackscreen.md (同期 niri base.kdl 编辑, 注意未提交的数位笔 hunk 需 git add -p 隔离)
experience:
  - "nixpkgs 26.05 与 unstable 的 browsers/ 目录都没有 zen-browser, 别默认它在喵~ 先查 pkgs/by-name/ze/ 再决定"
  - "官方通用 Linux 二进制(firefox 家族)打包照抄 nixpkgs firefox-bin 骨架: autoPatchelfHook + patchelfUnstable + --no-clobber-old-sections(relrhack 不覆盖旧 section 否则启动即崩)喵~"
  - "zen 命令行启动的 Wayland app-id = 二进制名 = zen(实测 niri msg windows 确认), 高配 PiP 窗口规则用 app-id=\"zen\" 精确匹配喵~"
  - "firefox/zen profiles.ini 的 [Install<hash>] Locked=1 会把 profile 绑死到某个二进制安装路径; 换 Nix 版(新 install-id)会掉回 Default=1 的 profile, 书签就『消失』喵~ 迁移后要规范化 profiles.ini 让带数据 profile 成 Default=1 喵~"
  - "从 Downloads 手动跑的 zen 与 Nix 版共用同一 ~/.zen profile, 书签本就在(~/.mozilla 与 ~/.zen 各 181 条), 所谓『迁移』实为 profile 选择修正喵~"
  - "flake 指向 dirty git 工作树时只认『已跟踪』文件, 新增脚本必须 git add 否则报 Path not tracked 构建失败喵~"
  - "home.file 部署到历史残留真实文件路径会触发 clobber 报错, 加 force=true 让 nix 成为唯一真相喵~"
  - "多 AI 并发同文件(base.kdl): 用 printf 'y\\nn\\ny\\n' | git add -p 只挑自己 hunk, 绝不整文件 add 把别人未提交改动扫进自己 commit 喵~"
  - "个人私源用 follows 复用主 nixpkgs, overlay 走 final.callPackage 不吃自带输入, 闭包不多拉一份 nixpkgs 喵~"
---

# 复盘: Zen Browser 全局安装 + 全量替换 Firefox + Hyprland 清理

## 背景与目标喵~

用户在 `~/Downloads/` 手动下载并解压了 Zen Browser 通用二进制(v1.21.16b), 要求:
1. 以符合 NixOS 哲学的方式把 Zen 写进配置(经确认放 home 层 `home.packages`)喵~
2. 把系统里所有 Firefox 引用(含快捷键)替换成 Zen 喵~
3. 清理不再使用的 Hyprland 相关配置喵~
4. 迁移 Firefox 书签喵~
5. 追加: 按 Nix 规则在 GitHub 建个人私源仓库 `Reiky-nixpkgs`, 日后配 CI/CD 喵~

## 关键调研结论喵~

- **Zen 不在 nixpkgs**: 查了主仓锁定的 nixpkgs 26.05(rev 566acc0)与 unstable(rev b7c2ada), `pkgs/applications/networking/browsers/` 只有 firefox/firefox-bin/chromium/brave/nyxt, `pkgs/by-name/ze/` 无 zen-browser 条目喵~ → 必须本地打包喵~
- **Firefox 引用点**: 活跃三处(`apps/browser.nix` 的 programs.firefox、`niri/sections/base.kdl:57` 快捷键、`niri/sections/high.kdl:127` PiP 窗口规则); 遗留死代码两处(`niri/config.kdl` 旧单体已被 sections 拆分取代、`desktop/hyprland/` 整个目录已不在 `desktop/default.nix` 的 imports 里)喵~
- **书签现状**: `~/.mozilla/firefox/default/places.sqlite` 与 `~/.zen/q873pg30.Default (release)/places.sqlite` 都是 181 条书签, 用户从 Downloads 版 zen 已经自己导入过, 迁移其实已完成喵~

## 实施喵~

### 1. 个人私源仓库 Reiky-nixpkgs(public)

- 结构: `flake.nix`(导出 `overlays.default` + `packages.x86_64-linux.{zen-browser,default}` + `hydraJobs`)、`pkgs/zen-browser/default.nix`、`README.md`(含版本更新流程与 CI/CD 预留)、`LICENSE`(MIT)、`.gitignore` 喵~
- 包定义照抄 firefox-bin 骨架: `fetchurl` 官方 tar.xz(SRI `sha256-Hkw8OR0QqCI501r62EZY+js4Vrj/cvk7v/f1c5KsuUI=`)、`sourceRoot="zen"`、`autoPatchelfHook`+`patchelfUnstable`+`--no-clobber-old-sections`、GTK/X11 依赖栈、`makeWrapper` 生成 `$out/bin/zen`、`distribution/policies.json` 禁自更新、`makeDesktopItem` + hicolor 图标喵~
- 独立 `nix build` 通过; 实测启动确认 app-id=`zen` 后关闭(临时 profile, 未碰用户真实数据)喵~
- 26.05 起 `xorg.*` 弃用, 改用扁平包名 `libx11/libxrender/...` 消除 warning 喵~
- GitHub `gh repo create Reiky-nixpkgs --public`, 默认分支改 main 与主仓一致喵~

### 2. 主仓接入

- `flake.nix`: 新增 `Reiky-nixpkgs` input(`follows` 主 nixpkgs), overlay 列表首位挂 `inputs.Reiky-nixpkgs.overlays.default` 喵~
- `nix flake lock` 拉入私源(rev 5970aa2), 验证 `overlaid.zen-browser.version == 1.21.16b` 喵~

### 3. 替换 Firefox

- `apps/browser.nix`: 删 `programs.firefox`, `home.packages` 加 `zen-browser`(保留 chrome)喵~ 废弃的 `privacy.donttrackheader.enabled`(FF136 起 DNT 已移除)不保留, home-manager 无 zen 模块故不托管 profile 设置喵~
- `base.kdl`: `spawn "firefox"`→`spawn "zen"`, 标题改「打开 Zen 浏览器」; 顺手删「与 hyprland 同步」过时注释喵~
- `high.kdl`: PiP 规则 `app-id=r#"firefox$"#`→`app-id="zen"`(实测值)喵~
- 删遗留 `niri/config.kdl` 死文件喵~

### 4. Hyprland 清理

- 全仓确认无外部引用 hyprland/waybar/wlogout, 删整个 `desktop/hyprland/` 喵~
- 唯一被 niri 还引用的 `swww-rofi.sh`(Mod+Shift+W)迁到 `desktop/wallpaper/` 并由 `swww.nix` 用 `home.file`+`force=true` 托管(此前它只是历史残留真实文件, 无 nix 来源)喵~ 重复的 capture.sh 与孤儿 wallpaper-video.sh/wf-recorder-status.sh 一并移除喵~

### 5. 书签/profile 规范化

- 备份 `~/.zen/{profiles.ini,installs.ini}` 并记 sha256 留证喵~
- 重写 `profiles.ini`: 只留带书签的 `q873pg30` 且置 `Default=1`, 去掉空 profile 的 Default=1 与 Downloads 版 `[Install...] Locked=1` 绑定, 使 Nix 版 zen(新 install-id)落到书签 profile 喵~

## 验证喵~

- `sudo nixos-rebuild build --flake /etc/nixos#NixMEOW` 成功(产出 `...-nixos-system-NixMEOW-26.05.20260806.445d861`)喵~
- `nix path-info -r` 确认 zen-browser 在系统闭包; 源码 grep 确认无功能性 firefox 残留(仅注释)喵~
- 未 switch(NVIDIA PRIME 风险), 由用户自行 build+reboot 后首启 zen 验证书签与快捷键喵~

## 遗留/后续喵~

- 私源 CI/CD(Cachix + Actions)按 README 预留由用户配置喵~
- `~/.config/wallpaper/script/wallpaper-video.sh` 等历史残留文件仍在磁盘(非 nix 托管), 可择机手动清理喵~
- 语言包 zh-CN 需用户在 zen 设置界面自装(home-manager 无法声明式托管)喵~
