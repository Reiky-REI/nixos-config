---
date: 2026-10-04
module: pkgs/dsh-plugins, home/reiky/tools/dsh-profile.nix, home/reiky/tools/dsh-profile/{package.json,pnpm-lock.yaml}
tags: [dsh, dsh-plugins, nix-pure, vendor, pnpm, buildNpmPackage, multi-agent]
layer: mixed
severity: medium
related:
  - ../../../.agents/knowledge/decisions/2026-10-04-dsh-profile-nix-pure-plan.md
  - 2026-10-03-deepsec-nix-reproducible-build.md
  - ../../known-issues.md
---

# 复盘: dsh profile 插件依赖 nix-pure 化 (2026-10-04)

## 背景

用户要求把 dsh profile 尽量做到 pure (可复现 / 可版本管理)喵~ dsh profile 的
`package.json` 里有 6 个本地依赖指向 `~/WorkSpace` 的可变目录 (无 rev、无 diff、
无回滚点)喵~ 用户 2026-10-04 拍板 (经 net 转达): mode-boost / nxwatch /
dsh-deepsec-guard **vendor 进配置仓**, pure-nix 方案由 dsh 牵头喵~

本任务在 dsh 会话 (workspace-write 沙箱, 写不了 `/etc/nixos`) 内完成, 做法是
把 `/etc/nixos` clone 到 `~/WorkSpace/dsh-nix-pure/nixos`, 在
`feat/dsh-plugins-nix-pure` 分支上做完 + 验证 + push, 由沙箱外合并喵~

## 变更

- `pkgs/dsh-plugins/mk-js-bundle.nix`: 形态① (源码自带 `lib/`) 的通用打包器
- `pkgs/dsh-plugins/vendors/{nxwatch,dsh-deepsec-guard,mode-boost}`: 无上游 /
  上游取不到 rev 的三个插件, 由配置仓 git 管版本 (provenance 见 `vendors/VENDOR.md`)
- `pkgs/dsh-plugins/{nxwatch,deepsec-guard,mode-boost}.nix`: vendor 来源
- `pkgs/dsh-plugins/{deepsec-shield,deepsec-spear}.nix`: `fetchFromGitHub`
  `Unclecheng-li/DeepSec @ fff031f`
- `pkgs/dsh-plugins/super-injector.nix` + `super-injector/package-lock.json`:
  `buildNpmPackage` (`yjh051108/dsh-routing-suite @ 1952733`)
- `home/reiky/tools/dsh-profile.nix`: `substHome` 泛化为 `subst` (占位符 map)
- `home/reiky/tools/dsh-profile/{package.json,pnpm-lock.yaml}`: 本地依赖改
  `link:@DSH_*@` 占位符, lock 重生成

## 关键发现 / 坑

1. **pnpm 会把绝对 store path 规范化成相对路径**喵~
   `link:/nix/store/<hash>-x` 在 lock 里变成
   `specifier: link:/nix/store/...` + `version: link:../../../../../nix/store/...`喵~
   → 所以占位符要两套: `@DSH_X@` (绝对) 与 `@DSH_X_REL@` (相对, 前缀 = 从
   profile 目录回到 `/` 的 `../` 串)喵~ 好消息: 相对深度对
   `<home>/.dsh/profiles/<name>` 固定, 可用 `lib.replicate` 算喵~
2. `file:` 目录会多一层 `.pnpm/<name>@file+...` 虚拟站且 lock 没有 integrity;
   `file:` tarball 才有 `integrity(sha512)`, 但需要确定性 tgz (mtime/sort/owner)喵~
   **最终选 `link:`** —— store path 本身就是内容寻址 (hash 覆盖全部内容)喵~
3. **`buildNpmPackage` 离线 `npm ci` 依赖上游 lock 完整**喵~ super-injector 上游
   `package-lock.json` 有 36/75 个包缺 `resolved` URL (npm/cli#6301),
   v1 fetcher 缓存不到 → `ENOTCACHED`; v2 fetcher 也修不了缺失 URL喵~
   最终: `npm install --package-lock-only` 重建完整 lock pin 进本仓,
   在 `fetchFromGitHub` 的 `postFetch` 里覆盖上游那份 (这样 npmDeps fetcher 与
   build 用同一份 lock)喵~
4. **现状 pnpm = 11.27.0** (决策文档里 11.18.0 已过时)喵~ 生成 lock 必须在与
   profile **同深度**的目录里跑 pnpm, 否则相对路径深度不对喵~
5. 验收时发现 `dsh-profile.nix` 的 `@HOME@` 会替换到 `pnpm-workspace.yaml` 的注释里,
   使 store 里注释读起来怪怪的 (无害)喵~

## 验证

- 6 个 derivation `nix build` 全绿
- 整机 `nixos-rebuild build` 通过 (取 `collab.sh lock rebuild`, 完释放)
- home-manager 生成的 profile package.json 含 store link; 生成的 `pnpm-lock.yaml`
  与 pnpm 生成结果**逐字节一致**
- `pnpm install --frozen-lockfile` 通过, node_modules 全软链 `/nix/store`
- `dsh --profile <pure> --dump-config`: 9 bundle + `cordis.patch.yml` 4 个 insert 全在
- `deepsec-guard scan-dir pkgs/dsh-plugins` = ALLOW

## 后续

- 切换后需手动 `dsh plugin --profile web install` (dsh 不会自动 install)
- `mode-boost` 若上游 merge 了带 `dsh.bundle` 的版本, 可切回 `fetchFromGitHub`
- `super-injector` 的上游 lock 缺陷值得给上游提 PR
