{
  config,
  pkgs,
  lib,
  ...
}: let
  # ChromeOS zork 版 ndk_translation (Android 13, AMD 平台)
  ndkTranslation =
    pkgs.runCommand "waydroid-arm-translation" {
      src = pkgs.fetchurl {
        url = "https://github.com/supremegamers/vendor_google_proprietary_ndk_translation-prebuilt/archive/faece8cc787a520193545116501cad40534063fc.zip";
        sha256 = "235b31e75cd62fe18a6d11f4772df096c767d0d0252ef7eb7a2aeb56448ba915";
      };
      nativeBuildInputs = [pkgs.unzip];
    } ''
      unzip $src
      cd vendor_google_proprietary_ndk_translation-prebuilt-*
      mkdir -p $out
      cp -r prebuilts/* $out/
    '';
in {
  # waydroid-net.sh nftables 补丁 overlay
  # (kernel 7.0.9 linuxPackages_latest 缺少 ip_tables.ko)
  nixpkgs.overlays = [
    (final: prev: {
      waydroid = prev.waydroid.overrideAttrs (old: {
        preFixup = let
          pkgs = prev;
          inherit
            (pkgs)
            lib
            dnsmasq
            getent
            iproute2
            iptables
            nftables
            gawk
            kmod
            lxc
            util-linux
            wl-clipboard
            runtimeShell
            ;
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

  # 容器: podman (无守护进程, 更轻量; CLI 兼容 docker)
  virtualisation.podman = {
    enable = true;
    # 提供 docker CLI 兼容别名 (docker → podman)
    dockerCompat = true;
    # 提供 docker.sock (兼容依赖 docker socket 的工具)
    dockerSocket.enable = true;
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu = {
    runAsRoot = false;
    swtpm.enable = true;
    vhostUserPackages = [
      pkgs.virtiofsd
    ];
  };
  programs.virt-manager.enable = true;

  # waydroid
  virtualisation.waydroid.enable = true;

  environment.systemPackages = with pkgs; [
    waydroid-helper
    nftables
  ];

  boot.kernelModules = ["nf_tables"];

  # gbinder: waydroid 1.5.4 使用 aidl3, 覆盖 NixOS 默认的 aidl2
  # 否则 binder 协议不匹配导致 waydroidplatform 服务无法通信
  environment.etc."gbinder.d/waydroid.conf" = lib.mkForce {
    text = ''
      [Protocol]
      /dev/binder = aidl3
      /dev/vndbinder = aidl3
      /dev/hwbinder = hidl

      [ServiceManager]
      /dev/binder = aidl3
      /dev/vndbinder = aidl3
      /dev/hwbinder = hidl
    '';
  };

  # ARM 翻译层自动部署
  system.activationScripts.waydroid-arm-translation = lib.mkIf config.virtualisation.waydroid.enable (lib.mkAfter ''
        if [ -d /var/lib/waydroid ]; then
          mkdir -p /var/lib/waydroid/overlay/system

          FLAG="/var/lib/waydroid/.arm-translation-installed"
          if [ ! -f "$FLAG" ] || [ "$FLAG" -ot "${ndkTranslation}" ]; then
            echo "waydroid-arm-translation: 安装 ARM 翻译层到 overlay..."
            cp -rf ${ndkTranslation}/* /var/lib/waydroid/overlay/system/
            touch "$FLAG"
          fi

          PROPS="/var/lib/waydroid/waydroid_base.prop"
          if [ -f "$PROPS" ] && ! grep -q "ro.dalvik.vm.native.bridge" "$PROPS" 2>/dev/null; then
            echo "waydroid-arm-translation: 添加 Android 属性..."
            cat >> "$PROPS" << 'PROPEOF'
    ro.product.cpu.abilist=x86_64,arm64-v8a,x86,armeabi-v7a,armeabi
    ro.product.cpu.abilist32=x86,armeabi-v7a,armeabi
    ro.product.cpu.abilist64=x86_64,arm64-v8a
    ro.dalvik.vm.native.bridge=libndk_translation.so
    ro.enable.native.bridge.exec=1
    ro.vendor.enable.native.bridge.exec=1
    ro.vendor.enable.native.bridge.exec64=1
    ro.dalvik.vm.isa.arm=x86
    ro.dalvik.vm.isa.arm64=x86_64
    PROPEOF
          fi
        fi
  '');
}
