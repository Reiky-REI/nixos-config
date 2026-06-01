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
  desktopEntry = name: desktopName: categories: mimeType: ''
    [Desktop Entry]
    Categories=${categories}
    Exec=env QT_SCALE_FACTOR=${wpsScale} QT_AUTO_SCREEN_SCALE_FACTOR=0 ${name} %F
    Icon=${name}
    MimeType=${mimeType}
    Name=${desktopName}
    Terminal=false
    Type=Application
    Version=1.5
  '';
in {
  home.packages = with pkgs; [
    obsidian
    kdePackages.dolphin
    wpsoffice-cn
  ];

  home.file = lib.mkMerge [
    (lib.mapAttrs' (name: drv:
      lib.nameValuePair ".local/bin/${name}" {
        source = "${drv}/bin/${name}";
        executable = true;
      }
    ) {
      wps = wpsWrapperDerivation "wps";
      wpp = wpsWrapperDerivation "wpp";
      et = wpsWrapperDerivation "et";
      wpspdf = wpsWrapperDerivation "wpspdf";
    })
    {
      ".local/share/applications/wps-office-wps.desktop".text = desktopEntry "wps" "WPS Writer" "Office;WordProcessor" "application/wps-office-wps";
      ".local/share/applications/wps-office-wpp.desktop".text = desktopEntry "wpp" "WPS Presentation" "Office;Presentation" "application/wps-office-wpp";
      ".local/share/applications/wps-office-et.desktop".text = desktopEntry "et" "WPS Spreadsheet" "Office;Spreadsheet" "application/wps-office-et";
      ".local/share/applications/wps-office-pdf.desktop".text = desktopEntry "wpspdf" "WPS PDF" "Office;Viewer" "application/pdf";
    }
  ];

  home.activation.setupWpsHiDPI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WPSCONF="${config.home.homeDirectory}/.config/Kingsoft/Office.conf"
    if [ -f "$WPSCONF" ]; then
      sed -i 's/SlideShowPresenterNotesFontSize=20/SlideShowPresenterNotesFontSize=30/g' "$WPSCONF"
      sed -i 's/ZoomOfFirstView=130/ZoomOfFirstView=175/g' "$WPSCONF"
      sed -i 's/PortraitOrientationZoomOfFirstView=120/PortraitOrientationZoomOfFirstView=175/g' "$WPSCONF"
      sed -i 's/LandscapeOrientationZoomOfFirstView=150/LandscapeOrientationZoomOfFirstView=175/g' "$WPSCONF"
      sed -i 's/PreviewZoom=100/PreviewZoom=175/g' "$WPSCONF"
      sed -i 's/ReadingZoom=100/ReadingZoom=175/g' "$WPSCONF"
      sed -i 's/OfdPreviewZoom=100/OfdPreviewZoom=175/g' "$WPSCONF"
    fi
  '';
}
