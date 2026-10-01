---
date: 2026-10-01
tags: [boot, grub, systemd-boot, dual-boot, uefi, reproducibility, architecture]
---

# 决策: 两级启动菜单 (Boot Menu GRUB + systemd-boot 世代菜单)

## 背景

需求四条喵: ① 每次开机可选 Windows / NixOS喵; ② 默认项 = 上次选择的系统喵; ③ 第一级菜单要有主题美化 (用户选了 Catppuccin Mocha + 当前桌面壁纸作背景)喵; ④ 仓库公开, 第三方壁纸不能提交进 git, 同时配置要保持可复现喵~

## 备选方案

| 方案 | 结论 | 原因 |
|------|------|------|
| A. 单菜单 systemd-boot (`windows` 选项 + `default @saved`) | 否决 | 用户明确要 GRUB 在前; 且跨 ESP 的 Windows 项需要 EDK2 shell handle 技巧 |
| B. `boot.loader.grub` + `boot.loader.systemd-boot` 都启用 | 不可行 | `system.build.installBootLoader` 是 `types.unique`, 只允许一个引导器, eval 直接冲突 |
| C. 自建第一级 GRUB + 保留 systemd-boot 托管 | **采用** | 两级需求都满足; systemd-boot 世代刷新不受影响 |
| D. 把当前壁纸提交进公开仓库 | 否决 | 第三方插画版权 + 公开仓库发布风险 |
| E. 背景用软链接指向仓库外文件 | 不可行 (构建期) | 纯求值看不到 git 之外的文件, 且 ESP 是 FAT32 没有软链接 |
| F. 运行期背景注入 + MIT 官方背景兜底 | **采用** | 仓库可复现且干净; 本机仍显示自己的壁纸 |

## 决策

1. 第一级 GRUB 由 `hosts/NixMEOW/boot-menu.nix` 用 `grub-mkstandalone` 构建成单文件 EFI 喵, 经 `extraFiles` 进 ESP喵; 菜单: NixOS (chainload systemd-boot) / Windows (chainload bootmgfw.efi)喵~
2. 「上次选择的系统」由 GRUB `grubenv` + `saved_entry` 记忆喵, 记忆文件由 `meow-boot-menu.service` 在缺失时创建, 不随 rebuild 重置喵~
3. 背景: 仓库内嵌 `pkgs.catppuccin-grub` 的官方背景兜底喵; 本机运行期由 `meow-boot-menu-wallpaper.service` 从 Noctalia 当前壁纸生成 2560x1600 背景写 ESP喵, 支持 `~/.config/meow-boot/background` 指定覆盖喵~
4. 该模块是 **host-local** 的喵: 只有双系统的 NixMEOW import 它喵, 无 Windows 的 host 不会受影响喵~
5. 命名: 模块 `hosts/<host>/boot-menu.nix` 喵, 单元 `meow-boot-menu{,-wallpaper}` 喵; 固件启动项叫 "MEOW Boot Menu" 喵~ 刻意不用 `stage1/stage2` 作标识符 (GRUB 历史内部概念占用), "第一级/第二级" 只作层级描述喵~

## 影响与风险

- 第一级是静态文件 + 两个 best-effort 服务喵; 服务失败不会阻塞 switch, 也不影响 systemd-boot 的世代刷新喵~
- 不删除任何现有 EFI 启动项喵, F12 仍可用「Linux Boot Manager」直启 systemd-boot 兜底喵~
- Windows 更新/BIOS 可能抢回 BootOrder 喵, 服务每次开机幂等校正喵~
- 背景是运行时不变量喵: 换壁纸后由 `.path` 监视器即时刷新, 服务失败/文件删除时自动回退官方背景喵~

## 回滚

- 删除 `hosts/NixMEOW/default.nix` 的 import 与 `boot-menu.nix`, rebuild + switch 即可回到 systemd-boot 直启喵 (可选: 用 efibootmgr 删除 `MEOW Boot Menu` 项)喵~
- 应急入口: 固件 F12 → Linux Boot Manager喵~
