{
  config,
  pkgs,
  lib,
  ...
}: let
  # 内核 7.1.5 已移除 legacy iptables 模组 (ip_tables), 而 waydroid-net.sh
  # 硬编码 LXC_USE_NFT="false" 优先走 legacy 分支; patch 改为 env 优先、
  # 默认 nft (运行环境可 LXC_USE_NFT=false 切回 legacy); PATH 补 nftables
  # 等工具 (net.sh 的 ELF wrapper 只在继承 PATH 上前置自有目录)。喵~
  waydroidNetNft = pkgs.waydroid.overrideAttrs (o: {
    postPatch = (o.postPatch or "") + ''
      substituteInPlace data/scripts/waydroid-net.sh \
        --replace-fail 'LXC_USE_NFT="false"' 'LXC_USE_NFT="''${LXC_USE_NFT:-true}"'
    '';
  });
in {
  # 容器: podman (无守护进程, 更轻量; CLI 兼容 docker)
  virtualisation.podman = lib.mkIf (config.meow.enabled ? "podman") {
    enable = true;
    # 提供 docker CLI 兼容别名 (docker → podman)
    dockerCompat = true;
    # 提供 docker.sock (兼容依赖 docker socket 的工具)
    dockerSocket.enable = true;
  };

  virtualisation.libvirtd = lib.mkIf (config.meow.enabled ? "libvirt") {
    enable = true;
    qemu = {
      runAsRoot = false;
      swtpm.enable = true;
      vhostUserPackages = [
        pkgs.virtiofsd
      ];
    };
  };
  programs.virt-manager.enable = lib.mkIf (config.meow.enabled ? "libvirt") true;

  # Android 容器: waydroid
  # 用途: 豆包爱学 (com.aitutor.hippo) 协议逆向 — app 在容器内挂机充当协议端,
  # 宿主跑 mitmproxy 观察流量 + Frida hook 签名/请求函数 (2026-10-07 计划)。
  # binder 走内核内建 binderfs (7.1.5 CONFIG_ANDROID_BINDERFS=y), 无需外挂模组。
  # app 的 arm native so (libsscronet/libmetasec_ov) 需要容器内装 ARM 转译 (libhoudini)。
  virtualisation.waydroid = lib.mkIf (config.meow.enabled ? "waydroid") {
    enable = true;
    package = waydroidNetNft;
  };

  systemd.services.waydroid-container.serviceConfig.Environment = with pkgs; [
    "PATH=${lib.makeBinPath [ iptables nftables kmod dnsmasq iproute2 ]}:/run/wrappers/bin:/run/current-system/sw/bin"
  ];
}
