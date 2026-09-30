---
date: 2026-10-01
module: hosts/NixMEOW/stage1-boot.nix, hosts/NixMEOW/default.nix
tags: [boot, grub, systemd-boot, dual-boot, uefi, catppuccin, theme, runtime-artifact]
layer: common
severity: medium
related:
  - ../decisions/two-stage-boot-grub-systemd-boot.md (两级启动架构选型)
  - ../known-issues.md (GRUB 脚本不支持 `||`、extraFiles 重拷语义)
experience:
  - "NixOS 只允许一个引导器 (system.build.installBootLoader 是 types.unique); 想在 GRUB 前systemd-boot 后, 第一级必须自建自装, 不能启用 boot.loader.grub"
  - "grub-mkstandalone 生成的单文件 EFI 默认内含全部模块; 主题/字体可 graft 进 memdisk, GRUB 端用 (memdisk)/... 引用; 但 nixpkgs 包内没有默认 starfield/unicode 资源, 要显式 --themes= --fonts= 清空"
  - "GRUB 脚本解析器不支持 `||` 短路, 条件回退必须写 if ! cmd ; then ... fi"
  - "systemd-boot builder 的 extraFiles 每次安装先删旧文件再重拷; 持久化状态 (grubenv) 不能放进 extraFiles, 应由独立服务只在缺失时创建"
  - "flake 工作树内容会嵌进所有 host 的配置, toplevel drvPath 不能当 host 隔离判据; 应 diff 关键命名空间 (systemd.services/paths/boot.loader)"
  - "第三方壁纸不进公开仓库: 内嵌 MIT 主题官方背景兜底, 本机由运行期服务从 Noctalia 当前壁纸生成背景写入 ESP"
---

# MEOW 两级启动菜单 (stage-1 GRUB) 实施复盘

## 背景与需求

用户要求: 每次开机先选 Windows / NixOS 喵, 默认启动项 = 上次选择的系统喵, 并且第一级菜单要好看 (Catppuccin 主题)喵~ 同时仓库是 **公开** 的喵, 当前壁纸是第三方插画, 不能提交进 git 喵~

## 架构

```
UEFI
 └─ MEOW Boot Menu (自建 GRUB, /EFI/MEOW-OS/grubx64.efi)
      ├─ NixOS   → chainload /EFI/systemd/systemd-bootx64.efi (选 NixOS 世代)
      └─ Windows → chainload (Windows ESP)/EFI/Microsoft/Boot/bootmgfw.efi
```

- 第一级 GRUB 由 `grub-mkstandalone` 构建成**单文件 EFI**喵: 菜单 cfg + 全部模块 + Catppuccin Mocha 主题 (背景/logo/图标/字体) 全部内嵌 memdisk 喵~
- 第二级 systemd-boot 保持 NixOS 托管喵, 世代菜单照常更新喵~
- 「上次选择的系统」用 `grubenv` 的 `saved_entry` 记忆喵: 每个菜单项写 `saved_entry="${chosen}"` + `save_env` 喵, 启动时 `load_env` 读回并 `set default` 喵~
- 主题两套 theme.txt 喵: `theme-stock.txt` 指向内嵌官方背景 (兜底)喵; `theme-esp.txt` 指向 ESP 上的运行期背景 `/EFI/MEOW-OS/boot-background.png` 喵, 文件不存在时自动用官方版喵~

## 为什么自装 GRUB

NixOS 的 `system.build.installBootLoader` 是 `types.unique` (只允许一个引导器)喵; 同时启用 `boot.loader.grub` 和 `boot.loader.systemd-boot` 会在 eval 阶段冲突喵~ 因此第一级 GRUB 由本模块自己构建、经 `boot.loader.systemd-boot.extraFiles` 拷进 ESP喵, 不碰 NixOS 的引导器管线喵~

## 运行期背景注入 (不开源壁纸)

