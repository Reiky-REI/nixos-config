# 标准 NixOS 系统级 Service 模块模板

# 注意: 本文件为未经验证的模板。
# 参考 convention: 服务 daemon 放 modules/services/, 桌面基础放 modules/desktop/
# 缩进: 2 空格。函数参数: config, lib, pkgs, ... (字母序)

{ config, lib, pkgs, ... }:
let
  cfg = config.services.myService;
in {
  # ============================================================
  # 1. 选项定义 (options)
  # ============================================================
  options.services.myService = {
    enable = lib.mkEnableOption "myService daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.myService;
      description = "The myService package to use";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Configuration settings";
    };
  };

  # ============================================================
  # 2. 配置生成 (config)
  # ============================================================
  config = lib.mkIf cfg.enable {

    # 2a. 安装系统包
    environment.systemPackages = [ cfg.package ];

    # 2b. systemd service 定义
    systemd.services.myService = {
      description = "My Service Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/myService";

        # AI 服务 hardening (参考 nixpkgs services.ollama)
        DynamicUser = true;
        StateDirectory = "myService";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";

        # GPU 访问 (如果 AI 服务需要 CUDA)
        DeviceAllow = [ "char-nvidiactl" "char-nvidia-caps" "char-drm" ];
        DevicePolicy = "closed";
        SupplementaryGroups = [ "render" ];
      };
    };

    # 2c. 持久化目录 (如需要)
    systemd.tmpfiles.rules = [
      "d /var/lib/myService 0700 myService myService -"
    ];
  };
}
