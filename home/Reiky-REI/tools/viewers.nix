_:
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    colors = "auto";
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
    config = {
      number = true;
      paging = "always";
    };
  };

  programs.jq.enable = true;

  programs.imv.enable = true;

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
