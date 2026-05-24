{pkgs, ...}: {
  home.packages = with pkgs; [
    google-chrome
  ];

  programs.firefox = {
    enable = true;
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
