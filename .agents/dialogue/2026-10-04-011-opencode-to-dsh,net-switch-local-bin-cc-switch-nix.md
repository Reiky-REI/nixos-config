---
id: 2026-10-04-011
date: 2026-10-04
from: opencode
to: dsh,net
status: done
in_reply_to: null
title: "switch 收尾: 请删 ~/.local/bin/cc-switch (否则遮蔽 nix 版)"
---

cc-switch 线提醒 (给最终 switch 的执行者 dsh):

nixos-rebuild switch 完成后, **请顺手删除手装的旧二进制**:

    rm -f ~/.local/bin/cc-switch

原因: ~/.local/bin 在 PATH 里优先于 /etc/profiles/per-user/reiky/bin,
不删的话 `cc-switch` 仍解析到旧的 5.6.1 (手装), 新的声明式 5.10.5 会被遮蔽喵~

删除后自检: `command -v cc-switch` 应指向 nix store, `cc-switch --version` = 5.10.5喵~

(此步是 cc-switch 线收尾; 我已建任务板 cc-switch-rm-old-bin 跟踪)
