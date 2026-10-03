{
  pkgs,
  config,
  meow,
  userId,
  ...
}: let
  # 真机 clash-verge 端口 7897; WSL 走宿主 clash = 7890
  # (WSL .wslconfig hostAddressLoopback=true, 127.0.0.1 直达 Windows, 已实测)
  proxyPort =
    if meow.kind == "wsl"
    then "7890"
    else "7897";
in {
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
      # 命名规则: secrets/ai-api-key-<userId>.age → /run/agenix/ai-api-key-<userId>
      # 注意: /run/agenix 目录不可列 (只有 x 权限), 不能用 glob, 必须拼精确路径
      if [ -f /run/agenix/ai-api-key-${userId} ]; then
        source /run/agenix/ai-api-key-${userId}
      fi

      # === Claude Code + cc-switch 本地代理 ===
      # env 由 cc-switch 管理（~/.claude/settings.json），这里只设代理地址
      # cc-switch 本地代理处理 Anthropic bridge 验证，避免 "Not logged in"
      export ANTHROPIC_BASE_URL=http://127.0.0.1:15721
      export ANTHROPIC_AUTH_TOKEN=proxy-placeholder
      export CLAUDE_CODE_EFFORT_LEVEL=max

      # === DSH-TUI 启动器入口 ===
      export PATH="$HOME/WorkSpace/bin:$PATH"

      # === 代理设置 ===
      export http_proxy=http://127.0.0.1:${proxyPort}
      export https_proxy=http://127.0.0.1:${proxyPort}
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
