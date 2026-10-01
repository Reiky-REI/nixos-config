{...}: {
  programs.zed-editor.enable = true;
  programs.zed-editor.userSettings = builtins.fromJSON (builtins.readFile ./zed-settings.json);
}
