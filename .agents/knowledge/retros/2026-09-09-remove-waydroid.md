---
date: 2026-09-09
module: modules/virtualization/default.nix, hosts/MEOW/default.nix, flake.nix, justfile, home/Reiky-REI/desktop/niri/sections/high.kdl
tags: [waydroid, 移除, virtualization, disk-cleanup, 留证]
layer: services
severity: medium
related:
  - ../retros/2026-05-25-waydroid-apps.md (waydroid 初装与 overlay)
  - ../retros/2026-05-26-waydroid-arm-translation.md (ARM 翻译层)
  - ../retros/2026-05-27-waydroid-gbinder-aidl3.md (aidl3 修复)
  - ../../known-issues.md (白闪元凶: Waydroid surfaceflinger 崩溃循环 — 本篇即终局)
experience:
  - "移除一个模块前先 grep 全仓引用面(含 justfile/niri kdl/hosts 用户组/flake 注释), 功能代码与文档分开处理 —— 本次功能配置 5 处一次清干净, .agents/knowledge 文档只加终局注记不删历史喵~"
  - "waydroid-container 运行时其应用数据由 root 写入 ~/.local/share/waydroid/data, 用户态 rm 会权限不够 —— 先 switch 移除服务, 再 sudo 删数据, 顺序要对喵~"
  - "du -sh 6.0G 的 /var/lib/waydroid 删除后 df 只涨 ~1G: Android 镜像多为稀疏文件, 实际占用远小于 du 估值, 清理预期别按 du 报数拍脑袋喵~"
  - "删除前留证清单(find 目录树 + sha256sum)对 6G 语料约 30s-2min, 可接受; 清单放 ~/delete-manifest-<目标>-<时间戳>.txt 统一命名喵~"
  - "waydroid 移除附带收益: 系统内存从 11G 用(8.2G swap)降到 6G 用 —— surfaceflinger 崩溃循环 + 容器常驻是长期内存黑洞, 闪退不只是功能问题喵~"
---

# 复盘: Waydroid 全量移除 (配置 + 磁盘)

## 背景喵~

waydroid 从 2026-08-16 起 surfaceflinger 崩溃循环(白闪元凶), 启动项早已注释禁用自启喵~ 但用户手动使用时持续闪退, 决定彻底移除喵~ 移除时 `/var/lib/waydroid` 已积累 6G(du 值)喵~

## 改动喵~

| 文件 | 变更 |
|------|------|
| `modules/virtualization/default.nix` | 重写: 删 ndkTranslation fetch、waydroid nftables overlay、`virtualisation.waydroid.enable`、waydroid-helper、gbinder aidl3 覆盖、arm-translation activation; 保留 podman/libvirtd/virt-manager 喵~ |
| `hosts/MEOW/default.nix` | extraGroups 去 `waydroid` 喵~ |
| `flake.nix` | 删 waydroid overlay 注释行喵~ |
| `justfile` | 删 `install-apk` recipe喵~ |
| `high.kdl` | 删注释掉的 `waydroid session start` spawn 喵~ |

## 执行顺序喵~

1. feature branch `chore/remove-waydroid` → 改配置 → `rebuild.sh build` 通过喵~
2. `nvidia-smi` 确认 GPU 只有 llama-cpp 系统服务无 dsh-fence 手动进程 → `rebuild.sh switch` 成功喵~ switch 输出确认 `/etc/gbinder.d/waydroid.conf` + `/etc/lxc/*` 符号链接被移除喵~
3. 验证: `waydroid-container.service` not found、waydroid 命令消失、用户组移除喵~
4. 留证: `~/delete-manifest-waydroid-20260909-124647.txt` (目录树 + 194 文件 SHA256)喵~
5. 删除: `sudo rm -r /var/lib/waydroid`(6G) + `sudo rm -r ~/.local/share/waydroid`(root 属主数据)喵~
6. 顺带 GC: 旧世代里 waydroid 包路径回收 673MB喵~

## 结果喵~

- 磁盘 78% → 74%(连同后续缓存清理)喵~
- 内存 11G 用 / 8.2G swap → 6G 用(释放大量 RAM + swap)喵~
- 保留: podman / libvirtd / virt-manager 不受影响喵~

## 经验喵~

见 frontmatter `experience` 喵~ 核心一条: waydroid 的闪退不是偶发 bug 而是容器常驻吃内存 + surfaceflinger 崩溃的结构性问题, 移除是合理终局; 若未来要 Android 容器, 按 2026-05-25 复盘重建并先测新版图形栈喵~
