# ===== NixMEOW-WSL — Windows WSL2 试验台 =====
# 定位: 无 NVIDIA 黑屏风险的 nixos-rebuild switch 迭代场 + nested niri。
# 平台配置全部由 inputs.nixos-wsl 模块提供 (boot loader/文件系统由它接管)。
# 特性标签见 machines.nix —— 目前只开 compositor-niri。
{
  inputs,
  pkgs,
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
