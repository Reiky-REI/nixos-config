{config, pkgs, lib, ...}: let
  wpsScale = "2";
  # 包装脚本包: 注入 QT_SCALE_FACTOR 后调用原始 WPS
  wpsWrapper = name: (pkgs.writeShellScriptBin name ''
    export QT_SCALE_FACTOR=${wpsScale}
    export QT_AUTO_SCREEN_SCALE_FACTOR=0
    exec ${pkgs.wpsoffice-cn}/bin/${name} "$@"
  '').overrideAttrs (old: {
    name = "${name}-hidpi-wrapper";
  });
  wpsWrapperDerivation = name: (wpsWrapper name);
in {
  home.packages = with pkgs; [
    obsidian
    kdePackages.dolphin
    wpsoffice-cn
  ];

  home.file = lib.mapAttrs' (name: drv:
    lib.nameValuePair ".local/bin/${name}" {
      source = "${drv}/bin/${name}";
      executable = true;
    }
  ) {
    wps = wpsWrapperDerivation "wps";
    wpp = wpsWrapperDerivation "wpp";
    et = wpsWrapperDerivation "et";
    wpspdf = wpsWrapperDerivation "wpspdf";
  };

  home.activation.setupWpsNotesFont = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WPSCONF="${config.home.homeDirectory}/.config/Kingsoft/Office.conf"
    if [ -f "$WPSCONF" ]; then
      sed -i 's/SlideShowPresenterNotesFontSize=20/SlideShowPresenterNotesFontSize=30/g' "$WPSCONF"
    fi
  '';
}
