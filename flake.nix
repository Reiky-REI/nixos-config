{
  description = "MEOW configuration";
  nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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
      url = "github:catppuccin/nix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
                niri = pkgs-unstable.niri;
              })
              # waydroid .net 脚本 overlay（定义在 modules/virtualization.nix）
            ];
          })

          home-manager.nixosModules.home-manager
          {
            environment.systemPackages = [agenix.packages.${system}.default];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs pkgs-unstable;
              username = user.username;
              fullName = user.fullName;
            };
            home-manager.users.${user.username} = {
              imports = [
                catppuccin.homeModules.catppuccin
                agenix.homeManagerModules.default
                noctalia.homeModules.default
                ./home/${user.username}
              ];
              home.packages = [
                CookNixvim.packages.${system}.default
              ];
            };
          }
        ];
      };
    };
  };
}
