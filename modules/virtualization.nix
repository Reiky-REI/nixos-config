{pkgs, ...}: {
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

  # waydroid
  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    waydroid-helper
    nftables
  ];

  boot.kernelModules = [ "nf_tables" ];
}
