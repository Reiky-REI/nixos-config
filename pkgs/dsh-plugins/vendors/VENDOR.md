# vendors/ — 无上游仓 (或上游取不到所需 rev) 的 dsh 插件源码

这些目录由**本配置仓 git 管版本**, 由 `pkgs/dsh-plugins/*.nix` 原样拷进 Nix store。
收编决定见用户 2026-10-04 拍板 (对话板 `2026-10-04-net-161716-to-dsh`) 与
`~/.agents/knowledge/decisions/2026-10-04-dsh-profile-nix-pure-plan.md`。

## nxwatch

- 来源: 手写产物, 无任何远程仓
- 收编自: `~/WorkSpace/nxwatch` (2026-10-04)
- 内容: `package.json` + `lib/{index.js,client.js}`
- 内容 sha256 (find -type f | sort | xargs cat):
  `414e02bb1538d8467b34ddf28d5ac115724e8994f6390911a99a3b3280ea4957`

## dsh-deepsec-guard

- 来源: 手写产物, 无任何远程仓
- 收编自: `~/WorkSpace/dsh-deepsec-guard` (2026-10-04)
- 内容: `package.json` + `lib/index.js` + `cordis.patch.yml`
- 内容 sha256:
  `ec66cba51cdbdef2041932f1ef31337fae66ed1b549995da31c0af3dfccad7a4`

## mode-boost

- 来源: `github.com/yjh051108/dsh-mode-boost` (dsh-routing-suite 的旧 submodule)
- 需要的 rev: `b166041fd66834177a9c7001d2d411b7d81f5fa5`
  ("fix: declare dsh.bundle manifest (cordis.patch.yml) so web profile boots")
- **该 rev 没有 push 到任何 ref** (git clone --bare 核实); 上游 main `a9a666a` 的
  `package.json` 没有 `dsh.bundle` 字段 → `fetchFromGitHub` 会拿到不被 dsh 注册为
  bundle 的版本 (静默失效)。故 B2 vendor。
- 收编自: `~/WorkSpace/dsh-routing-suite/mode-boost` (含 `.git` = `../.git/modules/mode-boost`)
- 内容: `package.json` + `lib/{index.js,core.js}` + `cordis.patch.yml` + `README.md`
  + `scripts/build.sh` (lib/ 已构建, 不需再跑 build)
- 内容 sha256:
  `92456d5af173ce0db2b77596d37d3d04303fc652ca90f7b4aaa3187cebf3b47b`
- 后续: 若上游 merge 了带 `dsh.bundle` 的版本, 可切回 `fetchFromGitHub` 并删除本目录

## super-injector 的 lock

`../super-injector/package-lock.json` 是从上游 `yjh051108/dsh-routing-suite @ 1952733`
的 `injector/package-lock.json` **重建**的完整 lock (上游那份 36/75 包缺 `resolved`
URL, 见 npm/cli#6301, 会导致离线 `npm ci` ENOTCACHED)。重建命令:
`npm install --package-lock-only --ignore-scripts --legacy-peer-deps`。
