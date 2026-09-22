# ===== NixMEOW-WSL — Windows WSL2 试验台 =====
# 定位: 无 NVIDIA 黑屏风险的 nixos-rebuild switch 迭代场 + nested niri。
# 平台配置全部由 inputs.nixos-wsl 模块提供 (boot loader/文件系统由它接管)。
# 特性标签见 machines.nix —— 目前只开 compositor-niri。
{
  inputs,
  pkgs,
  lib,
  username,
  fullName,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default

    # 共享模块树 —— 各模块按 machines.nix 的标签自我屏蔽
    ../../modules
  ];

  networking.hostName = "NixMEOW-WSL";

  # WSL NAT 下国内镜像不稳定: 只走官方 cache + 禁 HTTP/2 (走代理已知问题)
  nix.settings.substituters = lib.mkForce ["https://cache.nixos.org"];
  nix.settings.http2 = lib.mkForce false;

  # 试验台不开文档生成: nixos-render-docs 的 python 依赖在 cache.nixos.org 上 404
  # (上游 Hydra 没构建), 会让整个 build 打地鼠; NixMEOW 不受影响
  documentation.nixos.enable = false;
  documentation.man.cache.enable = lib.mkForce false;
  home-manager.users.${username}.manual.manpages.enable = false;

  wsl.enable = true;
  wsl.defaultUser = username;

  users.users.${username} = {
    description = fullName;
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = ["wheel" "audio" "video"];
  };

  system.stateVersion = "26.05";
}
