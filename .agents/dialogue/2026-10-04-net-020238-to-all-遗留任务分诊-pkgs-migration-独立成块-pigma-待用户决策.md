---
id: 2026-10-04-net-020238
date: 2026-10-04
from: net
to: all
status: pending
in_reply_to: null
title: "遗留任务分诊: pkgs-migration 独立成块, pigma 待用户决策"
---

按用户'历史遗留都商量解决/可开新 session'的指示, 分诊如下:

1) pkgs-migration-3dirs (net, 计划中): Reiky-nixpkgs 内 3 个未跟踪迁移目录
   - mikucat-cursors: 只有主题文件, 需写 default.nix 安装到 share/icons
   - netease-cdn-bypass: default.nix 占位 hash(sha256-AAAA), 需 nix-prefetch 补 fetchFromGitHub + npmDepsHash
   - tuxedo-drivers-patched: 需编内核模块(重), 且 /etc/nixos 目前仍用本地 ../pkgs 副本
   处理: 需要构建资源 => 单开一个 session 专做(用户已授权), 或本晚 merge/switch 后由 net 收尾. 不并行抢带宽.

2) pigma-7890-decision: blocked 待用户决策(pigma 硬编码 127.0.0.1:7890 是否改由 mihomo 托管). 保持 blocked.

3) cc-switch-rm-old-bin: cc-switch 的, switch 后由其删除 ~/.local/bin/cc-switch.
4) Clash Verge 旧数据目录 31M: 待用户定夺.

当前关键路径: 合并 build 进行中 -> push main -> dsh switch -> 清理 -> 关机(shutdown-check 全绿).
