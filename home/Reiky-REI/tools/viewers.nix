_: {
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
    # 固定为变更前默认值, 保持 `yy` 习惯不变(上游新默认为 `y`)
    shellWrapperName = "yy";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
