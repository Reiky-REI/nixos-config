{pkgs, ...}: {
  # OpenCode CLI: v2 (2.0.10, Reiky-nixpkgs 私源 — nixpkgs 尚未收录 v2)。
  # root 高级权限通道 (services.opencode-root) 单独 pin 在 v1, 见该模块 —
  # v2 的 serve 强制密码鉴权, 与 mcp-agents-bridge 的 v1 API 契约不兼容。
  environment.systemPackages = [pkgs.opencode-v2];
}
