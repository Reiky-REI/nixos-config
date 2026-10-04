# dsh-deepsec-shield — DeepSec Shield 代码安全审计工具 (dsh 插件)。
# 上游有仓: Unclecheng-li/DeepSec, rev fff031f (dsh-plugins/* 已入库且无本地改动)。
{
  callPackage,
  fetchFromGitHub,
}:
callPackage ./mk-js-bundle.nix {
  pname = "dsh-deepsec-shield";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "Unclecheng-li";
    repo = "DeepSec";
    rev = "fff031fc01fb36b95348214c8ee359f6ede8aa8b";
    hash = "sha256-z8TVWuLO03d3ZI4BK+kBBB8RfjJMR+0eagzU7DaYYVQ=";
  };
  subdir = "dsh-plugins/deepsec-shield";
  meta.description = "DeepSec Shield audit tools for dsh (upstream fff031f)";
}