- `meow-stage1-background.service` 按优先级取图喵: `~/.config/meow-boot/background` (软链或一行路径) > Noctalia `~/.cache/noctalia/wallpapers.json` 的 eDP-1 dark 喵~
- 处理: `magick` 居中裁剪 2560x1600 + 压暗 15% + `PNG24` 无 alpha喵, 写 ESP喵; 源文件指纹不变且目标存在时跳过喵~
- `meow-stage1-background.path` 监视 Noctalia 缓存与覆盖文件喵, 壁纸一换即时刷新喵~
- 仓库里只有 MIT 的 `pkgs.catppuccin-grub` (官方背景作兜底)喵, 第三方图不进 git喵~

## grubenv 与服务

- `meow-stage1-boot.service` (开机 + switch): grubenv 缺失时 `grub-editenv create` 并初始化 `saved_entry=meow-nixos`喵; 用 efibootmgr 幂等注册 `MEOW Boot Menu` 并把它排到 BootOrder 首位 (只增不删, 全 best-effort)喵~
- 为什么 grubenv 不放 extraFiles: builder 每次安装都会先删后拷 extraFiles 喵, 会重置记忆喵~

## 踩坑记录

1. **GRUB 脚本不支持 `||`**喵: `cmd1 || cmd2` 直接 syntax error喵, 用 `if ! cmd ; then ... fi` 喵~
2. **Nix 缩进字符串转义**喵: GRUB 的 `${chosen}`/`${saved_entry}` 要写 `''${...}` 喵, bash 里的 `''` (如 `read -d ''`) 要写 `'''` 喵~
3. **`grub-mkstandalone` 默认 `--themes=starfield --fonts=unicode`** 喵, 但 nixpkgs 包 `share/grub` 下没有这些资源喵; 必须显式 `--themes= --fonts= --locales=` 清空喵~
4. **`systemd.paths` 服务不能 `RemainAfterExit=true`**喵, 否则二次触发 start 会被当成 no-op, 背景不会更新喵~
5. **drvPath 不是 host 隔离判据**喵: flake 源快照会嵌进所有 host 配置, 任何树内容变化都会让全部 drvPath 变喵; 隔离性要用关键命名空间 diff 验证喵 (本次实测 WSL/CTR services/paths/timers/loader 零差异)喵~
6. **`--themes=` 生成的镜像里主题文件在 memdisk**喵, 用 `(memdisk)/boot/grub/themes/meow/...` 引用喵; 背景则走绝对路径 `/EFI/MEOW-OS/...` (解析到 `$root`)喵~

## 验证

- `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过喵 (toplevel `/nix/store/bcw2k3r1n3v4bhjajkidzhdxfrwqy4sb-nixos-system-NixMEOW-...`)喵~
- `grub-script-check` 检查生成的 cfg: 语法 OK 喵~
- theme-stock/theme-esp 的 `desktop-image` 行正确喵; 生成的 EFI (5.6MB) 内嵌 `theme-esp.txt`/`bootmgfw`/`meow-nixos`/`gfxmenu` 标记喵~
- host 隔离: NixMEOW-WSL / NixMEOW-CTR 的关键命名空间 diff 为空喵 (只有 NixMEOW 增加 1 个 extraFile + 1 个 path + 2 个 service)喵~

## 待验收 (重启清单)

- [ ] 开机出现 GRUB「MEOW Boot Menu」, 背景是当前壁纸, 预选=NixOS (首次)喵
- [ ] 选 NixOS → systemd-boot 世代菜单 → 正常进系统喵
- [ ] 选 Windows → 正常进入 Windows喵; 再重启时 GRUB 预选=Windows 喵
- [ ] 从 Windows 回来选 NixOS, 下次预选=NixOS 喵
- [ ] F12 固件菜单仍能看到「Linux Boot Manager」(systemd-boot 直启兜底)喵
- [ ] 换桌面壁纸后, 下次 (或即时) GRUB 背景跟随更新喵
