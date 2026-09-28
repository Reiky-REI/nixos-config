# 网易云音乐 CDN 防盗链绕过 API
# 依赖: ~/WorkSpace/netease-cdn-bypass/ (需要先 npm install)
# Cookie: ~/WorkSpace/netease-cdn-bypass/.env
{pkgs, ...}: let
  serviceDir = "${pkgs.home.homeDirectory}/WorkSpace/netease-cdn-bypass";
in {
  systemd.user.services.netease-cdn-bypass = {
    Unit = {
      Description = "Netease-CDN-Bypass";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = serviceDir;
      ExecStart = "${pkgs.nodejs_22}/bin/node ${serviceDir}/direct.js";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "NODE_ENV=production"
        "PORT=3002"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
