# ===== DSH 外层围栏 (nixos-guard FENCE 加固) =====
#
# 守衡协议的三层护栏中,FENCE(沙箱/审批)属于 dsh 宿主平面,预设层无法加强。
# 本模块把"进程级"围栏补在 NixOS 层:用一个加固的 systemd 服务包住整个
# dsh web 进程树——由工具启动的 bash 子进程继承同一套挂载/能力限制。
#
# 设计取向(对照社区共识 agent-sandbox.nix / ranti.dev):
#   - 默认可读、写入白名单:整个 home 只读,仅 workspace 与 ~/.dsh 可写;
#   - 不去覆盖 dsh 内层沙箱:内层 Landlock 逐调用收容照常工作,两层叠加;
#   - 网络不在此处一刀切:dsh 需要访问 API 与 web 检索,出口白名单建议
#     在 networking/clash 层做(见 nixos-guard-protocol 技能第 4/8 节)。
#
# 注意:
#   - 启用后 dsh 由 systemd 接管 3080 端口,请先停掉手动启动的 dsh 进程;
#   - PrivateTmp=true 使 /tmp 按服务隔离:跨进程传文件请走 workspace
#     (如 just install-apk 的 APK 应下载到 workspace 再装)。
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.dsh-fence;
  dshHome = "/home/${username}/.dsh";
  fallbackWorkspace = "/home/${username}/WorkSpace";
in {
  options.services.dsh-fence = {
    enable = lib.mkEnableOption "hardened systemd service for the DeepSeek Harness (dsh) web app";
    binPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${username}/node_modules/@deepseek-ai/dsh/lib/bin.js";
      description = "Absolute path of the dsh bin.js entry.";
    };
    workspace = lib.mkOption {
      type = lib.types.str;
      default = fallbackWorkspace;
      description = "Writable workspace root handed to agent sessions.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.dsh-fence = {
      description = "DeepSeek Harness web app (nixos-guard outer fence)";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = username;
        Group = "users";
        WorkingDirectory = cfg.workspace;
        ExecStart = "${pkgs.nodejs_22}/bin/node --expose-internals ${cfg.binPath} web";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";

        # ── 外层围栏:整棵 dsh 进程树的单元级限制 ──
        # 文件系统:home 只读,白名单两处可写;系统其余部分只读。
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [
          cfg.workspace
          dshHome
        ];
        PrivateTmp = true;

        # 内核/硬件面:收窄可见性与可写面。
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        PrivateDevices = true;

        # 权限:零能力、无提权;node JIT 需要 W+X,保持默认关闭 MDWE。
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        SystemCallArchitectures = "native";
        MemoryDenyWriteExecute = false;

        # 网络:只留进程间与 TCP(API/检索/页面);出口白名单见模块头注释。
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      };
    };
  };
}
