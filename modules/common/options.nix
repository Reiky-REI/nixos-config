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
      type = lib.types.enum ["laptop" "desktop" "wsl" "vm"];
      default = "laptop";
      description = "机器种类: laptop / desktop / wsl / vm";
    };

    features = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "特性标签列表, 来自 machines.nix 的 features 字段";
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
