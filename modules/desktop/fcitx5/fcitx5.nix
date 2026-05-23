{
  pkgs,
  lib,
  config,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      fcitx5 = prev.fcitx5.overrideAttrs (old: {
        cmakeFlags = (old.cmakeFlags or []) ++ ["-DUSE_QT6=ON"];
        buildInputs = (old.buildInputs or []) ++ [final.qt6.qtbase];
        dontWrapQtApps = true;
      });
      fcitx5-rime = prev.fcitx5-rime.override {fcitx5 = final.fcitx5;};
      fcitx5-gtk = prev.fcitx5-gtk.override {fcitx5 = final.fcitx5;};
    })
  ];
  # 选择输入法类型为 fcitx5
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
  };

  # 添加常用中文模块
  i18n.inputMethod.fcitx5.addons = with pkgs; [
    qt6Packages.fcitx5-configtool
    qt6Packages.fcitx5-chinese-addons # 拼音、五笔等
  ];
  i18n.inputMethod.fcitx5.waylandFrontend = true;

  /*
  *i18n.inputMethod.fcitx5.settings.inputMethod与catppuccin.fcitx5.apply相冲突
  *因为两者都试图管理同一个配置文件
  *catppuccin.fcitx5可以导入主题配色可以使用classicui.globalSection.Theme导入主题
  *也可以禁用inputMethod，设置主题。
  */

  # 设置rime输入法与美式键盘英文输入法并排序rime第一位
  i18n.inputMethod.fcitx5.settings.inputMethod = {
    GroupOrder."0" = "Default";
    "Groups/0" = {
      Name = "Default";
      "Default Layout" = "us";
      DefaultIM = "keyboard-us";
    };
    "Groups/0/Items/0".Name = "keyboard-us";
    "Groups/0/Items/1".Name = "pinyin";
  };

  i18n.inputMethod.fcitx5.settings = {
    globalOptions = {
      "Behavior" = {
        # 关键设置：关闭程序内预编辑，强制使用 Fcitx5 浮窗(能解决 neovide 中无法预编辑的问题)
        "PreeditEnabledByDefault" = "False";
      };
      "Hotkey/TriggerKeys" = {"0" = "Super+space";};
    };
    addons.classicui.globalSection.Theme = "catppuccin-mocha-mauve";
  };

  # catppuccin的flake,option
  catppuccin.fcitx5 = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };

  environment.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    QT5_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };
}
