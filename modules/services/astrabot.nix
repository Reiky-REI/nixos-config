# ===== AstrBot 开机自启服务 (NixOS systemd module) =====
#
# 通过 systemd 托管 AstrBot (端口 6185)。
# DSH web (端口 3080) 已由 dsh-fence.nix 单独托管, 无需重复配置。
#
# 使用方法:
#   1. 将此文件复制到 /etc/nixos/modules/services/astrabot.nix
#   2. 在 /etc/nixos/modules/services/default.nix 的 imports 中添加 ./astrabot.nix
#   3. 在 /etc/nixos/modules/services/default.nix 中添加:
#      services.astrabot.enable = true;
#   4. 执行: nixos-rebuild switch --flake /etc/nixos#NixMEOW
#   5. 手动启动过程中请先停掉: ./astrabot.sh stop
#
# 注意:
#   - venv 里的 greenlet 需要 libstdc++.so.6, 通过 stdenv gcc lib 提供
#   - 使用 --expose-internals 不需要, 这里只跑 astrbot
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.astrabot;
  astraDir = "/home/${username}/WorkSpace/astrabot";
  venv = "${astraDir}/.venv";
  logFile = "${astraDir}/astrbot.log";
  libstdcppPath = pkgs.lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib];
in {
  options.services.astrabot = {
    enable = lib.mkEnableOption "AstrBot chat bot service";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.astrabot = {
      description = "AstrBot chat bot";
      after = ["network.target" "dsh-fence.service"];
      wants = ["network.target"];
      wantedBy = ["multi-user.target"];

      path = ["/run/current-system/sw"];

      serviceConfig = {
        User = username;
        Group = "users";
        WorkingDirectory = astraDir;
        ExecStart = "${venv}/bin/astrbot run";
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "append:${logFile}";
        StandardError = "append:${logFile}";
        # greenlet 需要 libstdc++, 通过 stdenv gcc lib 提供
        Environment = "LD_LIBRARY_PATH=${libstdcppPath}";
      };
    };
  };
}
