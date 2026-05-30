{
  isLowPerf,
  isHighPerf,
  isMediumPerf,
  ...
}: let
  sectionDir = ./sections;

  base = builtins.readFile (sectionDir + /base.kdl);

  # 根据硬件档位选择对应的配置段
  # high: 完整视觉效果（blur、shadow、动画、半透明）
  # medium: 折衷配置（预留，当前复用 low）
  # low:  极简配置（无特效、无动画、仅功能）
  profileKdl =
    if isHighPerf
    then builtins.readFile (sectionDir + /high.kdl)
    else if isLowPerf
    then builtins.readFile (sectionDir + /low.kdl)
    else builtins.readFile (sectionDir + /low.kdl);
in {
  programs.fuzzel.enable = true;

  home.file.".config/niri/config.kdl".text = base + "\n" + profileKdl;
}
