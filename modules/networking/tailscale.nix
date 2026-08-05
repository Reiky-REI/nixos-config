{
  lib,
  pkgs,
  ...
}: {
  services.tailscale.enable = true;

  # Tailscale WireGuard 直连端口 (NAT 穿透)
  networking.firewall.allowedUDPPorts = [41641];

  # 持久化 Tailscale 状态: 首次手动 sudo tailscale up 后重启自动重连
  # --timeout=5s 防止未认证时无限阻塞 systemd (注意: 必须带单位, 否则 parse error)
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    serviceConfig.Restart = "on-failure";
    script = let
      tailscale = "${pkgs.tailscale}/bin/tailscale";
    in ''
      sleep 2
      ${tailscale} status > /dev/null 2>&1 && exit 0
      ${tailscale} up --accept-routes --accept-dns --timeout=5s
    '';
  };
}
