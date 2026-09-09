{pkgs, ...}: {
  home.packages = with pkgs; [
    google-chrome

    # Zen Browser: 取代原 programs.firefox (Firefox 分支, 隐私向, 主打工作区分组)
    # 由个人私源 Reiky-nixpkgs 以 overlay 提供 (nixpkgs 未收录, 见 flake.nix inputs)
    zen-browser
  ];

  # 迁移说明 (2026-09-09):
  # - 原 programs.firefox 的 configPath/languagePacks/profiles.settings 一并移除。
  #   home-manager 无 zen-browser 模块, 无法声明式托管其 profile;
  #   原 privacy.donttrackheader.enabled 是 Firefox 136 起已废弃的 DNT 遗留项, 无需保留。
  # - 书签已从 ~/.mozilla/firefox 迁移到 ~/.zen (见复盘), 语言包按需在设置界面装。
  # - 自动更新由包内 distribution/policies.json 禁用, 升级一律走 nix。
  # - 默认浏览器仍为 google-chrome (见 home/Reiky-REI/default.nix 的 xdg.mimeApps),
  #   zen 通过 niri 快捷键 Mod+Shift+B (spawn "zen") 启动。
}
