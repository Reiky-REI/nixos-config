{
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./clash.nix
    ./tailscale.nix
  ];

  networking.networkmanager.enable =
    lib.mkIf (config.meow.enabled ? "networkmanager") true;
  networking.firewall.allowedTCPPorts = lib.mkIf (
    builtins.any (role: builtins.elem role config.meow.roles) ["workstation" "devbox"]
  ) [5900];

  # systemd-resolved: 本地 DNS 缓存 + 多上游 failover
  # 当路由器 DNS (192.168.1.1) 不可用时自动 fallback 到公共 DNS
  # 容器共享宿主 resolv.conf, 与 systemd-resolved 互斥, 故容器内不启用。
  services.resolved = lib.mkIf (config.meow.kind != "container") {
    enable = true;
    settings.Resolve.FallbackDNS = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  services.avahi = lib.mkIf (config.meow.enabled ? "networkmanager") {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # 系统级代理环境变量跟 clash 走 (clash 起在本机 7897)
  networking.proxy = lib.mkIf (config.meow.enabled ? "clash") {
    default = "http://127.0.0.1:7897";
    httpProxy = "http://127.0.0.1:7897";
    httpsProxy = "http://127.0.0.1:7897";
    # 国内镜像/常用域名绕过代理: 代理失效时 nix/pip 等仍可直连
    noProxy = "localhost,127.0.0.1,::1,*.local,100.64.0.0/10,*.ts.net,mirrors.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,mirror.sjtu.edu.cn,mirrors.aliyun.com";
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = lib.mkIf (!(builtins.elem "server" config.meow.roles)) "yes";
}
