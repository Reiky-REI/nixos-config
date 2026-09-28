{
  description = "AstrBot AI Bot Framework - Nix Flake wrapper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # AstrBot venv 和数据目录路径（用户级，不进 nix store）

      # libstdc++ 等运行时库路径
      libPath = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib   # libstdc++.so.6
        pkgs.zlib
        pkgs.libGL
        pkgs.glib
        pkgs.nss
        pkgs.nspr
        pkgs.cairo
        pkgs.pango
        pkgs.gdk-pixbuf
        pkgs.gtk3
        pkgs.openssl
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gst-plugins-base
      ];

      # 轻量运行时包装器：不依赖 bubblewrap，不需要 user namespace
      # 只是设置好 LD_LIBRARY_PATH 然后 exec venv 的 astrbot
      astrbot-wrapped = pkgs.writeShellScriptBin "astrbot" ''
        export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        astrabot_root="''${ASTRBOT_ROOT:-$HOME/WorkSpace/astrabot}"
        export NAPCAT_WORKDIR="$astrabot_root"
        cd "$astrabot_root"
        exec "$astrabot_root/.venv/bin/astrbot" "$@"
      '';
    in
    {
      packages.${system} = {
        default = astrbot-wrapped;
        astrbot = astrbot-wrapped;
      };

      apps.${system}.default = {
        type = "app";
        program = "${astrbot-wrapped}/bin/astrbot";
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ astrbot-wrapped ];
        shellHook = ''
          echo "AstrBot NixOS wrapper ready. Run: astrbot run"
        '';
      };
    };
}
