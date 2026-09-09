---
date: 2026-09-09
module: Reiky-nixpkgs/pkgs/zen-browser/default.nix (私源), flake.nix (Reiky-nixpkgs input 更新)
tags: [zen-browser, firefox, ffmpeg, gstreamer, H264, flash, 网课, LD_LIBRARY_PATH, dlopen, speechd, speech-dispatcher]
layer: home
severity: medium
related:
  - ../retros/2026-09-09-zen-browser-global-install.md (zen 全局安装与打包前情)
  - ../../known-issues.md  ## Zen Browser ... 坑 (新增坑 7)
experience:
  - "新版 Firefox 基座(zen 1.21.16b 对应 FF 14x)已彻底移除 GStreamer 后端, H.264/AAC/MP3 解码改为运行时 dlopen 系统 FFmpeg(libavcodec.so.53~63)。打包官方二进制时若不把 ffmpeg 注入进程环境, dlopen 失败 → canvas.canPlayType('video/mp4; avc1') 返回空 → 网课等平台误报『请安装 Flash』。排查时先 strings libxul.so 看 dlopen 目标, 别默认还有 GStreamer 依赖。"
  - "nixpkgs firefox wrapper.nix 的 libs 集是官方二进制(Firefox 家族)该注入哪些运行时库的权威清单: ffmpeg/libva/libgbm/udev/speechd-minimal/cups/pipewire/libpulseaudio/libnotify/libxscrnsaver/vulkan-loader/pciutils/libglvnd/libkrb5。抄它可一次性规避 H.264/AAC/SpeechSynthesis/Notifications 等一大堆『封装后功能缺失』问题。"
  - "ffmpeg 是 split output, 真库在 .lib 输出(libavcodec.so.61/libavutil.so.59/libswresample.so.5), 传给 lib.makeLibraryPath 须用 ffmpeg_7.lib 而不是 ffmpeg_7(指向 -bin)。同理 udev 在 nixpkgs 由 systemd-minimal-libs 提供。"
  - "speechd-minimal 供 SpeechSynthesis API, 缺失会弹『Speech Dispatcher required』错误页; cups 供打印探测。官方 wrapper 默认 speechSynthesisSupport=true 即为 speechd-minimal, 别漏。"
  - "ze 官方二进制在用户环境能跑是因为经 steam-run(FHS 沙盒自带多媒体库/ld-linux)启动; 而 Nix 版 autoPatchelf 只补 NEEDED 硬依赖, 对 dlopen 的库不会管 —— 这是『download 版正常、Nix 版缺能力』的核心差异。"
  - "集成验证不能只看 ldd(NEEDED) 或进程中 avcodec 映, 因为是懒加载 dlopen, 没播过媒体不加载。可用 python ctypes.CDLL 借 wrapper 注入的 LD_LIBRARY_PATH 直接 dlopen 探测 libavcodec/libspeechd 等确认可命中。"
  - "第三方 flake overlay 打包二进制包时, 改动依赖/环境变量会使 store 路径变化; 用 MOZ_LEGACY_PROFILES=1 让 firefox 家族无视 install-id 用 Default=1 的 profile, 避免每次 rebuild 自建新空 profile。"
---

# 复盘: Zen Browser 网课 Flash 误报根因 (ffmpeg dlopen) + SpeechSynthesis 补全

## 背景与症状喵~

用户网购课平台时, 从 `~/Downloads` 经 `nix-shell -p steam-run -- 'steam-run ./zen'` 打开 Zen 1.21.16b 不需要 Flash, 但从 Nix 版 `zen`(home.packages, 私源 Reiky-nixpkgs 打包)打开却被平台提示『请安装 Flash』喵~ 要求排除差异喵~

## 根因分析喵~

1. **Zen 1.21.16b 已移除 GStreamer 后端** 喵~  `strings ~/Downloads/zen/libxul.so | grep gstreamer` 零命中, 而 `grep 'libavcodec.so'` 命中一整列 `libavcodec.so.53` ~ `.63` —— 新版 Firefox 基座改为运行时 dlopen 系统 FFmpeg 解码 H.264/AAC 喵~
2. **Nix 版包装缺 ffmpeg** 喵~  `autoPatchelfHook` 只处理 ELF 的 DT_NEEDED 硬依赖, 对运行时 dlopen 的目标库不管 喵~  私源 makeWrapper 只注入了 XDG_DATA_DIRS/GDK_PIXBUF/GIO 等, 没有 LD_LIBRARY_PATH 里的 ffmpeg 喵~  → dlopen 失败 → `canPlayType('video/mp4; codecs="avc1"')` 返回空 → 网课平台(Flash 时代写的)误报需装 Flash 喵~
3. **Downloads 版为何正常** 喵~  它经 `steam-run`(buildFHSEnv)登录, 环境自带完整 ffmpeg/ld-linux/多媒体库, dlopen 命中喵~
4. **与 profile 无关** 喵~  两个版本共用 `~/.zen` 书签也在 q873pg30 profile 里, 反复 rebuild 冒出的新空 profile 是 wrapper 路径变化 → install-id 漂移的**副作用**, 不是 flash 根因 喵~  用户直觉正确 喵~

## 修复喵~

私源 `pkgs/zen-browser/default.nix`:
- 新增顶层 `mediaLibs` 变量(带注释), 参照 nixpkgs `firefox/wrapper.nix` 的 libs 集: `ffmpeg_7.lib` + `udev/libgbm/libnotify/libxscrnsaver/libpulseaudio/libcanberra-gtk3/libglvnd/vulkan-loader/pciutils/libkrb5` 喵~
- makeWrapper 追加 `--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath mediaLibs}"` + `--set MOZ_ALLOW_DOWNGRADE 1` 喵~
- 实测后用户反馈出现 SpeechSynthesis 报错, 补上 `speechd-minimal` 与 `cups`, 并逐库改写规范注释 喵~

## 验证喵~

- `nix build .#zen-browser` 通过, wrapper 中 LD_LIBRARY_PATH 含 ffmpeg-7.1.5-lib/mesa-libgbm/speech-dispatcher-0.12.1/cups-2.4.19 等 喵~
- 主仓 `nix flake update Reiky-nixpkgs` → `rebuild.sh build` → `rebuild.sh switch`(已授权) 喵~
- 用 python `ctypes.CDLL` 借 zen 进程环境 LD_LIBRARY_PATH 成功 dlopen `libavcodec.so.61`/`libavutil.so.59`/`libswresample.so.5` 喵~
- 用户实测网课平台 Flash 提示消失, 视频正常播放 喵~  SpeechSynthesis 依赖补全 喵~

## 遗留喵~

- Downloads 版 `~/Downloads/zen` 与其 `zen.linux-x86_64.tar.*` 已可删 但按安全铁律不擅动, 用户自行决定 喵~
- 多余 profile(-1 ~ -5)按留证清单建议清理, 见本目录 .retros-index 相关 喵~
