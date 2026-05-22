{
  description = "Cook configuration";
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    agenix.url = "github:ryantm/agenix";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # CookNxivim 配置完整版
    CookNixvim = {
      url = "github:Youthdreamer/CookNixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix/release-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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

          ({
            pkgs,
            lib,
            config,
            ...
          }: {
            nixpkgs.overlays = [
              #  (self: super: {
              #    # 方法1：使用 override 强制 qt6（如果支持）
              #    fcitx5-qt = super.fcitx5-qt.override {
              #      useQt6 = true;
              #      qt6 = super.qt6;
              #    };
              #  })
              (final: prev: {
                fcitx5 = prev.fcitx5.overrideAttrs (old: {
                  cmakeFlags = (old.cmakeFlags or []) ++ ["-DUSE_QT6=ON"];
                  buildInputs = (old.buildInputs or []) ++ [final.qt6.qtbase];
                  dontWrapQtApps = true;
                });
                fcitx5-rime = prev.fcitx5-rime.override {fcitx5 = final.fcitx5;};
                fcitx5-gtk = prev.fcitx5-gtk.override {fcitx5 = final.fcitx5;};
              })
            ];
          })

          home-manager.nixosModules.home-manager
          {
            environment.systemPackages = [agenix.packages.${system}.default];
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs pkgs-unstable;};
            home-manager.users.Reiky-REI = {
              imports = [
                catppuccin.homeModules.catppuccin
                agenix.homeManagerModules.default
                noctalia.homeModules.default
                ./home/Reiky-REI
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
