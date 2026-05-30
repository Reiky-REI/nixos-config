{
  config,
  lib,
  ...
}: let
  # 读取机器注册表，根据当前 hostname 自动匹配硬件档位
  machines = import ../../machines.nix;
  hostname = config.networking.hostName;
  thisMachine =
    if builtins.hasAttr hostname machines
    then machines.${hostname}
    else
      abort ''
        ╔══════════════════════════════════════════════════════════╗
        ║  机器 '${hostname}' 未在 machines.nix 中注册！           ║
        ║  请编辑 /etc/nixos/machines.nix 添加：                   ║
        ║    "${hostname}" = { profile = "high"; };              ║
        ║  可选档位: high / medium / low                          ║
        ╚══════════════════════════════════════════════════════════╝
      '';
in {
  options.hardware = {
    profile = lib.mkOption {
      type = lib.types.enum ["high" "medium" "low"];
      readOnly = true;
      description = "硬件性能档位，由 machines.nix 根据 hostname 自动匹配";
    };

    isHighPerf = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = config.hardware.profile == "high";
      description = "是否高性能档位";
    };

    isMediumPerf = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = config.hardware.profile == "medium";
      description = "是否中等性能档位";
    };

    isLowPerf = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = config.hardware.profile == "low";
      description = "是否低性能档位（关 blur/shadow/半透明等特效）";
    };
  };

  config.hardware.profile = thisMachine.profile;
}
