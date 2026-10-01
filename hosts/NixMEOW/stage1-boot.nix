# ===== 第一级启动菜单: 独立 GRUB (OS 选择器) =====
# 启动链: UEFI -> [MEOW Boot Menu (本模块构建的 GRUB)]
#                -> NixOS:   chainload /EFI/systemd/systemd-bootx64.efi (第二级: 选 NixOS 世代)
#                -> Windows: chainload /EFI/Microsoft/Boot/bootmgfw.efi
#
# 为什么自装 GRUB 而不是 boot.loader.grub:
#   NixOS 的 system.build.installBootLoader 是 types.unique (只允许一个引导器)喵,
#   与 systemd-boot 同时启用会 eval 冲突喵~ 所以第一级 GRUB 由本模块自行构建并部署,
#   systemd-boot 保持 NixOS 托管 (世代菜单照常更新)喵~
#
# 背景图与可复现性:
#   仓库内嵌 Catppuccin 官方背景 (MIT, 已加 50% 黑遮罩) 作兜底喵; 本机实际背景由
#   meow-stage1-background.service 在运行时生成两张写进 ESP:
#     boot-background-nixos.png   (Noctalia 当前壁纸)
#     boot-background-windows.png (Windows TranscodedWallpaper)
#   GRUB 按 grubenv 的 saved_entry 决定用哪张 ("上次启动的系统"的桌面壁纸)喵~
#   第三方壁纸一个字节都不进 git 喵~
#
# 设备事实 (host-local):
#   nvme0n1p1 = NixOS ESP   (vfat 75D8-3A38, 挂载 /boot)
#   nvme1n1p1 = Windows ESP (vfat 2630-98EC, /EFI/Microsoft/Boot/bootmgfw.efi)
{
  config,
  pkgs,
  username,
  ...
}: let
  grub = pkgs.grub2_efi;
  userHome = config.users.users.${username}.home;

  espMount = config.boot.loader.efi.efiSysMountPoint;
  espStageDir = "${espMount}/EFI/MEOW-OS";
  nixosEspUuid = "75D8-3A38";
  windowsEspUuid = "2630-98EC";
  nixosDiskByEui = "/dev/disk/by-id/nvme-eui.1849474406090001001b444a446f13ec";

  # Catppuccin Mocha 主题 (去掉居中 logo) + 三套 theme.txt:
  #   theme-stock.txt   -> 内嵌官方背景 (仓库兜底; 全新机器)
  #   theme-nixos.txt   -> ESP /EFI/MEOW-OS/boot-background-nixos.png
  #   theme-windows.txt -> ESP /EFI/MEOW-OS/boot-background-windows.png
  # 所有背景统一加 50% 黑遮罩, 保证浅色菜单文字的可读性
  themeText = desktopImage: ''
    # MEOW GRUB theme (Catppuccin Mocha based; logo removed; 50%-dimmed background)
    title-text: ""
    desktop-image: "${desktopImage}"
    desktop-image-scale-method: "stretch"
    desktop-color: "#1E1E2E"
    terminal-font: "Unifont Regular 16"
    terminal-left: "0"
    terminal-top: "0"
    terminal-width: "100%"
    terminal-height: "100%"
    terminal-border: "0"

    + boot_menu {
      left = 50%-320
      top = 50%
      width = 640
      height = 30%
      item_font = "Unifont Regular 28"
      item_color = "#CDD6F4"
      selected_item_color = "#CDD6F4"
      icon_width = 44
      icon_height = 44
      item_icon_space = 24
      item_height = 56
      item_padding = 5
      item_spacing = 14
      selected_item_pixmap_style = "select_*.png"
    }

    + label {
      top = 82%
      left = 30%
      width = 40%
      align = "center"
      id = "__timeout__"
      font = "Unifont Regular 28"
      text = "Booting in %d seconds"
      color = "#CDD6F4"
    }
  '';

  theme =
    pkgs.runCommand "meow-grub-theme" {
      nativeBuildInputs = [pkgs.imagemagick grub];
    } ''
      mkdir -p $out
      cp -r ${pkgs.catppuccin-grub}/. $out/
      chmod -R u+w $out
      rm -f $out/theme.txt $out/logo.png
      magick $out/background.png -fill black -colorize 50% -strip $out/background.png
      # 菜单/倒计时用 28px 大字体 (原主题字体只有 16px, 2.5K 屏上看不清)
      grub-mkfont -s 28 --no-bitmap -o $out/font-item.pf2 ${pkgs.unifont.otf}
      cp ${pkgs.writeText "meow-theme-stock.txt" (themeText "background.png")} $out/theme-stock.txt
      cp ${pkgs.writeText "meow-theme-nixos.txt" (themeText "/EFI/MEOW-OS/boot-background-nixos.png")} $out/theme-nixos.txt
      cp ${pkgs.writeText "meow-theme-windows.txt" (themeText "/EFI/MEOW-OS/boot-background-windows.png")} $out/theme-windows.txt
    '';

  # 第一级菜单 (内嵌进 EFI, 纯文本可审计)
  # 注意: GRUB 脚本不支持 `||`, 条件用 `if ! cmd ; then ... fi`
  menuCfg = pkgs.writeText "meow-stage1-grub.cfg" ''
    set timeout=5
    set timeout_style=menu

    insmod all_video
    insmod gfxterm
    insmod gfxmenu
    insmod png
    insmod font
    insmod loadenv
    insmod fat
    insmod part_gpt
    insmod chain
    insmod search_fs_uuid
    insmod test

    # 定位 NixOS ESP; UUID 匹配不上时退回按文件查找
    search --no-floppy --fs-uuid ${nixosEspUuid} --set=root
    if [ ! -e /EFI/systemd/systemd-bootx64.efi ]; then
      search --no-floppy --file /EFI/systemd/systemd-bootx64.efi --set=root
    fi

    # 记忆上次选择的系统 (grubenv 由 meow-stage1-boot.service 创建, rebuild 不重置)
    if [ -f /EFI/MEOW-OS/grubenv ]; then
      load_env -f /EFI/MEOW-OS/grubenv saved_entry
    fi
    if [ -z "$saved_entry" ]; then
      set saved_entry=meow-nixos
    fi
    set default="''${saved_entry}"

    # 主题: 默认内嵌兜底; 有运行期背景时按"上次启动的系统"切换壁纸
    set theme=(memdisk)/boot/grub/themes/meow/theme-stock.txt
    if [ -f /EFI/MEOW-OS/boot-background-nixos.png ]; then
      set theme=(memdisk)/boot/grub/themes/meow/theme-nixos.txt
    fi
    if [ "$saved_entry" = "meow-windows" ]; then
      if [ -f /EFI/MEOW-OS/boot-background-windows.png ]; then
        set theme=(memdisk)/boot/grub/themes/meow/theme-windows.txt
      fi
    fi

    # 字体加载失败时保持 console 菜单, 仅损失颜值
    # font.pf2 = 原主题 16px 字体 (terminal-font); font-item.pf2 = 28px 菜单字体
    if loadfont (memdisk)/boot/grub/themes/meow/font.pf2; then
      loadfont (memdisk)/boot/grub/themes/meow/font-item.pf2
      set gfxmode=2560x1600,1920x1200,1280x800,auto
      terminal_output gfxterm
    fi

    menuentry "NixOS" --class nixos --id=meow-nixos {
      if ! search --no-floppy --fs-uuid ${nixosEspUuid} --set=root ; then
        search --no-floppy --file /EFI/systemd/systemd-bootx64.efi --set=root
      fi
      saved_entry="''${chosen}"
      save_env -f /EFI/MEOW-OS/grubenv saved_entry
      chainloader /EFI/systemd/systemd-bootx64.efi
    }

    menuentry "Windows" --class windows11 --class windows --id=meow-windows {
      if ! search --no-floppy --fs-uuid ${nixosEspUuid} --set=root ; then
        search --no-floppy --file /EFI/systemd/systemd-bootx64.efi --set=root
      fi
      saved_entry="''${chosen}"
      save_env -f /EFI/MEOW-OS/grubenv saved_entry
      if ! search --no-floppy --fs-uuid ${windowsEspUuid} --set=root ; then
        search --no-floppy --file /EFI/Microsoft/Boot/bootmgfw.efi --set=root
      fi
      chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
  '';

  # 单文件 EFI: 配置 + 全部模块 + 主题 (含图标/字体) 内嵌进 memdisk
  stage1Efi =
    pkgs.runCommand "meow-stage1-grubx64.efi" {
      nativeBuildInputs = [grub];
    } ''
      cd ${theme}
      args=()
      while IFS= read -r -d ''' f; do
        rel=''${f#./}
        args+=("boot/grub/themes/meow/$rel=$PWD/$rel")
      done < <(find . -type f -print0)

      grub-mkstandalone \
        --format=x86_64-efi \
        --output="$out" \
        --themes= --fonts= --locales= \
        "boot/grub/grub.cfg=${menuCfg}" \
        "''${args[@]}"
    '';
in {
  # 经 systemd-boot builder 拷进 ESP (每次 switch 自动刷新, 原子替换整个镜像)
  boot.loader.systemd-boot.extraFiles = {
    "EFI/MEOW-OS/grubx64.efi" = stage1Efi;
  };

  # grubenv 初始化 + UEFI 启动项注册: best-effort, 失败不影响启动/切换
  systemd.services.meow-stage1-boot = {
    description = "MEOW stage-1 GRUB: ensure grubenv and UEFI boot entry";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    unitConfig.RequiresMountsFor = espMount;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    startLimitIntervalSec = 0;
    path = [pkgs.coreutils pkgs.efibootmgr pkgs.gawk pkgs.gnugrep pkgs.gnused grub];
    script = ''
      set -u
      ESP_DIR=${espStageDir}
      LABEL='MEOW Boot Menu'
      LOADER='\EFI\MEOW-OS\grubx64.efi'

      if [ ! -f "$ESP_DIR/grubx64.efi" ]; then
        echo "meow-stage1-boot: stage-1 image missing, skip" >&2
        exit 0
      fi

      # grubenv 只在缺失时创建, 保留"上次选择的系统"记忆
      if [ ! -s "$ESP_DIR/grubenv" ]; then
        grub-editenv "$ESP_DIR/grubenv" create || echo "meow-stage1-boot: grub-editenv create failed" >&2
        grub-editenv "$ESP_DIR/grubenv" set saved_entry=meow-nixos || true
      fi

      DISK="$(readlink -f ${nixosDiskByEui} 2>/dev/null)"
      if [ -z "$DISK" ]; then
        echo "meow-stage1-boot: cannot resolve NixOS disk" >&2
        exit 0
      fi

      out="$(LANG=C efibootmgr 2>/dev/null)"
      if [ -z "$out" ]; then
        echo "meow-stage1-boot: efibootmgr unavailable" >&2
        exit 0
      fi

      find_num() {
        printf '%s\n' "$1" | awk -v l="$LABEL" '
          /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/ {
            n = $1
            sub(/^Boot/, "", n)
            sub(/\*.*$/, "", n)
            if (index($0, l) > 0) {
              print n
              exit
            }
          }'
      }

      num="$(find_num "$out")"
      if [ -z "$num" ]; then
        LANG=C efibootmgr -q -c -d "$DISK" -p 1 -L "$LABEL" -l "$LOADER" >/dev/null 2>&1 || true
        out="$(LANG=C efibootmgr 2>/dev/null)"
        num="$(find_num "$out")"
      fi

      if [ -z "$num" ]; then
        echo "meow-stage1-boot: failed to register UEFI entry" >&2
        exit 0
      fi

      order="$(printf '%s\n' "$out" | sed -n 's/^BootOrder:[[:space:]]*//p' | tr -d ' \r')"
      [ -n "$order" ] || order="$num"
      new="$num"
      IFS=','
      for x in $order; do
        [ -z "$x" ] && continue
        [ "$x" = "$num" ] && continue
        new="$new,$x"
      done
      unset IFS
      if [ "$new" != "$order" ]; then
        LANG=C efibootmgr -q -o "$new" >/dev/null 2>&1 || echo "meow-stage1-boot: failed to reorder BootOrder" >&2
      fi
    '';
  };

  # 运行期背景注入: 两张背景写进 ESP (第三方图不进 git)
  #   boot-background-nixos.png   = 覆盖文件 > Noctalia 当前壁纸
  #   boot-background-windows.png = Windows TranscodedWallpaper > 缓存图 > 图片目录最新
  # 统一 50% 黑遮罩保证文字可读; GRUB 按 grubenv saved_entry 选对应主题
  systemd.services.meow-stage1-background = {
    description = "MEOW stage-1 GRUB: refresh NixOS/Windows wallpaper backgrounds";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    unitConfig.RequiresMountsFor = espMount;
    serviceConfig = {
      Type = "oneshot";
    };
    startLimitIntervalSec = 0;
    path = [pkgs.coreutils pkgs.imagemagick pkgs.jq pkgs.file pkgs.findutils pkgs.gnugrep pkgs.gnused];
    script = ''
      set -u
      STAGE_DIR=${espStageDir}
      OVERRIDE=${userHome}/.config/meow-boot/background
      NOCTALIA=${userHome}/.cache/noctalia/wallpapers.json
      WIN_HOME=/mnt/windows/Users/reiky
      STATE_DIR=/var/lib/meow-stage1-background
      mkdir -p "$STATE_DIR"

      # 居中裁剪 2560x1600 + 50% 黑遮罩 + 去 alpha; 指纹未变则跳过
      prepare() {
        p_src="$1"
        p_dst="$2"
        p_fp="$3"
        [ -f "$p_src" ] || return 0
        p_stamp="$STATE_DIR/$(basename "$p_dst").fingerprint"
        if [ -f "$p_dst" ] && [ -f "$p_stamp" ] && [ "$(cat "$p_stamp")" = "$p_fp" ]; then
          return 0
        fi
        p_tmp="$(mktemp /var/tmp/meow-stage1-bg.XXXXXX.png)" || return 0
        if magick "$p_src" -auto-orient -resize '2560x1600^' -gravity center -extent 2560x1600 -fill black -colorize 50% -strip "PNG24:$p_tmp" 2>/dev/null; then
          install -D -m 0644 "$p_tmp" "$p_dst" && printf '%s' "$p_fp" > "$p_stamp"
        else
          echo "meow-stage1-background: conversion failed: $p_src" >&2
        fi
        rm -f "$p_tmp"
      }

      # ---- NixOS 侧: 覆盖文件 > Noctalia 当前壁纸 ----
      src=""
      if [ -e "$OVERRIDE" ]; then
        if [ -L "$OVERRIDE" ] || file -b --mime-type "$OVERRIDE" 2>/dev/null | grep -q '^image/'; then
          src="$(readlink -f "$OVERRIDE" 2>/dev/null)"
        elif [ -f "$OVERRIDE" ]; then
          src="$(head -n 1 "$OVERRIDE" 2>/dev/null | tr -d '\r')"
        fi
      fi
      if [ -z "$src" ] && [ -f "$NOCTALIA" ]; then
        src="$(jq -r '.wallpapers["eDP-1"].dark // .wallpapers["eDP-1"].light // (.wallpapers | to_entries | map(.value.dark // .value.light) | map(select(. != null)) | first) // .defaultWallpaper // empty' "$NOCTALIA" 2>/dev/null)"
      fi
      if [ -n "$src" ] && [ -f "$src" ]; then
        prepare "$src" "$STAGE_DIR/boot-background-nixos.png" "nixos|v2|$src|$(stat -c '%s|%Y' "$src" 2>/dev/null)"
      else
        echo "meow-stage1-background: no usable NixOS wallpaper" >&2
      fi

      # ---- Windows 侧: 只读挂载, 访问时按需 automount ----
      win_src="$WIN_HOME/AppData/Roaming/Microsoft/Windows/Themes/TranscodedWallpaper"
      if [ ! -f "$win_src" ]; then
        win_src="$(find "$WIN_HOME/AppData/Roaming/Microsoft/Windows/Themes/CachedFiles" "$WIN_HOME/Pictures/desktop_background" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2-)"
      fi
      if [ -n "$win_src" ] && [ -f "$win_src" ]; then
        prepare "$win_src" "$STAGE_DIR/boot-background-windows.png" "windows|v2|$win_src|$(stat -c '%s|%Y' "$win_src" 2>/dev/null)"
      else
        echo "meow-stage1-background: no usable Windows wallpaper" >&2
      fi

      # 清理旧版单背景文件
      rm -f "$STAGE_DIR/boot-background.png"
    '';
  };

  # 壁纸/指定文件变化时即时刷新 (无须等下次开机)
  systemd.paths.meow-stage1-background = {
    wantedBy = ["multi-user.target"];
    startLimitIntervalSec = 0;
    pathConfig = {
      PathChanged = [
        "${userHome}/.cache/noctalia"
        "${userHome}/.cache/noctalia/wallpapers.json"
        "${userHome}/.config/meow-boot"
        "${userHome}/.config/meow-boot/background"
      ];
    };
  };
}
