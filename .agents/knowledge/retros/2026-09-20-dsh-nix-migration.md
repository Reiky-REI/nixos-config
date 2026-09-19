---
date: 2026-09-20
module: modules/services/dsh-fence.nix, home/Reiky-REI/tools/dsh.nix, flake.lock, Reiky-nixpkgs/pkgs/dsh
tags: [dsh, Reiky-nixpkgs, npm, 声明式, dsh-fence, 端口冲突]
layer: services
severity: medium
related:
  - 2026-09-20-dsh-fence-dead-dep.md (同属 dsh-fence 排障)
  - ../known-issues.md (3080 端口冲突 / dsh 手动 web)
  - ../conventions.md (打包归属: nixpkgs 没有的包进 Reiky-nixpkgs)
experience:
  - "npm 包 '最新版' 可能装着装着就 404: 先 npm view <dep> versions 验证依赖是否真的发布, 别默认 latest 可装"
  - "从 npm tarball 打包 CLI: buildNpmPackage + 目录内自备 package-lock.json (上游 tarball 不带 lock), 用 runCommandLocal 把 lock 拼进 src"
  - "systemd 服务换成 nix 包后仍可能被'手动跑同一命令'抢占端口 — 换包解决不了行为习惯, 需另外拦截"
  - "删除/回收前按铁律留证: find 生成文件清单 + sha256sum 清单, 再整目录移动归档而非直接 rm"
---

# dsh 从 npm 局部安装回收到 Nix 声明式管理

## 背景
用户要求把 `dsh`（DeepSeek Harness）从家目录 `npm install` 回收到 nix 管理系统喵~ 按新约定（nixpkgs 没有的包 → Reiky-nixpkgs 私源）打包喵~

## 版本坑（重要）
原计划升到 npm latest `0.1.5-rc.2`，但 `npm install --package-lock-only` 报 **E404**：它依赖
`@deepseek-ai/dsh-experimental-code-runtime-python@^0.1.5-rc.2`，而该包在 registry 上
**从未发布**（`npm view ... versions` 也是 404）→ 属上游发布断裂，最新版根本装不上喵~
故固定 **0.1.1-rc.2**（用户原本在用的版本），并在 README 记录原因待上游修复喵~

## 打包（Reiky-nixpkgs/pkgs/dsh）
- `fetchurl` 取 npm tarball（hash `sha256-R+wF...`）
- 本地生成 `package-lock.json`（566 包）随包提交；`runCommandLocal` 把它拼进 src 后交给 `buildNpmPackage`
- `dontNpmBuild = true`（tarball 已含编译产物）；`npmDepsHash = sha256-8ajk...`
- `postInstall` 用 `makeWrapper` 把 shebang 换成显式 `nodejs_22`，并补 `--expose-internals`（与 dsh-fence 原调用一致）
- 单测：`nix build .#dsh` → `./result/bin/dsh --version` = `0.1.1-rc.2` 喵~

## 主仓接线
- `modules/services/dsh-fence.nix`：删掉 `binPath` 选项，新增 `package`（默认 `pkgs.dsh`），`ExecStart = ${cfg.package}/bin/dsh web ...`
- `home/Reiky-REI/tools/dsh.nix`：新增，`home.packages = [pkgs.dsh]`
- `flake.lock`：`--update-input Reiky-nixpkgs` → rev `5f09148`

## 回收 npm 安装（留证式）
- 归档目录：`~/.local/state/legacy-npm-dsh-20260920/`
- 留证：`manifest-files.txt`（29195 个文件）+ `manifest-sha256.txt`（完整哈希）
- 处理：`node_modules`（259M）+ `package.json` + `package-lock.json` **整体 mv** 进归档（非 rm，可随时还原）喵~

## 坑：换包解决不了手动抢占
switch 后 dsh-fence 立刻 `EADDRINUSE 127.0.0.1:3080` —— 有人**又手动跑了**
`dsh web --no-open`（pid 1485130）喵~ 精确 kill 后服务才绑定成功（local/远程均 200）喵~
结论：`dsh web` 与 `dsh-fence` 天然互斥，需要行为层拦截（待办）喵~
