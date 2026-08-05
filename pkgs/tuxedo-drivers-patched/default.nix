# tuxedo-drivers 补丁版: 修复 COLORFIRE MEOW R16 (Clevo/Tongfang 模具) 键盘背光
#
# 该模具固件误报键盘背光类型 (0x26), tuxedo_keyboard 驱动无法识别导致不注册 LED
# 补丁添加 force_clevo_kb_backlight_type 模块参数, 可强制为 1-zone RGB (值 6)
# 加载后暴露 /sys/class/leds/rgb:kbdlight, 支持亮度和 RGB 颜色控制
#
# 参考: github.com/JAmanOG/colorful-p15-keyboard-backlight
{
  lib,
  stdenv,
  fetchFromGitLab,
  kernel,
  kernelModuleMakeFlags,
  kmod,
  pahole,
  udevCheckHook,
  bash,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "tuxedo-drivers-${kernel.version}";
  version = "4.18.0";

  src = fetchFromGitLab {
    group = "tuxedocomputers";
    owner = "development/packages";
    repo = "tuxedo-drivers";
    rev = "v${finalAttrs.version}";
    hash = "sha256-9XtogovzAWaMkJI5CxszY5qO3q6NOACZ7pnejyobJlY=";
  };

  # 原 nixpkgs 补丁 (不复制 usr 到 /) + 键盘背光类型强制补丁
  patches = [
    ./no-cp-usr.patch
    ./kbdlight.patch
  ];

  postInstall = ''
    echo "Running postInstallhook"
    substituteInPlace usr/lib/udev/rules.d/* \
      --replace-quiet "/bin/bash" "${lib.getExe bash}" \
      --replace-quiet "/bin/sh" "${lib.getExe bash}"
    install -Dm 0644 -t $out/etc/udev/rules.d usr/lib/udev/rules.d/*
  '';

  buildInputs = [pahole];
  nativeBuildInputs =
    [
      kmod
      udevCheckHook
    ]
    ++ kernel.moduleBuildDependencies;

  makeFlags =
    kernelModuleMakeFlags
    ++ [
      "KERNELRELEASE=${kernel.modDirVersion}"
      "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "INSTALL_MOD_PATH=${placeholder "out"}"
    ];

  doInstallCheck = true;

  meta = {
    broken = stdenv.hostPlatform.isAarch64 || (lib.versionOlder kernel.version "5.5");
    description = "Keyboard and hardware I/O driver for TUXEDO Computers laptops (patched for COLORFIRE MEOW R16 kbd backlight)";
    homepage = "https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
