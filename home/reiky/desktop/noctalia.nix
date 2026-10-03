{
  config,
  lib,
  pkgs,
  inputs,
  noctaliaMonitors,
  ...
}: let
  # 锁定在 v4.7.8-git (b99b7a7), 补丁: suspend 失败时自动解除 Noctalia 锁屏,
  # 避免 idle 尝试挂起失败后 lockScreenActive 卡 true 导致桌面小组件消失
  noctalia-shell = inputs.noctalia.packages.${pkgs.system}.default.overrideAttrs (old: {
    # patches = (old.patches or []) ++ [./noctalia-suspend-fallback.patch];  # 暂时禁用: patch 格式需要修复
    patches = old.patches or [];
  });

  mergeJson = import ../lib/merge-json-activation.nix {inherit lib pkgs;};
  settingsTemplate = builtins.fromJSON (builtins.readFile ./noctalia-settings.json);
  monitorWidgets =
    if builtins.length noctaliaMonitors >= 2
    then
      map (widget:
        widget
        // {
          name =
            if widget.name == "@primary-monitor@"
            then builtins.elemAt noctaliaMonitors 0
            else builtins.elemAt noctaliaMonitors 1;
        })
      settingsTemplate.desktopWidgets.monitorWidgets
    else [];
  settings = lib.recursiveUpdate settingsTemplate {
    desktopWidgets.monitorWidgets = monitorWidgets;
    wallpaper.directory = "${config.home.homeDirectory}/Pictures/Wallpapers/static";
  };
  settingsFile = pkgs.writeText "noctalia-settings.json" (builtins.toJSON settings);
  pluginsFile = pkgs.writeText "noctalia-plugins.json" (builtins.readFile ./noctalia-plugins.json);
in {
  # 手动启动 (由 niri spawn-at-startup "noctalia-shell" 拉起)
  programs.noctalia-shell.systemd.enable = false;
  programs.noctalia-shell.enable = true;
  programs.noctalia-shell.package = noctalia-shell;

  home.activation.mergeNoctaliaSettings = mergeJson {
    target = "${config.xdg.configHome}/noctalia/settings.json";
    source = settingsFile;
  };
  home.activation.mergeNoctaliaPlugins = mergeJson {
    target = "${config.xdg.configHome}/noctalia/plugins.json";
    source = pluginsFile;
  };

  # 本地自定义插件: mihomo 代理状态 bar 组件 (源码真源在 ./plugins/mihomo-proxy)
  xdg.configFile."noctalia/plugins/mihomo-proxy".source = ./plugins/mihomo-proxy;
}
