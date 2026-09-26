{
  config,
  fullName,
  lib,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  networking.hostName = "NixMEOW";

  # ===== 双系统: Windows 分区 (只读) + 家目录入口 =====
  # 目标: 在 NixOS 家目录里直接访问 Windows 的 C:\Users\reiky
  #   -> ~/win  (= /mnt/windows/Users/reiky)
  # 只读的理由: 盘根有 hiberfil.sys; Windows 快速启动/休眠态下 rw 有损坏风险;
  #   且 modules/common 已记录过 nvme1 关机 I/O 超时问题。
  # automount + nofail: Windows 不存在/脏位时不会阻塞启动, 访问时才挂。
  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/B67E33C97E3380E3";
    fsType = "ntfs3";
    options = [
      "ro"
      "uid=${toString config.users.users.${username}.uid}"
      "gid=${toString config.users.groups.${config.users.users.${username}.group}.gid}"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.device-timeout=10s"
      "noatime"
    ];
  };

  systemd.tmpfiles.rules = [
    "L+ /home/${username}/win - - - - /mnt/windows/Users/reiky"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${username} = {
    description = "__${fullName}__";
    isNormalUser = true;
    # 固定 uid: users.<name>.uid 默认是 null (激活时才分配), 会让 NTFS 挂载的
    # `uid=` 选项拼成空值; 固定成当前实际值 1002 保证挂载选项可解析。
    uid = 1002;
    home = "/home/${username}";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    hashedPassword = "$y$j9T$RQ9/Mj/mI5O8AhOnB.3gJ/$mRmKCYV3q7zKoFF1asu5oZNfBNRE4uHDloKQM7Eq5G3";
    extraGroups = ["wheel" "networkmanager" "audio" "input" "video" "docker" "kvm" "libvirtd"];
  };

  system.stateVersion = "25.05";
}
