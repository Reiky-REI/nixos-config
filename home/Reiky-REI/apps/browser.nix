{pkgs, ...}: {
  home.packages = with pkgs; [
    google-chrome
  ];

  programs.firefox = {
    enable = true;
    # 固定旧路径, 避免上游默认变更(.mozilla -> xdg.configHome)引发 profile 迁移
    configPath = ".mozilla/firefox";
    languagePacks = ["zh-CN"];
    profiles.default = {
      name = "default";
      isDefault = true;
      settings = {
        "privacy.donttrackheader.enabled" = true;
      };
    };
  };
}
