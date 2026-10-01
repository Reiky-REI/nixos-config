{
  agentConfig,
  config,
  lib,
  pkgs,
  ...
}: let
  settingsTemplate = builtins.fromJSON (builtins.readFile ./opencode-settings.json);
  replaceHome = value:
    if builtins.isAttrs value
    then lib.mapAttrs (_: replaceHome) value
    else if builtins.isList value
    then map replaceHome value
    else if builtins.isString value
    then lib.replaceStrings ["@HOME@"] [config.home.homeDirectory] value
    else value;
  opencodeSettings = lib.recursiveUpdate (replaceHome settingsTemplate) {
    default_agent = agentConfig.opencode.defaultAgent;
    agents.plan.model = agentConfig.opencode.model;
    agents.plan.system = agentConfig.opencode.planSystem;
  };
  opencodeSettingsFile = pkgs.writeText "opencode.jsonc" (builtins.toJSON opencodeSettings);

  # opencode v2 数据库清理脚本 (声明式部署, 见 opencode-gc.py)
  opencodeGc = pkgs.writeScript "opencode-gc" (builtins.readFile ./opencode-gc.py);

  # Deferred restart runs outside Home Manager activation so it cannot deadlock switch.
  opencodePluginDeferredRestart = pkgs.writeShellScript "opencode-plugin-deferred-restart" ''
    set -eu
    while ${pkgs.systemd}/bin/systemctl --system is-active --quiet nixos-rebuild-switch-to-configuration.service; do
      ${pkgs.coreutils}/bin/sleep 1
    done
    ${pkgs.coreutils}/bin/sleep 2
    if ! ${pkgs.procps}/bin/pgrep -f '[o]pencode serve --service' >/dev/null; then
      exit 0
    fi
    exec ${pkgs.opencode-v2}/bin/opencode service restart
  '';

  # The path unit can trigger during HM activation; only enqueue the detached job here.
  opencodePluginRestart = pkgs.writeShellScript "opencode-plugin-restart" ''
    set -eu
    if ! ${pkgs.procps}/bin/pgrep -f '[o]pencode serve --service' >/dev/null; then
      exit 0
    fi
    exec ${pkgs.systemd}/bin/systemd-run --user \
      --unit="opencode-plugin-restart-deferred-$$" \
      --collect \
      "${opencodePluginDeferredRestart}"
  '';
in {
  home.file.".config/opencode/opencode.jsonc".source = opencodeSettingsFile;
  home.file.".config/opencode/cli.json".source = ./opencode-cli.json;

  # 全局 edit 前自动快照插件; 放在 .opencode/plugins 外, 避免项目级与全局重复加载。
  home.file.".config/opencode/plugins/edit-backup.js".source = ./opencode-edit-backup.js;

  # 插件源码或 HM 生成的全局插件软链变化时, 自动重启 OpenCode V2 服务清除 Bun 模块缓存。
  # 目录监视用于捕获 HM 原子替换软链; 文件监视用于捕获源码原地修改。
  systemd.user.services.opencode-plugin-restart = {
    Unit.Description = "Restart OpenCode V2 after plugin source changes";
    Service = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
      ExecStart = "${opencodePluginRestart}";
    };
  };

  systemd.user.paths.opencode-plugin-restart = {
    Unit.Description = "Watch OpenCode settings and plugin files for changes";
    Path = {
      PathChanged = [
        "${config.home.homeDirectory}/.config/opencode/plugins"
        "${config.home.homeDirectory}/.config/opencode/opencode.jsonc"
      ];
      Unit = "opencode-plugin-restart.service";
    };
    Install.WantedBy = ["default.target"];
  };

  # opencode 数据库清理脚本 (替换历史遗留的手工真实文件, 故 force)
  home.file.".local/bin/opencode-gc" = {
    source = opencodeGc;
    executable = true;
    force = true;
  };

  # opencode 数据库清理定时器
  systemd.user.services.opencode-gc = {
    Unit = {
      Description = "opencode 数据库清理";
      After = "network.target";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${opencodeGc}";
    };
  };

  systemd.user.timers.opencode-gc = {
    Unit = {
      Description = "opencode 数据库清理定时器";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
}
