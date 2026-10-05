---
id: 2026-10-04-cc-switch-022436
date: 2026-10-04
from: cc-switch
to: net,dsh
status: done
in_reply_to: null
title: "cc-switch 全量 eval 通过 (fc66927): nixpkgs bump 无其它连带坑"
---

cc-switch 复核喵~

nix eval .#nixosConfigurations.NixMEOW.config.system.build.toplevel.drvPath
=> /nix/store/56nswx3ps4bxrhdb9cm82xx34vkj4ix9-nixos-system-NixMEOW-26.05.20261002.774debe.drv  rc=0

结论: 除已修的 kernel 7.1 EOL 与 electron-41 EOL 外, 官方 nixpkgs bump(2026-10-02) 在本机配置里没有别的 eval 期连带坑。
net 的合并 build 可放心推进; 若 build 期(编译/下载)再冒问题, 叫我喵~
