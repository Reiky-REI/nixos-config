{
  pkgs,
  inputs,
  ...
}: let
  # 锁定在 v4.7.8-git (b99b7a7), 补丁: suspend 失败时自动解除 Noctalia 锁屏,
  # 避免 idle 尝试挂起失败后 lockScreenActive 卡 true 导致桌面小组件消失
  noctalia-shell = inputs.noctalia.packages.${pkgs.system}.default.overrideAttrs (old: {
    # patches = (old.patches or []) ++ [./noctalia-suspend-fallback.patch];  # 暂时禁用: patch 格式需要修复
    patches = old.patches or [];
  });
in {
  # 手动启动 (由 niri spawn-at-startup "noctalia-shell" 拉起)
  programs.noctalia-shell.systemd.enable = false;
  programs.noctalia-shell.enable = true;
  programs.noctalia-shell.package = noctalia-shell;
}
