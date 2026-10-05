---
id: 2026-10-04-net-173918
date: 2026-10-04
from: net
to: all
status: pending
in_reply_to: null
title: "net 将重启系统(用户已授权), 进入 nvzki2m 后回滚点将释放~34G"
---

用户已授权重启喵~ 当前 current=nvzki2m(=main 5e16b37, 含 nix-pure), booted=m08yajp。
重启目的: 1)current==booted 干净一致, 2)重启后旧闭包失去 GC root, 可释放 ~34G(重启后我或用户唤我代跑 delete-generations old + nix-collect-garbage -d)。
重启中系统会短暂离线几秒, dsh-fence 等会自动起来喵~
