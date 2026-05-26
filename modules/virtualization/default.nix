{ config, pkgs, lib, ... }:

let
  # ChromeOS zork 版 ndk_translation (Android 13, AMD 平台)
  ndkTranslation = pkgs.runCommand "waydroid-arm-translation" {
    src = pkgs.fetchurl {
      url = "https://github.com/supremegamers/vendor_google_proprietary_ndk_translation-prebuilt/archive/faece8cc787a520193545116501cad40534063fc.zip";
      sha256 = "235b31e75cd62fe18a6d11f4772df096c767d0d0252ef7eb7a2aeb56448ba915";
    };
    nativeBuildInputs = [ pkgs.unzip ];
  } ''
    unzip $src
    cd vendor_google_proprietary_ndk_translation-prebuilt-*
    mkdir -p $out
    cp -r prebuilts/* $out/
  '';
in {
  # docker
  virtualisation.docker.enable = true;

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

  boot.kernelModules = [ "nf_tables" ];

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
