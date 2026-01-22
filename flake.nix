{
  description = "Cook configuration";
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable"; # 只给 Noctalia 用
    };
    # nxivim配置完整版
    CookNixvim = {
      url = "github:Youthdreamer/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix/release-25.05";
    home-manager = {
      url = "github:nix-community/home-manager";
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
  in {
    nixosConfigurations = {
      cook = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs pkgs-unstable;
        };

        modules = [
          ./configuration.nix
          agenix.nixosModules.default
          catppuccin.nixosModules.catppuccin
          home-manager.nixosModules.home-manager
          {
            environment.systemPackages = [agenix.packages.${system}.default];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs pkgs-unstable;};
            home-manager.users.youth = {
              imports = [
                catppuccin.homeModules.catppuccin
                agenix.homeManagerModules.default
                noctalia.homeModules.default
                ./home/youth
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
