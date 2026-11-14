# 形态①: 源码已自带构建产物 (lib/) 的纯 JS dsh 插件。
#
# Nix 侧只负责「钉住来源 + 原样拷进 store」, 不做任何构建 —— 因为上游仓库里
# 已经提交了可运行的 lib/。来源有两种:
#   - 上游有仓: src = fetchFromGitHub { rev = <40 位 commit>; hash = ...; }
#   - 上游无仓 / 上游取不到该 rev: src = ./vendors/<name> (由本配置仓 git 管版本)
#
# 复现性判据: store path 的输入哈希覆盖全部 vendor 文件 + fetchFromGitHub 的
# tree hash, 所以「换机器/目录被改」都不会再影响 profile 安装结果。
{
  lib,
  stdenv,
  pname,
  version,
  src,
  # 上游 monorepo 中的子目录 (例如 dsh-plugins/deepsec-shield); 空 = src 根
  subdir ? "",
  # 插件 store path 之外还需要能被 Node 解析到的运行时依赖。
  # 键是 node_modules 下的包名, 值是 store path。用于「源码 import 了某个宿主自带的
  # @deepseek-ai/* 包, 但插件自身的 package.json 没声明」的场景 —— Node 从 realpath
  # (store path) 向上解析, profile 里 hoist 的副本救不了它, 只能放进 $out/node_modules。
  extraNodeModules ? {},
  meta ? {},
}:
stdenv.mkDerivation {
  inherit pname version;
  src = if subdir == "" then src else "${src}/${subdir}";

  # 纯 JS: 不 unpack (src 本身就是目录)、不构建、不需要 fixup (无 ELF/脚本 patch)
  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a "$src"/. "$out"/
    # cp -a 会连源目录的只读权限一起复制; 下面的 node_modules 软链需要写权限
    chmod -R u+w "$out"
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: target: ''
        mkdir -p "$out/node_modules/$(dirname ${lib.escapeShellArg name})"
        ln -s ${lib.escapeShellArg "${target}"} "$out/node_modules/${name}"
      '')
      extraNodeModules)}
    runHook postInstall
  '';

  meta =
    {
      description = "DeepSeek Harness (dsh) profile plugin, prebuilt JS bundle";
      platforms = lib.platforms.all;
    }
    // meta;
}
