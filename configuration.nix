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

  nix.settings.trusted-users = ["root" "Reiky-REI"];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

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

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.timesyncd.enable = true;

  # U盘自动加载
  services.udisks2.enable = true;

  # networking
  networking.hostName = "cook";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    5900
  ];

  # Configure network proxy if necessary
  # 系统级代理设置
  networking.proxy = {
    default = "http://127.0.0.1:7897";
    httpProxy = "http://127.0.0.1:7897";
    httpsProxy = "http://127.0.0.1:7897";
    noProxy = "localhost,127.0.0.1,::1,*.local";
  };

  # 禁用所有形式的睡眠和休眠
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes         # 如果只想禁用休眠，可以保持 Suspend 启用
    AllowHibernation=no      # 禁用休眠 (Hibernate)
    AllowHybridSleep=yes# 禁用混合睡眠 (Hybrid Sleep)
    AllowSuspendThenHibernate=yes# 禁用先睡眠后休眠
  '';

  # timezone and local
  time.timeZone = "Asia/Shanghai";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_CTYPE = "zh_CN.UTF-8";
  };
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji

    dejavu_fonts

    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Sans" "Noto Sans CJK SC"];
        sansSerif = ["Noto Serif" "Noto Serif CJK SC"];
        monospace = ["Fira Code"];
      };
    };
  };

  programs.xwayland.enable = true;

  # Niri
  programs.niri.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  #services.displayManager.gdm.enable = true;
  #services.displayManager.gdm.wayland = true;
  #services.gnome.gnome-keyring.enable = true;
  #security.pam.services.gdm.enableGnomeKeyring = true;

  # services.displayManager.sddm.enable = true;

  services.displayManager.ly.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Enable sound.
  services.pulseaudio.enable = false;
  # OR
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # flatpak
  services.flatpak.enable = true;

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

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # allow none nix packages
  programs.nix-ld.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
