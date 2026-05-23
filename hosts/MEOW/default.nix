{
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules
  ];

  environment.systemPackages = with pkgs; [
    wineWow64Packages.stable
    winetricks
    google-chrome
    pulseaudio
    pciutils # lspci
    ffmpeg
    libva
    libva-utils
    power-profiles-daemon
    vim
    git
    curl
    wget
    bluez
    cachix
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    TERMINAL = "kitty";
    # GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    QT5_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "/var/lib/flatpak/exports/share"
    "$HOME/.local/share/flatpak/exports/share"
  ];

  programs.steam.enable = true;
  programs.steam.fontPackages = with pkgs; [source-han-sans];
  programs.zsh.enable = true;
  users.users.Reiky-REI = {
    description = "__Reiky__";
    isNormalUser = true;
    home = "/home/Reiky-REI";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    hashedPassword = "$y$j9T$RQ9/Mj/mI5O8AhOnB.3gJ/$mRmKCYV3q7zKoFF1asu5oZNfBNRE4uHDloKQM7Eq5G3";
    extraGroups = ["wheel" "networkmanager" "audio" "input" "video" "docker" "kvm" "libvirtd"];
  };
  security.sudo.wheelNeedsPassword = false; # sudo组是否需要密码

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Low-power CPUs use the kernel parameters below to avoid crashes
  boot.kernelParams = ["ahci.mobile_lpm_policy=1"];

  # Use the latestist kernal
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # host name
  networking.hostName = "NixMEOW";

  # 禁用所有形式的睡眠和休眠
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes         # 如果只想禁用休眠，可以保持 Suspend 启用
    AllowHibernation=no      # 禁用休眠 (Hibernate)
    AllowHybridSleep=yes# 禁用混合睡眠 (Hybrid Sleep)
    AllowSuspendThenHibernate=yes# 禁用先睡眠后休眠
  '';

  hardware = {
    enableAllFirmware = true; # 自动安装所有固件
    cpu.intel.updateMicrocode = true; # Intel CPU
    # cpu.amd.updateMicrocode = true; # AMD CPU
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };
  system.stateVersion = "25.05";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
