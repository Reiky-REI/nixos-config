# 复盘: Waydroid Notion/Apple Music 配置 + nftables 修复

## 改动
- `modules/virtualization.nix`: 添加 `waydroid-helper`、`nftables`、`boot.kernelModules = ["nf_tables"]`
- `home/Reiky-REI/apps/media.nix`: 添加 `cider` (Apple Music 原生客户端)
- `justfile`: 添加 `install-apk` 命令
- `flake.nix`: overlay 修补 `waydroid-net.sh` 使用 nftables (LXC_USE_NFT=true + 添加 nftables 到 PATH)
- 用户组已添加 `waydroid` (之前 commit)

## 坑
- `linuxPackages_latest` (kernel 7.0.9) 缺少 `ip_tables.ko` 模块
  - `CONFIG_NETFILTER_XTABLES_LEGACY` 未开启导致 legacy iptables 不可用
  - 修复: 改用 nftables 模式 (`LXC_USE_NFT=true`)，安装 `nftables` + `boot.kernelModules`
- Waydroid 1.6.2 (unstable) 移除了 `-w` 参数，与锁定的 NixOS 模块服务定义冲突
  - 修复: 避免使用 unstable waydroid，改为 overlay 修补 locked waydroid (1.5.4)
- overlay 的 `preFixup` 需要先于 `wrapProgram` 运行修补脚本
  - `.waydroid-net.sh-wrapped` 在 `wrapProgram` 之后才创建
  - 修复: 用新的 `preFixup` 替换旧的，在 wrap 前修补并同时添加 nftables 到 PATH

## 待做
- [ ] 下载 Notion APK: `just install-apk notion <url>` 或从 APKMirror 下载后 `waydroid app install`
- [ ] 测试 Apple Music (Waydroid 版)，如果 FairPlay DRM 不行则使用 Cider
- [ ] 可选: 配置 ARM 翻译: `sudo waydroid-helper -i`
