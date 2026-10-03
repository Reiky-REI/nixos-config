{
  description = "MEOW configuration";
  nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    # 走代理时 HTTP/2 流不稳定, 强制 HTTP/1.1 避免大文件传输中断
    http2 = false;
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # 内核 7.1.5 pin (2026-07-30 rev c578459): 7.1.6 amdgpu 在 niri 有已知伪影回归
    # (窗口表面间歇丢合成/壁纸透上来, 见 known-issues), 仅用于 boot.kernelPackages
    nixpkgs-715.url = "github:NixOS/nixpkgs/c5784590f98b42b4548d932005e365b4584c6be7";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 注意: 锁定在 v4.7.8-git (b99b7a7), 不要 `nix flake update --update-input noctalia`
    # 上游 main 已变成 v5 (noctalia), 与当前 QML shell 配置不兼容
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CookNxivim 配置完整版, 原作者：github.com:Youthdreamer
    CookNixvim = {
      url = "github:Reiky-REI/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri
    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL (NixMEOW-WSL 宿主用)
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 个人 Nix 私源 (zen-browser 等 nixpkgs 未收录的包), 以 overlay 形式消费
    # 见 https://github.com/Reiky-REI/Reiky-nixpkgs README
    # follows 主 nixpkgs: overlay 走消费方 pkgs (final.callPackage), 不额外拉一份 nixpkgs
    Reiky-nixpkgs = {
      url = "github:Reiky-REI/Reiky-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    defaultSystem = "x86_64-linux";

    users = import ./users.nix;
    machines = import ./machines.nix;
    systems = nixpkgs.lib.unique (map (machine: machine.system or defaultSystem) (builtins.attrValues machines));
    primaryUser = users.${machines.NixMEOW.primaryUser};
    # agent 注册表: 一次校验, 供 flake 输出与各 host 的客户端适配层消费
    agentsConfig = import ./lib/agents.nix {
      lib = nixpkgs.lib;
      agents = import ./agents.nix;
      inherit users machines;
    };
    opencodeConfig = import ./lib/opencode-config.nix {
      flakeRoot = self;
      inherit agentsConfig;
    };
    claudeConfig = import ./lib/claude-config.nix {
      flakeRoot = self;
      username = primaryUser.username;
      inherit agentsConfig;
    };

    # 机器由 machines.nix 注册表生成, 见 lib/mk-host.nix:
    # 加一台新机器 = machines.nix 注册 + hosts/<name>/default.nix, 本文件不用动
    mkHost = hostName: machine:
      import ./lib/mk-host.nix {
        inherit inputs;
        system = machine.system or defaultSystem;
      }
      hostName
      machine;
  in {
    inherit opencodeConfig claudeConfig agentsConfig;

    formatter.${defaultSystem} = nixpkgs.legacyPackages.${defaultSystem}.alejandra;

    # 可交付产物: 带 docker tarball 的 host 暴露成 packages.<system>.<host>-docker
    packages = nixpkgs.lib.genAttrs systems (
      targetSystem:
        nixpkgs.lib.listToAttrs (
          builtins.concatMap (
            hostName: let
              host = self.nixosConfigurations.${hostName};
              hostSystem = machines.${hostName}.system or defaultSystem;
            in
              nixpkgs.lib.optionals
              (hostSystem == targetSystem && host.config.system.build ? tarball)
              [(nixpkgs.lib.nameValuePair "${hostName}-docker" host.config.system.build.tarball)]
          ) (builtins.attrNames machines)
        )
    );

    checks = builtins.listToAttrs (map (
        targetSystem: let
          hostNames =
            builtins.filter (
              hostName: (machines.${hostName}.system or defaultSystem) == targetSystem
            )
            (builtins.attrNames machines);
          hostChecks = nixpkgs.lib.mapAttrs' (
            hostName: host:
              nixpkgs.lib.nameValuePair "nixos-${hostName}" host.config.system.build.toplevel
          ) (builtins.listToAttrs (map (hostName: nixpkgs.lib.nameValuePair hostName self.nixosConfigurations.${hostName}) hostNames));
          compatibilityCheck =
            if targetSystem == defaultSystem
            then {nixos = self.nixosConfigurations.NixMEOW.config.system.build.toplevel;}
            else {};
        in
          nixpkgs.lib.nameValuePair targetSystem (hostChecks // compatibilityCheck)
      )
      systems);

    nixosConfigurations = builtins.mapAttrs mkHost machines;
  };
}
