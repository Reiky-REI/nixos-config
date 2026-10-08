---
date: 2026-10-08
module: modules/virtualization/default.nix, lib/features.nix, machines.nix, home/reiky/apps/{communication,media,runtime-configs}.nix
tags: [waydroid, aixue, android, mitm, cert-pinning, merge, workspace-cleanup]
layer: mixed
severity: low
related:
  - 2026-10-08-readme-ai-section.md
---

# 复盘: waydroid E2E 环境并入 main + mitm 抓包死路封存 (2026-10-08)

## 背景

豆包爱学协议逆向项目 (`~/WorkSpace/aixue-reverse`) 用 waydroid 跑 Android 端 app，
仓库侧 `feat/waydroid-aixue` 分支 (`5c5b5f1`) 提供 E2E 环境，一直未合 main 喵。
用户 2026-10-08 裁定：**协议破解 (mitm) 到此为止，只做收尾**喵。

## 变更

- `feat/waydroid-aixue` 并入 main（合并提交 `4b84bfc`）喵，内容：
  - feature 标签 `waydroid` + NixMEOW 挂载喵
  - `virtualisation.waydroid.package` override：内核 7.1.5 移除 legacy iptables 后，
    net.sh 硬编码的 `LXC_USE_NFT="false"` 改为 ENV 优先 (`LXC_USE_NFT:-true`)；
    unit PATH 注入 nftables/kmod/dnsmasq/iproute2 喵
  - binder 走内核内建 binderfs（7.1.5 `CONFIG_ANDROID_BINDERFS=y`），无需外挂模组喵
  - 卸载 QQ/SPlayer/OBS 释放 ~6.3G（含 `runtime-configs.nix` 移除 SPlayer merge）喵
- **丢弃**未提交的 mitm 抓包前置改动（见下），不入境喵。

## mitm 抓包路线封存（死路论证）

原计划：waydroid 出网走宿主 mitm 代理，改动为
`extraArgs = ["-w" "192.168.240.1:8080"]` 喵。实测双墙：
- native cronet：内嵌 Chrome Root Store（编译进 so），系统 CA 信任区被旁路，装 CA 无效喵
- Java/KMP 层：`CertPathValidatorException: Trust anchor ...` →
  networkSecurityConfig 专属证书锚点，不吃系统 CA 喵
- 开 mitm = app 全瘫（学习 tab 占位页），关 proxy + kill 重启才恢复喵

→ 该 `extraArgs` 只会让 app 瘫痪，故**删除、不入境**喵。

被丢弃的改动（留证；文件应恢复到 HEAD 的 waydroid 块）：

```diff
diff --git a/modules/virtualization/default.nix b/modules/virtualization/default.nix
index 6907a24..6e5f5c3 100644
--- a/modules/virtualization/default.nix
+++ b/modules/virtualization/default.nix
@@ -44,6 +44,10 @@ in {
   virtualisation.waydroid = lib.mkIf (config.meow.enabled ? "waydroid") {
     enable = true;
     package = waydroidNetNft;
+    # mitmproxy 抓包前置: 容器出网走宿主 mitm 代理 (waydroid0 网关 IP 喵~)。
+    # 仅代理 http/https; 风险: 若 app 有证书 pinning 会拒连 — 届时切 frida ssl_logger 路线喵~
+    # 代理地址硬编码是刻意的 (waydroid0 为静态网桥), 注释在此认证喵~
+    extraArgs = ["-w" "192.168.240.1:8080"];
   };
 
   systemd.services.waydroid-container.serviceConfig.Environment = with pkgs; [
```

## 验证

- `feat/waydroid-closeout` 分支 `nixos-rebuild build` 通过（合并前后闭包一致，运行系统无变化）喵
- `/etc/nixos` 工作区 `git status` 干净喵

## 遗留 / 封存

- 协议破解（`libsscronet` patch / frida-gadget 重打包）**封存，不追**喵
- aixue 侧主路线 = UI 问答管道，见 home
  `~/.agents/knowledge/retros/2026-10-08-aixue-ui-pipeline-hardening.md` 与
  `~/.agents/knowledge/decisions/2026-10-08-aixue-pipeline-hardening.md` 喵
- 由 `aixue` 会话协作收尾（经 agent-collab `wake.sh` 精确唤起）喵
