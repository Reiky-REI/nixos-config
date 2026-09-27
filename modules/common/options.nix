# ===== meow.* 机器标签选项 =====
# 由 lib/mkHost.nix 从 machines.nix 注入每台机器;
# 各模块用 lib.mkIf (config.meow.enabled ? "<tag>") 自我屏蔽,
# 宿主不再挑选模块 —— 加机器只需在 machines.nix 写一行标签。
{
  config,
  lib,
  ...
}: {
  options.meow = {
    kind = lib.mkOption {
      type = lib.types.enum ["laptop" "desktop" "wsl" "vm" "container"];
      default = "laptop";
      description = "机器种类: laptop / desktop / wsl / vm / container";
    };

    roles = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (import ../../lib/roles.nix));
      default = [];
      description = "Host 用途标签, 与 user/agent 身份独立";
    };

    desktopEffects = lib.mkOption {
      type = lib.types.enum ["full" "minimal"];
      default = "minimal";
      description = "桌面视觉效果档, 与硬件性能 profile 分离";
    };

    features = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (import ../../lib/features.nix));
      default = [];
      description = "经 lib/features.nix 校验的特性标签, 来自 machines.nix";
    };

    enabled = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      readOnly = true;
      description = "feature -> true 映射, 由 features 派生; 模块用 (config.meow.enabled ? \"tag\") 判断";
    };

    isWSL = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = config.meow.kind == "wsl";
      description = "是否 WSL 环境";
    };
  };

  config.meow.enabled = builtins.listToAttrs (
    map (f: lib.nameValuePair f true) config.meow.features
  );
}
