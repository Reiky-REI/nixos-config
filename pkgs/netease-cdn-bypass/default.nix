# ===== Netease-CDN-Bypass: 网易云音乐 CDN 防盗链绕过 API =====
#
# buildNpmPackage: npm install 在 Nix sandbox 内完成, 依赖完全隔离
# 运行: ${pkgs.netease-cdn-bypass}/bin/netease-cdn-bypass
# 配置: 通过环境变量 NETEASE_COOKIE 或 .env 文件
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "netease-cdn-bypass";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "BB0813";
    repo = "Netease-CDN-Bypass";
    rev = "main";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # nix-build 时自动替换
  };

  npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # nix-build 时自动替换

  # 跳过默认的 npmBuildHook, 我们只需要 node_modules
  npmBuildHook = "true";

  # 自定义安装: 复制源码 + 创建启动脚本
  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/$pname
    cp -r . $out/lib/node_modules/$pname/

    mkdir -p $out/bin
    cat > $out/bin/$pname << WRAPPER
#!${nodejs_22}/bin/node
const path = require('path');
const modulePath = path.join(path.dirname(process.argv[1]), '..', 'lib', 'node_modules', '${pname}', 'direct.js');
require(modulePath);
WRAPPER
    chmod +x $out/bin/$pname

    runHook postInstall
  '';

  meta = with lib; {
    description = "Netease-CDN-Bypass - 网易云音乐 CDN 防盗链绕过 API";
    homepage = "https://github.com/BB0813/Netease-CDN-Bypass";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = pname;
  };
}
