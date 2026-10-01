{
  config,
  lib,
  meow,
  kbCorpusProjects,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  isWorkstation = builtins.elem "workstation" meow.roles;
  kbCorpusPaths =
    [
      "/etc/nixos/.agents/AGENTS.md"
      "/etc/nixos/.agents/knowledge"
      "/etc/nixos/.agents/knowledge/decisions"
      "/etc/nixos/.agents/knowledge/retros"
      "/etc/nixos/.agents/SKILLS.md"
      "${home}/.agents/AGENTS.md"
      "${home}/.agents/knowledge"
      "${home}/.agents/knowledge/decisions"
      "${home}/.agents/knowledge/retros"
      "${home}/.agents/memory"
      "${home}/.agents/memory/auto"
      "${home}/.agents/memory/auto/feedback"
      "${home}/.agents/memory/auto/project"
      "${home}/.agents/memory/feedback"
      "${home}/.agents/MEMORY.md"
      "${home}/.agents/memory/project"
      "${home}/.agents/memory/reference"
      "${home}/.agents/memory/user"
      "${home}/.agents/SKILLS.md"
      "${home}/WorkSpace/.agents/AGENTS.md"
      "${home}/WorkSpace/.agents/knowledge"
      "${home}/WorkSpace/.agents/knowledge/retros"
    ]
    ++ lib.concatMap (project: let
      root = "${home}/WorkSpace/${project}/.agents";
    in [
      "${root}/AGENTS.md"
      "${root}/knowledge"
      "${root}/knowledge/retros"
    ])
    kbCorpusProjects;
in {
  systemd.user.services = lib.mkIf isWorkstation {
    kb-corpus = {
      Unit.Description = "Warm the KB index after corpus changes";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/.agents/tools/kb-mcp/warm-all.sh";
        Nice = 10;
        IOSchedulingClass = "idle";
      };
    };
  };

  systemd.user.paths.kb-corpus = lib.mkIf isWorkstation {
    Unit = {
      Description = "Watch agent knowledge sources for changes";
      TriggerLimitIntervalSec = "20s";
      TriggerLimitBurst = 5;
    };
    Path = {
      PathModified = kbCorpusPaths;
      Unit = "kb-corpus.service";
    };
    Install.WantedBy = ["default.target"];
  };

  home.activation.disableLegacyFailedUnits = lib.mkIf isWorkstation (lib.hm.dag.entryAfter ["reloadSystemd"] ''
    for unit in astrabot.service napcat.service napcat-watchdog.timer dsh-web.service hermes-gateway.service; do
      ${pkgs.systemd}/bin/systemctl --user disable --now "$unit" >/dev/null 2>&1 || true
    done
  '');
}
