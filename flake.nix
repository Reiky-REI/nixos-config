{
  description = "MEOW configuration";
  nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
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
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-715,
    home-manager,
    CookNixvim,
    agenix,
    catppuccin,
    noctalia,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    # 7.1.5 内核专用打包集 (仅 kernelPackages 使用)
    pkgs-715 = import nixpkgs-715 {
      inherit system;
      config.allowUnfree = true;
    };

    # 7.1.5 kernelPackages + 键盘背光补丁驱动 (复刻下方 overlay 的 tuxedo 扩展)
    kernelPackages715 = (pkgs-715.linuxPackages_7_1).extend (kfinal: kprev: {
      tuxedo-drivers = kfinal.callPackage ./pkgs/tuxedo-drivers-patched {};
      tuxedo-keyboard = kfinal.callPackage ./pkgs/tuxedo-drivers-patched {};
    });
    user = import ./config.nix;
    opencodeConfig = import ./lib/opencode-config.nix {flakeRoot = self;};
    claudeConfig = import ./lib/claude-config.nix {
      flakeRoot = self;
      username = user.username;
    };
  in {
    inherit opencodeConfig claudeConfig;

    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    checks.${system}.nixos = self.nixosConfigurations.NixMEOW.config.system.build.toplevel;

    nixosConfigurations = {
      NixMEOW = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs pkgs-unstable;
          username = user.username;
          fullName = user.fullName;
        };

        modules = [
          ./hosts/MEOW/default.nix
          agenix.nixosModules.default
          catppuccin.nixosModules.catppuccin

          {
            age.secrets.ai_api_key_REIKY_REI = {
              file = ./secrets/ai_api_key_REIKY_REI.age;
              owner = user.username;
            };
            age.identityPaths = ["/home/${user.username}/.ssh/id_ed25519"];
          }

          ({
            pkgs,
            lib,
            config,
            ...
          }: {
            nixpkgs.overlays = [
              (final: prev: {
                # 回退 niri 到旧 nixpkgs-unstable rev (f83fc3c): 新 rev 的 niri 26.04 有
                # QSH/壁纸层闪烁回归, 见 known-issues "niri 26.04 layer-shell 壁纸层闪到最前"
                niri = pkgs-unstable.niri;
                # QQ 3.2.27 deb 被腾讯下架 (上游 nixpkgs bug), 复用本地已安装的旧版
                qq = prev.runCommand "qq-3.2.27" {} ''
                  ln -s /nix/store/4fwl2khg6iwm34kjxq855zyncc43fcx7-qq-3.2.27-2026-04-01 $out
                '';
                # 键盘背光补丁版驱动 (COLORFIRE MEOW R16 固件误报背光类型)
                linuxPackages = prev.linuxPackages.extend (kfinal: kprev: {
                  tuxedo-drivers = kfinal.callPackage ./pkgs/tuxedo-drivers-patched {};
                  tuxedo-keyboard = kfinal.callPackage ./pkgs/tuxedo-drivers-patched {};
                });
              })
              # waydroid .net 脚本 overlay（定义在 modules/virtualization/default.nix）
            ];
          })

          ({lib, ...}: {
            # 内核 7.1.5 (nixpkgs-715 pin): 覆盖 hardware.nix 的 linuxPackages_7_1
            boot.kernelPackages = lib.mkForce kernelPackages715;
          })

          home-manager.nixosModules.home-manager
          {
            environment.systemPackages = [agenix.packages.${system}.default];
          }
          ({config, ...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs pkgs-unstable;
              username = user.username;
              fullName = user.fullName;
              inherit (config.hardware) profile isLowPerf isHighPerf isMediumPerf;
            };
            home-manager.users.${user.username} = {
              imports = [
                catppuccin.homeModules.catppuccin
                agenix.homeManagerModules.default
                noctalia.homeModules.default
                ./home/${user.username}
              ];
              home.packages = [
                pkgs-unstable.mpvpaper
                CookNixvim.packages.${system}.default
              ];
            };
          })
        ];
      };
    };
  };
}
