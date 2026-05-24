{pkgs, ...}: {
  home.packages = with pkgs; [
    wechat
    qq
    vlc
    obsidian
    youtube-music
    spotify
    kdePackages.dolphin
    netease-cloud-music-gtk
    logseq
    google-chrome
  ];

  # firefox
  programs.firefox = {
    enable = true; # 安装并启用 Firefox
    languagePacks = ["zh-CN"]; # 中文语言包，可按需加其他
    profiles.default = {
      name = "default"; # 默认 profile 名称
      isDefault = true; # 设置为默认 profile
      settings = {
        "privacy.donottrackheader.enabled" = true; # 开启“请勿跟踪”
      };
    };
  };

  # 视频软件
  programs.mpv.enable = true;
  # catppuccin.mpv = {
  #   enable = true;
  #   accent = "mauve";
  #   flavor = "mocha";
  # };

  # 录制软件
  programs.obs-studio.enable = true;
}
