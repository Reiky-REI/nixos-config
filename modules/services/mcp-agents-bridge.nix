# ===== mcp-agents-bridge: 公共 MCP server (任务G) =====
# 把电脑可用 agents 能力 + 高级权限(root 通道 9502)封装为 MCP server,
# DSH(dsh-mcp-client)与 AstrBot(mcp_server.json)均作为 client 接入。
# 安全边界: 只监听 127.0.0.1:9503; 服务以普通用户运行不持 root; 高级权限经 9502 按需获取;
# server.py 内置危险命令黑名单(rm -rf / 等), 白名单之外默认放行但由调用方自律。
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.mcp-agents-bridge;
in {
  options.services.mcp-agents-bridge = {
    enable = lib.mkEnableOption "公共 MCP bridge server (DSH/AstrBot 可调, 聚合高级权限+agents 能力)";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9503;
      description = "Streamable-HTTP listen port (127.0.0.1 only).";
    };
    serverPy = lib.mkOption {
      type = lib.types.path;
      default = "/home/Reiky-REI/WorkSpace/mcp-agents-bridge/server.py";
      description = "Path to server.py.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mcp-agents-bridge = {
      description = "mcp-agents-bridge: 公共 MCP server (advanced-privilege + agents tools, :${toString 9503})";
      after = ["network.target" "opencode-root.service" "astrabot.service" "dsh-fence.service"];
      wants = ["network.target"];
      wantedBy = ["multi-user.target"];
      path = ["/run/current-system/sw"];
      serviceConfig = {
        Type = "simple";
        User = "Reiky-REI";
        Group = "users";
        WorkingDirectory = "/home/Reiky-REI/WorkSpace/mcp-agents-bridge";
        Environment = [
          "ROOT_SERVE_URL=http://127.0.0.1:9502"
          "DSH_BRIDGE_URL=http://127.0.0.1:6185"
          "ASTRA_BOT_URL=http://127.0.0.1:6185"
          "HOME=/home/Reiky-REI"
        ];
        ExecStart = "/home/Reiky-REI/WorkSpace/astrabot/.venv/bin/python /home/Reiky-REI/WorkSpace/mcp-agents-bridge/server.py";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
