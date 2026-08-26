{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./clash.nix
    ./tailscale.nix
  ];

  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    5900
  ];

  # systemd-resolved: 本地 DNS 缓存 + 多上游 failover
  # 当路由器 DNS (192.168.1.1) 不可用时自动 fallback 到公共 DNS
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  networking.proxy = {
    default = "http://127.0.0.1:7897";
    httpProxy = "http://127.0.0.1:7897";
    httpsProxy = "http://127.0.0.1:7897";
    noProxy = "localhost,127.0.0.1,::1,*.local,100.64.0.0/10,*.ts.net";
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
}
