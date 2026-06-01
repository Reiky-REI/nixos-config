{config, pkgs, lib, ...}: let
  wpsScale = "1.75";
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

  home.activation.setupWpsHiDPI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WPSCONF="${config.home.homeDirectory}/.config/Kingsoft/Office.conf"
    if [ -f "$WPSCONF" ]; then
      # 演讲备注字体 20 → 30 (1.5x)
      sed -i 's/SlideShowPresenterNotesFontSize=20/SlideShowPresenterNotesFontSize=30/g' "$WPSCONF"
      # 文档默认缩放调至 175% (匹配 QT_SCALE_FACTOR=1.75)
      sed -i 's/ZoomOfFirstView=130/ZoomOfFirstView=175/g' "$WPSCONF"
      sed -i 's/PortraitOrientationZoomOfFirstView=120/PortraitOrientationZoomOfFirstView=175/g' "$WPSCONF"
      sed -i 's/LandscapeOrientationZoomOfFirstView=150/LandscapeOrientationZoomOfFirstView=175/g' "$WPSCONF"
      sed -i 's/PreviewZoom=100/PreviewZoom=175/g' "$WPSCONF"
      sed -i 's/ReadingZoom=100/ReadingZoom=175/g' "$WPSCONF"
      sed -i 's/OfdPreviewZoom=100/OfdPreviewZoom=175/g' "$WPSCONF"
    fi
  '';
}
