# ===== 网易云音乐 CDN 防盗链绕过 API (NixOS systemd 模块) =====
#
# ExecStartPre 自动完成 npm install + cookie 配置 + 路径修复。
# 使用: services.netease-cdn-bypass.enable = true;
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.netease-cdn-bypass;
  serviceDir = "/home/${username}/WorkSpace/netease-cdn-bypass";
  cookie = "MUSIC_U=005F2710D9DDB180BDE3A65CC3626930FD9E87556E952642359DD4ACEB006CE1F72DB65E3F11D018FBD520C0CF9FD583D23E93E0319DBDE33B55EEA4270F8AE57C3FE75656B0DA28A59A281D9B777C64EC5164E17C03A7FF461BC4CE8C8B4EA85B70BDE3B07B43EF0E98052A452F519C41B8278C882B594FF459B49B4110E8EABF3873E7B09459452CD2DAF0D223081C2A4C4ED987E59FB1051F11C5DAB7649B9ACBB37226CAB6FD4497A8B0A0AA7ACCC6553B9FF8CCB3FAB5AA372E6D9EC559A7AE1E3EDDE4A4C7F4E7421E0B2B69DAC1981EF1A3F430B26FCADC479C34AB5599FB7428896D314D1FD568E71A859E172E2BDEC648E64E0689459922490677D273244BDEFE65B5128133ECDD7D1AE194A4F5319AE880EBB04D4BF5AA7F4C980CE0850C35FC493963E11BF67A512BBAEE7B391B0087C30B841F27B2E2F031F45BDD6679D27FBAED84614963933511A0D0B4694DE8D5B802219DEEEABEF566970AF86B28808368A6093E49EF0CD7D4E1524DA0217DD4245AB0E2E1168EE5F3CA23F218D4B674C234208E2574242D79F1917C; __csrf=; __remember_me=true";
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
          "${pkgs.bash}/bin/bash -c 'echo \"NETEASE_COOKIE=${cookie}\" > ${serviceDir}/.env'"
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
