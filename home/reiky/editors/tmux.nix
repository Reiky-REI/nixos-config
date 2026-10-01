{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    clock24 = true;
    escapeTime = 0;
    mouse = true;
    prefix = "C-a";
    terminal = "tmux-256color";
    historyLimit = 5000;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      yank
      vim-tmux-navigator
      sensible
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_status_default "on"
          set -g @catppuccin_status_background "default"
        '';
      }
    ];
    extraConfig = ''
      set -g default-command ${pkgs.zsh}/bin/zsh
      setw -g mode-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection
      bind-key C-u if -F '#{pane_in_mode}' 'send-keys C-u' 'copy-mode -u; send-keys -X page-up'
      unbind C-b
      bind C-a send-prefix
      bind | split-window -h
      bind - split-window -v
      bind Enter run 'tmux new-window ~/bin/tmux-sessionizer'
    '';
  };
}
