# ===== NixMEOW-CTR — Docker systemd 容器镜像 =====
# 定位: 把同一套用户态工具环境打包成容器, 在别处以 docker/podman 运行。
# 无图形、无本机硬件事实、无 boot loader; 共享宿主内核。
#
# 镜像来自 nixpkgs 的 `virtualisation/docker-image.nix` 模块 (非已弃用的
# nixos-generators flake)。该 profile 提供 `system.build.tarball`, 采用
# systemd 作为 PID 1, 因此运行时需要容器特权, 详见 docs/NixMEOW-CTR.md。
#
# 构建: nix build .#packages.x86_64-linux.NixMEOW-CTR-docker
{
  config,
  lib,
  modulesPath,
  pkgs,
  username,
  primaryUser,
  ...
}: {
  imports = [
    ../../modules
    (modulesPath + "/virtualisation/docker-image.nix")
  ];

  networking.hostName = "NixMEOW-CTR";

  # 镜像不是一个可引导机器: 显式关掉任何 boot loader。
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # 不把 nixpkgs channel 副本塞进镜像, 控制体积。
  system.installer.channel.enable = false;

  services.journald.console = "/dev/console";

  users.users.${username} = {
    description = primaryUser.fullName;
    isNormalUser = true;
    # server 角色不启用 programs.zsh, 这里用系统自带的交互 bash。
    shell = pkgs.bashInteractive;
    ignoreShellProgramCheck = true;
    extraGroups = ["wheel"];
  };

  system.stateVersion = "26.05";
}
