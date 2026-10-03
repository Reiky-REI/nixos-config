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
  # 26.05 默认内核 6.18.42 + WiFi 固件 20260605 组合下 mt7921e 与小米 AP
  # 关联不稳 (associate 后链路掉, NM 反复 association took too long)。
  # 实际内核由 kernel-715 特性提供: lib/mk-host.nix 用 nixpkgs-715 pin (7.1.5) 以
  # lib.mkForce 覆盖此处 (7.1.6 有 amdgpu 闪烁回归, 故钉 7.1.5)喵~
  # 本行仅作 fallback (kernel-715 关闭时生效), 取 6.12 LTS 规避 6.18 的 WiFi 回归。
  # 注意: nixpkgs 26.05 无 linuxPackages_lts; 根 nixpkgs 升到 2026-10-02 后
  # linuxPackages_7_1 已 EOL 被移除, 故不再引用该属性。
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # NixMEOW CPU is AMD; keep vendor microcode host-local rather than enabling Intel microcode globally.
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;

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
