{ pkgs, ... }:

{
  # 2026-10-07 卸载 OBS (myOBS wrapOBS 块已删, 释放 ~3.8G) 与 SPlayer (1.5G) 喵~
  # 重装: 恢复 myOBS/wrapOBS 三插件 + splayer, binary-cache 命中无需重编译喵~
  home.packages = with pkgs; [
    vlc
    krita
  ];

  # MPV 配置保持不变
  programs.mpv.enable = true;
}
