{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./hardware-profile.nix
  ];

  # users setting
  nix.settings.trusted-users = ["root" username];
  nixpkgs.config.allowUnfree = true;
  # 临时允许 EOL electron-39 (vscode 等传递依赖), 26.05 升级后自动解决
  nixpkgs.config.permittedInsecurePackages = ["electron-39.8.10"];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
  nix.settings.max-jobs = lib.mkDefault (
    if config.hardware.isHighPerf
    then 16
    else if config.hardware.isMediumPerf
    then 8
    else 4
  );
  nix.settings.cores = 16;
  nix.settings.min-free = 5368709120;
  nix.settings.max-free = 10737418240;

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
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    # 静态 TTF 中文字体, 兼容 Steam 等自带旧版 fontconfig/freetype 的程序
    # (VF ttc 老库读不了, 见 known-issues.md "nix-shell 里跑 Steam 中文显示方块")
    wqy_microhei

    dejavu_fonts

    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Serif" "Noto Serif CJK SC"];
        sansSerif = ["Noto Sans" "Noto Sans CJK SC"];
        monospace = ["Fira Code"];
      };
    };
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = ["04:00"];

  # nix gc
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "daily";
    options = lib.mkDefault "--delete-older-than 3d";
  };

  # allow none nix packages
  programs.nix-ld.enable = true;

  # 关机/重启加速: 缩短僵尸服务等待时间, 避免长时间卡在黑屏
  # 背景: nvme1 (Windows 盘) 关机时 I/O 超时 + NVIDIA GSP 异常曾导致关机耗时 4 分钟
  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # polkit: wheel 组用户免密执行 systemd-run / pkexec 等提权操作
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    cachix
  ];
}
