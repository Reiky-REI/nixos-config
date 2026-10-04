# @dsh-external/dsh-mode-boost — 任务感知思维模式路由插件。
#
# 需要的 rev 是 b166041 ("declare dsh.bundle manifest so web profile boots"),
# 它虽然在上游 main a9a666a 之上, 但没有 push 到任何 ref (git clone --bare 核实),
# 上游 main 的 package.json 也没有 dsh.bundle 字段 -> fetchFromGitHub 会静默拿到
# 一个不被 dsh 当 bundle 注册的版本。故依用户 2026-10-04 决策 vendor 进配置仓。
{ callPackage }:
callPackage ./mk-js-bundle.nix {
  pname = "dsh-mode-boost";
  version = "0.1.0";
  src = ./vendors/mode-boost;
  meta.description = "@dsh-external/dsh-mode-boost (rev b166041, vendored)";
}
