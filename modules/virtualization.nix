{pkgs, pkgs-unstable, ...}: {
  # docker
  virtualisation.docker.enable = true;

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu = {
    runAsRoot = false;
    swtpm.enable = true;
    vhostUserPackages = [
      pkgs.virtiofsd
    ];
  };
  programs.virt-manager.enable = true;

  # waydroid — 使用 nftables 版绕过 kernel 7.0.9 缺少 ip_tables 模块的问题
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs-unstable.waydroid-nftables;

  environment.systemPackages = with pkgs; [
    waydroid-helper
  ];
}
