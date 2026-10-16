{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.meow.enabled ? "tailscale") {
    services.tailscale.enable = true;

    # Tailscale WireGuard 直连端口 (NAT 穿透)
    networking.firewall.allowedUDPPorts = [41641];

    # 持久化 Tailscale 状态: 首次手动 sudo tailscale up 后重启自动重连
    # --timeout=5s 防止未认证时无限阻塞 systemd (注意: 必须带单位, 否则 parse error)
    # --ssh: 启用 Tailscale SSH (RunSSH), 供其他 tailnet 设备免密钥 ssh 进本机
    #        (ACL 默认 check 模式, 首次连接需浏览器确认); 该 flag 实际存于
    #        tailscaled state, 这里显式声明以防 state 重置后丢失
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
        ${tailscale} up --accept-routes --accept-dns --ssh --timeout=5s
      '';
    };
  };
}
