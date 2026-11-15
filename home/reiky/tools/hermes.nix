{
  config,
  inputs,
  lib,
  meow,
  pkgs,
  system,
  ...
}: let
  isWorkstation = builtins.elem "workstation" meow.roles;

  # 上游模块自己解析出最终包 (programs.hermes-agent.package 默认跟随
  # services.hermes-agent.package), gateway unit 复用同一个包, 不重复构建
  hermes = config.programs.hermes-agent.package;

  # 上次安装 (2026-09-09) 留下的状态目录, 含 config.yaml / skills / state.db
  hermesHome = "${config.home.homeDirectory}/.hermes";
in {
  # Nous Research Hermes Agent — 声明式安装 CLI, gateway 单独常驻
  #
  # 不装 Desktop (Electron): 用户 2026-11-15 明确"不要 GUI 也行", 且
  # hermes-agent-pnpm-deps 构建要额外几个 GB, 本机磁盘吃紧喵~
  #
  # 只启用 programs.* (装包 + PATH), 不启用 services.hermes-agent:
  # 后者会在 $HERMES_HOME 写 .managed 标记并导出 HERMES_MANAGED, 让
  # `hermes setup` / `hermes model` 拒绝写配置 (要求改 nix 再 rebuild)喵~
  # 这里的 unit 与上游 services.hermes-agent.gateway.enable 生成的等价,
  # 只是不带 managed 标记, 因此运行时仍可自由换 provider 和模型喵~
  imports = [inputs.hermes-agent.homeManagerModules.default];

  programs.hermes-agent.enable = true;

  # Web 面板 (config / API keys / sessions 管理) 喵~
  # nix 包里已带预构建 dist (share/hermes-agent/web_dist), 所以 --skip-build 喵~
  systemd.user.services.hermes-dashboard = lib.mkIf (isWorkstation && system == "x86_64-linux") {
    Unit = {
      Description = "Hermes Agent Web Dashboard";
      After = ["default.target"];
    };
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "simple";
      ExecStart = "${hermes}/bin/hermes dashboard --no-open --skip-build --host 127.0.0.1 --port 9119";
      WorkingDirectory = config.home.homeDirectory;
      Environment = [
        "HERMES_HOME=${hermesHome}"
        "PATH=${lib.makeBinPath [hermes pkgs.bash pkgs.coreutils pkgs.git]}"
      ];
      Restart = "always";
      RestartSec = 5;
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.user.services.hermes-agent = lib.mkIf (isWorkstation && system == "x86_64-linux") {
    Unit = {
      Description = "Hermes Agent Gateway";
      # 用户级 unit 不要 order 到 network-online.target (系统级目标, 无效)
      After = ["default.target"];
    };
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "simple";
      # `hermes gateway` 默认子命令即 run
      ExecStart = "${hermes}/bin/hermes gateway";
      WorkingDirectory = config.home.homeDirectory;
      Environment = [
        "HERMES_HOME=${hermesHome}"
        "PATH=${lib.makeBinPath [hermes pkgs.bash pkgs.coreutils pkgs.git]}"
      ];
      Restart = "always";
      RestartSec = 5;
      # 状态目录单人所有, 不共享给同组
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}
