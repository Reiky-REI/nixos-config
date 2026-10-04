# dsh-deepsec-guard — DSH 动作前接缝的统一 DeepSec 守卫插件。
# 无上游仓库 (手写产物), 依用户 2026-10-04 决策 vendor 进本配置仓。
{ callPackage }:
callPackage ./mk-js-bundle.nix {
  pname = "dsh-deepsec-guard";
  version = "0.1.0";
  src = ./vendors/dsh-deepsec-guard;
  meta.description = "dsh-deepsec-guard — DeepSec pre-action guard plugin for dsh";
}
