{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./clash.nix
  ];
  # networking
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    5900
  ];

  # Configure network proxy if necessary
  # 系统级代理设置
  networking.proxy = {
    default = "http://127.0.0.1:7897";
    httpProxy = "http://127.0.0.1:7897";
    httpsProxy = "http://127.0.0.1:7897";
    noProxy = "localhost,127.0.0.1,::1,*.local";
  };
}
