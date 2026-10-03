{
  config,
  lib,
  meow,
  pkgs,
  ...
}: let
  isAgentHost = builtins.any (role: builtins.elem role meow.roles) ["workstation" "devbox" "server"];

  # dsh profile 根目录 / 家目录 (用于展开 workspace yaml 里的 @HOME@ 占位符)
  profilesRoot = "${config.home.homeDirectory}/.dsh/profiles";

  # 每个 profile 的声明式清单 (package.json / pnpm-lock.yaml /
  # pnpm-workspace.yaml / cordis.patch.yml)。
  # 注意: pnpm-workspace.yaml 含机器相关路径 (store/cache/state 必须在可写区,
  # 因为 dsh-fence 以 ProtectHome=read-only 运行), 源码里写 @HOME@ 占位符,
  # 由 activate 时替换成实际家目录, 避免写死用户名。
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

  substHome = name: path: pkgs.writeText name (
    lib.replaceStrings ["@HOME@"] [config.home.homeDirectory] (builtins.readFile path)
  );

  syncProfile = p: ''
    target=${lib.escapeShellArg "${profilesRoot}/${p.name}"}
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (p.src + "/package.json")} "$target/package.json"
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (p.src + "/pnpm-lock.yaml")} "$target/pnpm-lock.yaml"
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (p.src + "/cordis.patch.yml")} "$target/cordis.patch.yml"
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg (substHome "pnpm-workspace-${p.name}.yaml" (p.src + "/pnpm-workspace.yaml"))} "$target/pnpm-workspace.yaml"
  '';
in {
  home.activation.syncDshProfiles = lib.mkIf isAgentHost (
    lib.hm.dag.entryAfter ["writeBoundary"] (lib.concatMapStrings syncProfile profiles)
  );
}
