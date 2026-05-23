{pkgs, ...}: let
  qt6pkgs = pkgs.qt6Packages;
in {
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [
      qt6pkgs.fcitx5-chinese-addons # 修正包名
      fcitx5-gtk
    ];
  };

  i18n.inputMethod.fcitx5.settings = {
    inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "keyboard-us";
      };
      "Groups/0/Items/0".Name = "keyboard-us";
      "Groups/0/Items/1".Name = "pinyin";
    };
    globalOptions = {
      "Hotkey/TriggerKeys" = {"0" = "Super+space";};
    };
  };

  catppuccin.fcitx5 = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
    enableRounded = true;
    apply = true;
  };
}
