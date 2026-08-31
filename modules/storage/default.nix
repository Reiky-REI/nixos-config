# ===== Storage: NAS SMB 挂载 =====
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./nas-mount.nix
  ];
}
