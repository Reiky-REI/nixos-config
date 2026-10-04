# dsh-deepsec-spear — DeepSec Spear 授权渗透工具 (dsh 插件)。
# 上游有仓: Unclecheng-li/DeepSec, rev fff031f (与 shield 同 rev, 各自独立 derivation)。
{
  callPackage,
  fetchFromGitHub,
}:
callPackage ./mk-js-bundle.nix {
  pname = "dsh-deepsec-spear";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "Unclecheng-li";
    repo = "DeepSec";
    rev = "fff031fc01fb36b95348214c8ee359f6ede8aa8b";
    hash = "sha256-z8TVWuLO03d3ZI4BK+kBBB8RfjJMR+0eagzU7DaYYVQ=";
  };
  subdir = "dsh-plugins/deepsec-spear";
  meta.description = "DeepSec Spear pentest tools for dsh (upstream fff031f)";
}
