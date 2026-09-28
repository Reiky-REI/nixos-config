{
  lib,
  pkgs,
  ...
}: {
  # OpenCode CLI: v2 (2.0.10, Reiky-nixpkgs 私源 — nixpkgs 尚未收录 v2)。
  environment.systemPackages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [pkgs.opencode-v2];
}
