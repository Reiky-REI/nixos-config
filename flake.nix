{
  description = "NixMEOW AI-Native System — Blueprint";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.NixMEOW = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [];
    };
  };
}
