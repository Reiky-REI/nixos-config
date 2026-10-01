{
  lib,
  meow,
  ...
}: {
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

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    # 固定为变更前默认值, 保持 `yy` 习惯不变(上游新默认为 `y`)
    shellWrapperName = "yy";
  };

  programs.superfile.enable = true;
  programs.superfile.settings = builtins.fromTOML (builtins.readFile ./superfile.toml);

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
