{pkgs, ...}: {
  home.packages = with pkgs; [
    zsh-powerlevel10k
  ];

  home.file.".p10k.zsh" = {
    source = ./p10k.zsh;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
    };
  };
  home.shell.enableZshIntegration = true;
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      lta = "ls --tree --long --icons";
      nv = "nvim";
      snv = "sudo nvim";
      ff = "fastfetch";
      nlg = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      ncg = "sudo nix-collect-garbage -d"; # 清理无用包
    };
    #    使用P10K打开下面以下注释
    initContent = ''
      [ -f ~/.zsh_secrets ] && source ~/.zsh_secrets
      [ -f ~/.zsh_local ] && source ~/.zsh_local
      # source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      # [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # === agenix 解密密钥加载 ===
      # secrets/ 目录中的 .age 文件在 rebuild 时由 agenix 自动解密到 /run/agenix/
      # 编辑密钥:  agenix -e secrets/<name>.age -i ~/.ssh/id_ed25519
      # 重加密:    agenix -r secrets/ -i ~/.ssh/id_ed25519
      for file in /run/agenix/ai_api_key; do
        [ -f "$file" ] && source "$file"
      done

      # === 代理设置 ===
      export http_proxy=http://127.0.0.1:7897
      export https_proxy=http://127.0.0.1:7897
    '';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
    };
  };
}
