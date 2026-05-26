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
    opencodeConfig = import ./lib/opencode-config.nix { flakeRoot = self; };
  in {
    inherit opencodeConfig;
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
            age.identityPaths = [ "/home/${user.username}/.ssh/id_ed25519" ];
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
              # 修补 waydroid-net.sh 使用 nftables
              # (kernel 7.0.9 linuxPackages_latest 缺少 ip_tables.ko)
              (final: prev: {
                waydroid = prev.waydroid.overrideAttrs (old: {
                  preFixup = let
                    pkgs = prev;
                    inherit (pkgs) lib dnsmasq getent iproute2 iptables nftables
                      gawk kmod lxc util-linux wl-clipboard runtimeShell;
                  in ''
                    substituteInPlace $out/lib/waydroid/data/scripts/waydroid-net.sh \
                      --replace-fail 'LXC_USE_NFT="false"' 'LXC_USE_NFT="true"'

                    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")

                    patchShebangs --host $out/lib/waydroid/data/scripts
                    wrapProgram $out/lib/waydroid/data/scripts/waydroid-net.sh \
                      --prefix PATH ":" ${
                        lib.makeBinPath [
                          dnsmasq
                          getent
                          iproute2
                          iptables
                          nftables
                        ]
                      }

                    wrapPythonProgramsIn $out/lib/waydroid/ "${
                      lib.concatStringsSep " " (
                        [
                          "$out"
                        ]
                        ++ (old.propagatedBuildInputs or [])
                        ++ [
                          gawk
                          kmod
                          lxc
                          util-linux
                          wl-clipboard
                        ]
                      )
                    }"

                    substituteInPlace $out/lib/waydroid/tools/helpers/*.py \
                      --replace '"sh"' '"${runtimeShell}"'
                  '';
                });
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
