{pkgs, ...}: {
  # CC Switch CLI: 统一管理 Claude Code / Codex / Gemini / OpenCode 的
  # provider、MCP、代理与技能。原先手装于 ~/.local/bin (非声明式),
  # 现由私源 Reiky-nixpkgs 提供, 升级走 nix (见 README 打包说明)。
  home.packages = with pkgs; [
    cc-switch
  ];
}
