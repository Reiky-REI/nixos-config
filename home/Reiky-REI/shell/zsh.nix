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
      # 2026-09-01: 家目录文件巨多 (node_modules/WorkSpace), 默认 30ms 扫描超时报 WARN, 提到 150ms 喵~
      scan_timeout = 150;
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
      dsh-tui = "/home/Reiky-REI/WorkSpace/bin/dsh-tui";
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
      #
      # 按用户名自动加载对应的密钥文件:
      #   ai_api_key_<USERNAME>.age → /run/agenix/ai_api_key_<USERNAME>
      # 这样系统上的每个用户可以有自己的密钥文件。
      for file in /run/agenix/ai_api_key_''${USER}; do
        [ -f "$file" ] && source "$file"
      done

      # === Claude Code + cc-switch 本地代理 ===
      # env 由 cc-switch 管理（~/.claude/settings.json），这里只设代理地址
      # cc-switch 本地代理处理 Anthropic bridge 验证，避免 "Not logged in"
      export ANTHROPIC_BASE_URL=http://127.0.0.1:15721
      export ANTHROPIC_AUTH_TOKEN=proxy-placeholder
      export CLAUDE_CODE_EFFORT_LEVEL=max

      # === DSH-TUI 启动器入口 ===
      export PATH="$HOME/WorkSpace/bin:$PATH"

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
