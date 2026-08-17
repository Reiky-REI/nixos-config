# ===== opencode-root: 高级权限 opencode serve 开机自启 =====
#
# 需求来源 (2026-08-17 用户): DSH 沙箱无 root (NoNewPrivs + Seccomp),
# 系统级操作 (改 /etc/nixos / git / nixos-rebuild switch) 需借道一个
# root 权限的 opencode serve。此前靠用户在 tmux 里手动开
#   sudo -E env HOME=/home/<user> opencode serve --port 9502
# 但重启即丢 (2026-08-17 睡眠唤醒黑屏强制重启后通道丢失, 需用户重开)。
# 本模块把它固化为 systemd 服务, 与 dsh-fence/astrabot 一起开机自启。
#
# 安全边界 (必须遵守):
#   - 只监听 127.0.0.1, 不暴露到局域网/公网;
#   - 无内置鉴权 (opencode serve 无 token 选项), 本机任意用户可连;
#     因此仅限本机信任进程使用, 不要开 firewall 端口;
#   - HOME 指到用户家目录以复用 opencode 配置/auth (provider key);
#   - 服务以 root 运行 = 高级权限通道, 调用方必须自律 (见 skill)。
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.opencode-root;
in {
  options.services.opencode-root = {
    enable = lib.mkEnableOption "root opencode serve (advanced-privilege channel)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9502;
      description = "Listen port (127.0.0.1 only).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.opencode-root = {
      description = "opencode serve (root, advanced-privilege channel :${toString cfg.port})";
      after = ["network.target" "dsh-fence.service"];
      wants = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = ["/run/current-system/sw"];
      serviceConfig = {
        Type = "simple";
        User = "root";
        WorkingDirectory = "/home/${username}";
        Environment = [
          "HOME=/home/${username}"
          "PATH=/run/current-system/sw/bin:/usr/bin:/bin"
        ];
        ExecStart = "/run/current-system/sw/bin/opencode serve --port ${toString cfg.port} --hostname 127.0.0.1";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
