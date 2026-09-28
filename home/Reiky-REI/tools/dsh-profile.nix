{
  config,
  lib,
  meow,
  pkgs,
  ...
}: let
  isAgentHost = builtins.any (role: builtins.elem role meow.roles) ["workstation" "devbox" "server"];
  profileDir = "${config.home.homeDirectory}/.dsh/profiles/web";
in {
  home.activation.syncDshProfile = lib.mkIf isAgentHost (lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg ./dsh-profile/package.json} ${lib.escapeShellArg "${profileDir}/package.json"}
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg ./dsh-profile/pnpm-lock.yaml} ${lib.escapeShellArg "${profileDir}/pnpm-lock.yaml"}
    ${pkgs.coreutils}/bin/install -D -m 0644 ${lib.escapeShellArg ./dsh-profile/cordis.patch.yml} ${lib.escapeShellArg "${profileDir}/cordis.patch.yml"}
  '');
}
