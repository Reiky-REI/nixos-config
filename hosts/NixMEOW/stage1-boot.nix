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
#   仓库内嵌 Catppuccin 官方背景 (MIT) 作兜底喵; 本机实际背景由
#   meow-stage1-background.service 在运行时从当前桌面壁纸生成后写入 ESP喵,
#   第三方壁纸一个字节都不进 git 喵~ 背景文件缺失时自动用内嵌官方版本喵~
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

  # Catppuccin Mocha 主题 + 两套 theme.txt:
  #   theme-stock.txt -> 内嵌官方背景 (仓库兜底; 全新机器/无运行时背景时使用)
  #   theme-esp.txt   -> ESP 运行时背景 /EFI/MEOW-OS/boot-background.png
  theme = pkgs.runCommand "meow-grub-theme" {} ''
    mkdir -p $out
    cp -r ${pkgs.catppuccin-grub}/. $out/
    chmod -R u+w $out
    cp $out/theme.txt $out/theme-stock.txt
    sed 's|desktop-image: "background.png"|desktop-image: "/EFI/MEOW-OS/boot-background.png"|' \
      $out/theme.txt > $out/theme-esp.txt
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

    # 有运行时背景用 ESP 版, 否则用内嵌官方背景
    if [ -f /EFI/MEOW-OS/boot-background.png ]; then
      set theme=(memdisk)/boot/grub/themes/meow/theme-esp.txt
    else
      set theme=(memdisk)/boot/grub/themes/meow/theme-stock.txt
    fi

    # 字体加载失败时保持 console 菜单, 仅损失颜值
    if loadfont (memdisk)/boot/grub/themes/meow/font.pf2; then
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

  # 运行期壁纸注入: 生成 GRUB 背景写进 ESP (第三方图不进 git)
  # 优先级: ~/.config/meow-boot/background (软链或一行路径) > Noctalia 当前壁纸
  systemd.services.meow-stage1-background = {
    description = "MEOW stage-1 GRUB: refresh wallpaper from current desktop wallpaper";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    unitConfig.RequiresMountsFor = espMount;
    serviceConfig = {
      Type = "oneshot";
    };
    startLimitIntervalSec = 0;
    path = [pkgs.coreutils pkgs.imagemagick pkgs.jq pkgs.file pkgs.gnugrep pkgs.gnused];
    script = ''
      set -u
      TARGET=${espStageDir}/boot-background.png
      OVERRIDE=${userHome}/.config/meow-boot/background
      NOCTALIA=${userHome}/.cache/noctalia/wallpapers.json
      STATE_DIR=/var/lib/meow-stage1-background
      mkdir -p "$STATE_DIR"

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
      if [ -z "$src" ] || [ ! -f "$src" ]; then
        echo "meow-stage1-background: no usable wallpaper; keeping existing GRUB background" >&2
        exit 0
      fi

      # 指纹未变且目标已存在时跳过, 避免每次开机重复写 ESP
      fp="v1|$src|$(stat -c '%s|%Y' "$src" 2>/dev/null)"
      if [ -f "$TARGET" ] && [ -f "$STATE_DIR/fingerprint" ] && [ "$(cat "$STATE_DIR/fingerprint")" = "$fp" ]; then
        exit 0
      fi

      tmp="$(mktemp /var/tmp/meow-stage1-bg.XXXXXX.png)" || exit 0
      trap 'rm -f "$tmp"' EXIT
      if magick "$src" -auto-orient -resize '2560x1600^' -gravity center -extent 2560x1600 -fill black -colorize 15% -strip "PNG24:$tmp" 2>/dev/null; then
        install -D -m 0644 "$tmp" "$TARGET" && printf '%s' "$fp" > "$STATE_DIR/fingerprint"
      else
        echo "meow-stage1-background: image conversion failed: $src" >&2
      fi
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
