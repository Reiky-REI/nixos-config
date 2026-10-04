{
  config,
  lib,
  meow,
  pkgs,
  ...
}: let
  isAgentHost = builtins.any (role: builtins.elem role meow.roles) ["workstation" "devbox" "server"];

  # dsh profile 根目录 / 家目录 (用于展开 workspace yaml 与 lock 里的占位符)
  profilesRoot = "${config.home.homeDirectory}/.dsh/profiles";

  # 本地插件 (nix-pure 化): 由 /etc/nixos/pkgs/dsh-plugins 产出 store path。
  # 每个插件的来源与复现性见 pkgs/dsh-plugins/{default,vendors}.nix 的注释。
  dshPlugins = pkgs.callPackage ../../../pkgs/dsh-plugins {};

  # pnpm 在 lock 里会把绝对路径规范化成「相对 profile 目录」的路径, 因此同一
  # store path 需要两个占位符:
  #   @DSH_X@     -> 绝对路径 /nix/store/...
  #   @DSH_X_REL@ -> 相对路径 ../../../../../nix/store/...
  # 相对前缀 = 从 <profilesRoot>/<profile> 回到 / 的 ../ 串。
  relUp = path: let
    parts = lib.filter (s: s != "") (lib.splitString "/" path);
  in
    lib.concatStringsSep "/" (lib.replicate (lib.length parts) "..");

  pluginPlaceholders = profile: let
    rel = path: "${relUp "${profilesRoot}/${profile.name}"}${path}";
  in {
    "@DSH_MODE_BOOST@" = "${dshPlugins.mode-boost}";
    "@DSH_MODE_BOOST_REL@" = rel "${dshPlugins.mode-boost}";
    "@DSH_SUPER_INJECTOR@" = "${dshPlugins.super-injector}";
    "@DSH_SUPER_INJECTOR_REL@" = rel "${dshPlugins.super-injector}";
    "@DSH_NXWATCH@" = "${dshPlugins.nxwatch}";
    "@DSH_NXWATCH_REL@" = rel "${dshPlugins.nxwatch}";
    "@DSH_DEEPSEC_GUARD@" = "${dshPlugins.deepsec-guard}";
    "@DSH_DEEPSEC_GUARD_REL@" = rel "${dshPlugins.deepsec-guard}";
    "@DSH_DEEPSEC_SHIELD@" = "${dshPlugins.deepsec-shield}";
    "@DSH_DEEPSEC_SHIELD_REL@" = rel "${dshPlugins.deepsec-shield}";
    "@DSH_DEEPSEC_SPEAR@" = "${dshPlugins.deepsec-spear}";
    "@DSH_DEEPSEC_SPEAR_REL@" = rel "${dshPlugins.deepsec-spear}";
  };

  # 每个 profile 的声明式清单 (package.json / pnpm-lock.yaml /
  # pnpm-workspace.yaml / cordis.patch.yml)。
  # 注意: 本地插件依赖写成 link:@DSH_*@ 占位符 (见 pkgs/dsh-plugins/), workspace
  # yaml 含机器相关路径 (store/cache/state 必须在可写区, 因为 dsh-fence 以
  # ProtectHome=read-only 运行), 源码里写占位符, 由 activate 时替换, 避免写死
  # 用户名与 /nix/store hash。
  profiles = [
    {
      name = "web";
      src = ./dsh-profile;
    }
    {
      name = "dsh-tui";
      src = ./dsh-profile-tui;
    }
  ];

  # 占位符 -> 实际值的 map (@HOME@ 与各插件 store path)
  substMap = profile:
    {
      "@HOME@" = config.home.homeDirectory;
    }
    // pluginPlaceholders profile;

  subst = profile: name: path: pkgs.writeText name (
    lib.replaceStrings
    (lib.attrNames (substMap profile))
    (lib.attrValues (substMap profile))
    (builtins.readFile path)
  );

  syncProfile = p: ''
    target=${lib.escapeShellArg "${profilesRoot}/${p.name}"}
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (subst p "dsh-profile-${p.name}-package.json" (p.src + "/package.json"))} "$target/package.json"
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (subst p "dsh-profile-${p.name}-pnpm-lock.yaml" (p.src + "/pnpm-lock.yaml"))} "$target/pnpm-lock.yaml"
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (p.src + "/cordis.patch.yml")} "$target/cordis.patch.yml"
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (subst p "dsh-profile-${p.name}-pnpm-workspace.yaml" (p.src + "/pnpm-workspace.yaml"))} "$target/pnpm-workspace.yaml"
  '';
in {
  home.activation.syncDshProfiles = lib.mkIf isAgentHost (
    lib.hm.dag.entryAfter ["writeBoundary"] (lib.concatMapStrings syncProfile profiles)
  );
}
