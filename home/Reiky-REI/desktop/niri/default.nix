{
  isLowPerf,
  isHighPerf,
  isMediumPerf,
  lib,
  meow,
  ...
}: let
  sectionDir = ./sections;

  # WSL 嵌套场景: Windows 键被宿主系统吃掉 (Win+D/E/L 全局快捷键轮不到嵌套 niri),
  # 改用 Alt 作 Mod; 真机 (kind != wsl) 保持 Mod = Super 原样
  mod = if meow.kind == "wsl" then "Alt" else "Mod";

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

  # mod 替换: 只动 "Mod+" / "Super+" 绑定 token (注释里的 "Mod-" 不受影响)。
  # 注意 base.kdl 两种写法混用 (noctalia 绑定是字面 Super+), 都要替换;
  # mod = "Mod" 时原样返回, NixMEOW 配置逐字节不变。
  # WSL 还需消解替换后的重复键: 真机上 Super+L 与 Mod+L 等靠字面串不同而共存,
  # 全部换成 Alt 后成为 exact duplicate (niri 解析报错), 处理:
  #   - 锁屏 (hyprlock) 试验台无意义 → 删除该绑定
  #   - switch-focus-between-floating-and-tiling 挪到 Alt+Shift+G (Shift+G 空闲),
  #     把 Alt+Shift+V 让给 noctalia 剪切板
  withMod = text:
    if mod == "Mod"
    then text
    else let
      step1 = lib.replaceStrings ["Mod+" "Super+"] ["${mod}+" "${mod}+"] text;
    in
      lib.replaceStrings
        [
          "Alt+L hotkey-overlay-title=\"锁屏: hyprlock\" { spawn-sh \"hyprlock\"; }"
          "Alt+Shift+V { switch-focus-between-floating-and-tiling; }"
        ]
        [
          "// WSL: 锁屏无意义, 绑定已移除 (原 Super+L, 见本文件 withMod 注释)"
          "Alt+Shift+G { switch-focus-between-floating-and-tiling; }"
        ]
        step1;
in {
  programs.fuzzel.enable = true;

  home.file.".config/niri/config.kdl".text = withMod base + "\n" + withMod profileKdl;
}
