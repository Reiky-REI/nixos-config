{ pkgs, ... }:

let
  # 为了可读性，把 OBS 及其插件单独提取为一个变量
  myOBS = pkgs.wrapOBS {
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs                   # Wayland 屏幕捕获
      obs-pipewire-audio-capture # PipeWire 音频捕获
      obs-vkcapture            # 游戏画面捕获（可选）
      # 如果以后需要更多插件，直接在这里追加，保持列表整洁
    ];
  };
in
{
  # 系统全局包（如果你在 systemPackages 中使用）或 home-manager 的 home.packages
  home.packages = with pkgs; [
    vlc
    splayer
    krita
    myOBS  # 替换掉原本的 obs-studio
    # 其他工具...
  ];

  # MPV 配置保持不变
  programs.mpv.enable = true;
}
