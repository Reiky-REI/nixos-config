{
  pkgs,
  config,
  ...
}: let
  # 通用解压脚本：自动检测格式，调用对应工具
  extract = pkgs.writeShellApplication {
    name = "extract";
    runtimeInputs = with pkgs; [
      unzip
      p7zip
      unrar
      gnutar
      gzip
      bzip2
      xz
      zstd
      file # 用于兜底检测文件类型
    ];
    text = ''
      set -euo pipefail

      if [ $# -eq 0 ]; then
        echo "用法: extract <压缩包> [目标目录]"
        exit 1
      fi

      FILE="$1"
      DEST="''${2:-.}"

      if [ ! -f "$FILE" ]; then
        echo "错误: 文件不存在: $FILE"
        exit 1
      fi

      mkdir -p "$DEST"

      case "$FILE" in
        *.zip)
          unzip -o "$FILE" -d "$DEST"
          ;;
        *.7z|*.7z.)
          7z x "$FILE" -o"$DEST"
          ;;
        *.rar)
          unrar x "$FILE" "$DEST"
          ;;
        *.tar)
          tar xf "$FILE" -C "$DEST"
          ;;
        *.tar.gz|*.tgz)
          tar xzf "$FILE" -C "$DEST"
          ;;
        *.tar.bz2|*.tbz2)
          tar xjf "$FILE" -C "$DEST"
          ;;
        *.tar.xz|*.txz)
          tar xJf "$FILE" -C "$DEST"
          ;;
        *.tar.zst|*.tzst)
          tar --zstd -xf "$FILE" -C "$DEST"
          ;;
        *.gz)
          gunzip -k "$FILE"
          ;;
        *.bz2)
          bunzip2 -k "$FILE"
          ;;
        *.xz)
          unxz -k "$FILE"
          ;;
        *.zst|*.zstd)
          zstd -d "$FILE" --force -o "$DEST/$(basename "$FILE" .zst)"
          ;;
        *)
          # 用 file 命令兜底检测
          TYPE=$(file -b --mime-type "$FILE")
          case "$TYPE" in
            application/zip)
              unzip -o "$FILE" -d "$DEST"
              ;;
            application/x-7z-compressed)
              7z x "$FILE" -o"$DEST"
              ;;
            application/x-rar)
              unrar x "$FILE" "$DEST"
              ;;
            application/gzip)
              gunzip -k "$FILE"
              ;;
            application/x-bzip2)
              bunzip2 -k "$FILE"
              ;;
            application/x-xz)
              unxz -k "$FILE"
              ;;
            application/zstd)
              zstd -d "$FILE" --force -o "$DEST/$(basename "$FILE" .zst)"
              ;;
            application/x-tar|application/x-compressed-tar|application/x-bzip-compressed-tar|application/x-xz-compressed-tar|application/x-tar+zstd)
              tar xf "$FILE" -C "$DEST"
              ;;
            *)
              echo "不支持的格式: $TYPE ($FILE)"
              exit 1
              ;;
          esac
          ;;
      esac

      echo "✅ 解压完成: $FILE → $DEST"
    '';
  };

  # 解压 .desktop 文件
  extractDesktop = pkgs.writeText "nyaa-extract.desktop" ''
    [Desktop Entry]
    Exec=${extract}/bin/extract %f
    MimeType=application/zip;application/x-7z-compressed;application/x-rar;application/gzip;application/x-bzip2;application/x-xz;application/zstd;application/x-tar;application/x-compressed-tar;application/x-bzip-compressed-tar;application/x-xz-compressed-tar;application/x-tar+zstd;
    Name=解压到当前目录
    NoDisplay=false
    Terminal=true
    TerminalOptions=--hold
    Type=Application
    Categories=Utility;
  '';
in {
  home.packages = [extract];

  # 注册为压缩包的默认打开方式
  xdg.mimeApps.defaultApplications = {
    "application/zip" = ["nyaa-extract.desktop"];
    "application/x-7z-compressed" = ["nyaa-extract.desktop"];
    "application/x-rar" = ["nyaa-extract.desktop"];
    "application/gzip" = ["nyaa-extract.desktop"];
    "application/x-bzip2" = ["nyaa-extract.desktop"];
    "application/x-xz" = ["nyaa-extract.desktop"];
    "application/zstd" = ["nyaa-extract.desktop"];
    "application/x-tar" = ["nyaa-extract.desktop"];
    "application/x-compressed-tar" = ["nyaa-extract.desktop"];
    "application/x-bzip-compressed-tar" = ["nyaa-extract.desktop"];
    "application/x-xz-compressed-tar" = ["nyaa-extract.desktop"];
    "application/x-tar+zstd" = ["nyaa-extract.desktop"];
  };

  # 放置 .desktop 文件
  xdg.dataFile."applications/nyaa-extract.desktop".source = extractDesktop;
}
