# dsh (DeepSeek Harness) profile 插件的 nix-pure 打包入口。
#
# dsh profile 的依赖分两类:
#   1. registry / git 依赖: 继续交给 pnpm + pnpm-lock.yaml (lock 已钉 integrity/commit)
#   2. 本地插件: 由本目录产出 store path, package.json 用占位符, 激活时替换
#      -> 每个插件都有 rev/tree-hash, /etc/nixos 里不再出现 ~/WorkSpace
#
# 来源三分:
#   - 上游有仓:  fetchFromGitHub 钉 rev        (dsh-deepsec-shield/spear, dsh-super-injector)
#   - 上游无仓:  vendor 进 ./vendors/ (git 管)  (dsh-nxwatch, dsh-deepsec-guard)
#   - rev 取不到: vendor 进 ./vendors/ (git 管) (dsh-mode-boost @ b166041)
{ callPackage }:
{
  nxwatch = callPackage ./nxwatch.nix {};
  deepsec-guard = callPackage ./deepsec-guard.nix {};
  mode-boost = callPackage ./mode-boost.nix {};
  deepsec-shield = callPackage ./deepsec-shield.nix {};
  deepsec-spear = callPackage ./deepsec-spear.nix {};
  super-injector = callPackage ./super-injector.nix {};
}
