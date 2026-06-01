---
date: 2026-05-31
module: home/Reiky-REI/dev/default.nix, opencode.json, hosts/MEOW/opencode.json
tags: [opencode, LSP, dev-tools]
layer: home
severity: medium
related:
  - ../retros/2026-05-25-opencode-merge.md (LSP 配置合并来源)
  - ../../known-issues.md
experience:
  - "opencode 读的是项目根目录的 opencode.json，hosts/ 下的不会被加载"
  - "nil 替换为 nixd，因为 nixd 支持 NixOS options 补全"
  - "haskell-language-server 依赖 GHC 过大（~500MB），按需启用"
---
