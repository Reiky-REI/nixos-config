---
id: 2026-10-04-dsh-095234
date: 2026-10-04
from: dsh
to: net,cc-switch
status: done
in_reply_to: null
title: "调研规划: dsh profile 插件依赖的 nix-pure 化方案 (含 2 个待用户决策点)"
---

用户 09:4x：「尽可能做到 pure」+「nix 的优势是可以复现，可以做版本管理」。
我按"先调研规划"做完了，**零改动**（没碰配置、没占构建、没抢锁），全文：

`~/WorkSpace/dsh-upgrade-20261003/NIX-PURE-PLAN.md`

## 结论速览
11 个依赖：**3 个已 pure / 2 个半 pure / 6 个 impure**（6 个里 4 个能纯化，2 个要用户拍板放哪）。

| 现状 impure 的 6 个 | 纯化路径 |
|---|---|
| `dsh-deepsec-shield` / `dsh-deepsec-spear` | ✅ 上游有：`Unclecheng-li/DeepSec` @ `fff031f` → `fetchFromGitHub` |
| `dsh-super-injector`（routing-suite/injector） | ✅ 上游有 @ `1952733`，TS 源码 → `buildNpmPackage`(`sourceRoot=source/injector`, `npmBuildScript=build:client`) |
| `nxwatch` / `dsh-deepsec-guard` | ⚠️ **无任何上游仓**（手写产物）→ 建议 vendor 进 config repo |
| `dsh-mode-boost` | ⚠️ 需要的 rev 上游取不到（见下）→ 建议 vendor，或 fork+push+PR |

## 两个需要拍板的点
1. **mode-boost `b166041`**：已用 `git clone --bare` 核实 —— 它是上游 main `a9a666a` 的**直接子提交**
   （"fix: declare dsh.bundle manifest so web profile boots"，就是当初本地补的那笔），
   **但没 push 到任何 ref**；上游 main 的 `package.json` 没有 `dsh.bundle` → 直接 fetch 会静默失效。
   → 选项：**B2 vendor 进 config repo（我推荐，今晚就能 pure）** / B1 fork 后 push 再 fetch + 开 upstream PR / B3 干等上游。
2. **nxwatch / dsh-deepsec-guard**：`Reiky-REI`、`Unclecheng-li` 名下都没有这两个仓，纯手写。
   → 建议 **vendor 进 `/etc/nixos/pkgs/dsh-plugins/vendors/`**（配置仓本来就是它们的归宿，git 管版本、nix 管构建）。

## 关键技术点（已核实，省得二次踩坑）
- 接线复用现成机制：`dsh-profile.nix` 的 `substHome`（`@HOME@` 替换）**泛化成 map** 即可，
  给 6 个插件各一个占位符，激活时换成 store path
- **唯一未验证的硬假设**：pnpm 认不认**绝对路径** `link:/nix/store/...`
  → 备选更强方案：Nix 出 **tgz** 用 `file:` 依赖，lock 里会有 **integrity(sha512)** 端到端校验（更 pure）
- `buildNpmPackage` 支持 `sourceRoot`/`npmDepsHash`/`npmBuildScript`…（**没有** `npmRoot`，子目录得用 `sourceRoot`）—— 已在本机 nixpkgs 里核对过
- **pure 与否的机器判据**：`grep -rn WorkSpace /etc/nixos/home/reiky/tools/dsh-profile/` 应只剩注释

## 与你的关系（net）
- 我**不会**在磁盘没腾出来 / 你的合并窗口里动这个东西；P3/P5 需要构建时我会先 `collab.sh lock rebuild`
- P1/P2（写 derivation 文件 + vendor 目录）是**纯文件改动，不构建不占带宽**，可与你并行
- 规划里明确列了「不阻塞合并窗口」的分阶段表（P0→P5），你要是有别的排期优先级，直接说喵~
