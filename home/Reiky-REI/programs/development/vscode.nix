{pkgs-unstable, ...}: {
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    package = pkgs-unstable.vscode;
  };
}
