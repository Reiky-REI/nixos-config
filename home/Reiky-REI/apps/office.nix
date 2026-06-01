{config, pkgs, lib, ...}: {
  home.packages = with pkgs; [
    obsidian
    kdePackages.dolphin
    wpsoffice-cn
  ];

  # === WPS HiDPI 修复 (2x 缩放) ===

  # L1: 注入 DPI 配置到 WPS 原生配置文件
  home.activation.setupWpsHiDPI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WPSCONF="${config.home.homeDirectory}/.config/Kingsoft/Office.conf"
    mkdir -p "${config.home.homeDirectory}/.config/Kingsoft"
    if [ ! -f "$WPSCONF" ]; then
      printf '[6.0]\ncommon\\useSystemDpi=1\n' > "$WPSCONF"
    elif ! grep -q 'common\\useSystemDpi' "$WPSCONF" 2>/dev/null; then
      if ! grep -q '^\[6\.0\]' "$WPSCONF" 2>/dev/null; then
        printf '\n[6.0]\ncommon\\useSystemDpi=1\n' >> "$WPSCONF"
      else
        sed -i '/^\[6\.0\]/acommon\\useSystemDpi=1' "$WPSCONF"
      fi
    fi
  '';

  # L2: 覆盖 .desktop 文件，启动时注入 QT_SCALE_FACTOR=2
  xdg.desktopEntries = {
    "wps-office-wps" = {
      name = "WPS Writer";
      exec = "env QT_SCALE_FACTOR=2 QT_AUTO_SCREEN_SCALE_FACTOR=0 wps %F";
      icon = "wps-office-wps";
      type = "Application";
      categories = ["Office" "WordProcessor"];
      mimeType = ["application/wps-office-wps"];
    };
    "wps-office-wpp" = {
      name = "WPS Presentation";
      exec = "env QT_SCALE_FACTOR=2 QT_AUTO_SCREEN_SCALE_FACTOR=0 wpp %F";
      icon = "wps-office-wpp";
      type = "Application";
      categories = ["Office" "Presentation"];
      mimeType = ["application/wps-office-wpp"];
    };
    "wps-office-et" = {
      name = "WPS Spreadsheet";
      exec = "env QT_SCALE_FACTOR=2 QT_AUTO_SCREEN_SCALE_FACTOR=0 et %F";
      icon = "wps-office-et";
      type = "Application";
      categories = ["Office" "Spreadsheet"];
      mimeType = ["application/wps-office-et"];
    };
    "wps-office-pdf" = {
      name = "WPS PDF";
      exec = "env QT_SCALE_FACTOR=2 QT_AUTO_SCREEN_SCALE_FACTOR=0 wpspdf %F";
      icon = "wps-office-pdf";
      type = "Application";
      categories = ["Office" "Viewer"];
      mimeType = ["application/pdf"];
    };
  };

  # L3: 演讲备注字体 20 → 30 (1.5x)
  home.activation.setupWpsNotesFont = lib.hm.dag.entryAfter ["setupWpsHiDPI"] ''
    WPSCONF="${config.home.homeDirectory}/.config/Kingsoft/Office.conf"
    if [ -f "$WPSCONF" ]; then
      sed -i 's/SlideShowPresenterNotesFontSize=20/SlideShowPresenterNotesFontSize=30/g' "$WPSCONF"
    fi
  '';
}
