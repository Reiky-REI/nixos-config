# @dsh-external/dsh-super-injector — 运行时插件注入器 (dsh 插件)。
#
# 上游是 TS 源码包, injector/lib/ 被 .gitignore 排除 (未入库), 必须现场构建。
# 用 nixpkgs buildNpmPackage:
#   - sourceRoot 指到 monorepo 的 injector/ 子目录 (buildNpmPackage 没有 npmRoot)
#   - npmBuildScript = build:client (即 tsdown, 按 tsdown.config.ts 同时产出
#     lib/index.js + lib/client.js); 不用 scripts/build.sh (它需要 DSH_CHECKOUT)
#
# ⚠ 上游 package-lock.json 不完整: 75 个包里 36 个缺 "resolved" URL
#   (已知 npm/cli#6301), 离线 `npm ci` 会 ENOTCACHED (yuku-parser 等)。
#   故把本机 `npm install --package-lock-only` 重建的完整 lock pin 进本仓
#   (super-injector/package-lock.json), 在 postFetch 里覆盖上游那份;
#   这样 npmDeps fetcher 与 build 用的是同一份完整 lock。
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "dsh-super-injector";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "yjh051108";
    repo = "dsh-routing-suite";
    rev = "195273352f23bff7f9023ebe2ec0cdbdf9c98f10";
    hash = "sha256-g1++2Eeo+eDW2AB5amtBzKlDecN5p23XPZ6FOV4BHoM=";
    postFetch = ''
      chmod -R u+w "$out/injector"
      cp ${./super-injector/package-lock.json} "$out/injector/package-lock.json"
    '';
  };

  sourceRoot = "source/injector";

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-cSkXxNP0zvX7s6ktRNJUQ0QiBFeYmYGvUiySk8OZHFo=";
  npmFlags = ["--legacy-peer-deps"];
  npmBuildScript = "build:client";

  # 只保留 dsh 运行需要的产物 (package.json 的 files 字段同款)
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a package.json cordis.patch.yml lib "$out"/
    runHook postInstall
  '';

  meta = {
    description = "@dsh-external/dsh-super-injector (upstream 1952733, built from TS)";
    platforms = lib.platforms.all;
  };
}
