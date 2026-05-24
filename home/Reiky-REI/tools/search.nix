_:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --type f";
    defaultOptions = [
      "--preview '[ -d {} ] && eza --tree --level=2 --color=always {} || bat --color=always --style=numbers {}'"
      "--preview-window=right:60%"
    ];

    changeDirWidgetOptions = [
      "--preview '[ -d {} ] && eza --tree --level=2 --color=always {} || eza --color=always {}'"
      "--preview-window=right:40%"
    ];

    historyWidgetOptions = [
      "--no-preview"
    ];
  };

  programs.fd = {
    enable = true;
    hidden = true;
    ignores = ["node_modules" "target"];
  };

  programs.ripgrep.enable = true;
  programs.ripgrep-all.enable = true;
}
