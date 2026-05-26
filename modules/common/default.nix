{
  lib,
  pkgs,
  username,
  ...
}: {
  # users setting
  nix.settings.trusted-users = ["root" username];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
  nix.settings.max-jobs = 8;
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
    noto-fonts-cjk-serif
    noto-fonts-color-emoji

    dejavu_fonts

    liberation_ttf

    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono

    wqy_zenhei
    wqy_microhei

    arphic-ukai
    arphic-uming
  ];

  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Noto Serif" "Noto Serif CJK SC" "AR PL UMing CN" "Liberation Serif"];
        sansSerif = ["Noto Sans" "Noto Sans CJK SC" "WenQuanYi Zen Hei" "Liberation Sans"];
        monospace = ["Fira Code" "Liberation Mono"];
      };
      localConf = ''
        <fontconfig>
        <!-- WPS Office Windows font aliases -->
        <alias>
          <family>SimSun</family>
          <prefer>
            <family>AR PL UMing CN</family>
            <family>Noto Serif CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>SimHei</family>
          <prefer>
            <family>WenQuanYi Zen Hei</family>
            <family>Noto Sans CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>KaiTi</family>
          <prefer>
            <family>AR PL UKai CN</family>
            <family>Noto Serif CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>FangSong</family>
          <prefer>
            <family>AR PL UKai CN</family>
            <family>Noto Serif CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>Microsoft YaHei</family>
          <prefer>
            <family>WenQuanYi Micro Hei</family>
            <family>Noto Sans CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>Microsoft JhengHei</family>
          <prefer>
            <family>WenQuanYi Micro Hei</family>
            <family>Noto Sans CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>Times New Roman</family>
          <prefer>
            <family>Liberation Serif</family>
            <family>Noto Serif</family>
          </prefer>
        </alias>
        <alias>
          <family>NSimSun</family>
          <prefer>
            <family>AR PL UMing CN</family>
            <family>Noto Serif CJK SC</family>
          </prefer>
        </alias>
        <alias>
          <family>MingLiU</family>
          <prefer>
            <family>AR PL UMing CN</family>
          </prefer>
        </alias>
        <alias>
          <family>PMingLiU</family>
          <prefer>
            <family>AR PL UMing CN</family>
          </prefer>
        </alias>
        </fontconfig>
      '';
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

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    cachix
  ];
}
