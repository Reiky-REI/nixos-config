# nxwatch — 「NixOS 守夜人」dsh 驾驶舱插件。
# 无上游仓库 (手写产物), 依用户 2026-10-04 决策 vendor 进本配置仓。
{ callPackage }:
callPackage ./mk-js-bundle.nix {
  pname = "dsh-nxwatch";
  version = "0.1.0";
  src = ./vendors/nxwatch;
  meta.description = "nxwatch — NixOS guard cockpit for dsh web profile";
}
