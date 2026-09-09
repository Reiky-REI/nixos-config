{
  config,
  pkgs,
  lib,
  ...
}: {
  # 容器: podman (无守护进程, 更轻量; CLI 兼容 docker)
  virtualisation.podman = {
    enable = true;
    # 提供 docker CLI 兼容别名 (docker → podman)
    dockerCompat = true;
    # 提供 docker.sock (兼容依赖 docker socket 的工具)
    dockerSocket.enable = true;
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu = {
    runAsRoot = false;
    swtpm.enable = true;
    vhostUserPackages = [
      pkgs.virtiofsd
    ];
  };
  programs.virt-manager.enable = true;
}
