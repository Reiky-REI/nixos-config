# dsh-deepsec-guard — DSH 动作前接缝的统一 DeepSec 守卫插件。
# 无上游仓库 (手写产物), 依用户 2026-10-04 决策 vendor 进本配置仓。
#
# 插件源码 import 了 `@deepseek-ai/schemastery` (lib/index.js 第 30 行), 但
# package.json 没声明该依赖。Node 从插件 store path 向上解析时找不到它 ->
# dsh 启动报 `dsh-deepsec-guard (dsh-deepsec-guard): failed to import`, 守卫
# 静默失效 (fail-open, 不拦任何工具调用)。这里把宿主 dsh 自带的那份软链进
# $out/node_modules, 版本随 dsh 升级自动跟随 (0.2.2-rc.3 = 3.19.0)。
{ callPackage, pkgs }:
callPackage ./mk-js-bundle.nix {
  pname = "dsh-deepsec-guard";
  version = "0.1.0";
  src = ./vendors/dsh-deepsec-guard;
  extraNodeModules = {
    "@deepseek-ai/schemastery" = "${pkgs.dsh}/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/schemastery";
  };
  meta.description = "dsh-deepsec-guard — DeepSec pre-action guard plugin for dsh";
}
