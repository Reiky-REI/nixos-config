{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
  ];

  boot.kernelParams = ["ahci.mobile_lpm_policy=1"];
  boot.kernelPackages = pkgs.linuxPackages;

  # COLORFIRE MEOW R16 键盘背光 (Clevo/Tongfang 模具, 用补丁版 tuxedo-drivers)
  # force_clevo_kb_backlight_type=6: 强制 1-zone RGB, 暴露 /sys/class/leds/rgb:kbdlight
  hardware.tuxedo-drivers.enable = true;
  boot.extraModprobeConfig = ''
    options tuxedo_keyboard force_clevo_kb_backlight_type=6
    options btusb enable_autosuspend=0 reset=1
    # MT7922 (mt7921e) 在 AMD 平台 ASPM 电源管理 bug, 长时间运行固件挂死
    # 表现为 driver own failed / chip reset failed, 禁用 ASPM 根治
    options mt7921e disable_aspm=Y
  '';
}
