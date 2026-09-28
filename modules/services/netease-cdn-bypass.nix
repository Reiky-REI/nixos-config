# ===== 网易云音乐 CDN 防盗链绕过 API (NixOS systemd 模块) =====
#
# ExecStartPre 自动完成 npm install 与路径修复, Cookie 由工作区私有 .env 提供喵~
# 使用: services.netease-cdn-bypass.enable = true;
{
  config,
  lib,
  pkgs,
  primaryUser,
  username,
  ...
}: let
  cfg = config.services.netease-cdn-bypass;
  serviceDir = "${primaryUser.homeDirectory}/WorkSpace/netease-cdn-bypass";
in {
  options.services.netease-cdn-bypass = {
    enable = lib.mkEnableOption "Netease-CDN-Bypass music API service";
  };

  config = lib.mkIf cfg.enable {
    systemd.services.netease-cdn-bypass = {
      description = "Netease-CDN-Bypass - 网易云音乐 CDN 防盗链绕过 API";
      after = ["network.target"];
      wants = ["network.target"];
      wantedBy = ["multi-user.target"];

      path = [pkgs.nodejs_22 pkgs.git pkgs.coreutils pkgs.gnused pkgs.bash];

      serviceConfig = {
        User = username;
        Group = "users";
        WorkingDirectory = serviceDir;

        ExecStartPre = [
          "${pkgs.bash}/bin/bash -c 'cd ${serviceDir} && ${pkgs.nodejs_22}/bin/npm install --omit=dev'"
          "${pkgs.bash}/bin/bash -c '${pkgs.gnused}/bin/sed -i \"s|/opt/meting/.env|${serviceDir}/.env|g\" ${serviceDir}/direct.js'"
        ];

        ExecStart = "${pkgs.nodejs_22}/bin/node ${serviceDir}/direct.js";

        Restart = "on-failure";
        RestartSec = "5s";

        Environment = [
          "NODE_ENV=production"
          "PORT=3002"
          "HTTP_PROXY=http://127.0.0.1:7897"
          "HTTPS_PROXY=http://127.0.0.1:7897"
          "NO_PROXY=localhost,127.0.0.1,::1"
        ];
      };
    };
  };
}
