# tablet.nix — GAOMON 156 PRO 数位屏配置
# 数位笔映射在 niri base.kdl 中 (input { tablet { map-to-output } })
# 本模块负责: hwdb 按键重映射 + udev 权限
#
# 设备信息 (来自 /proc/bus/input/devices):
#   Vendor: 256c  Product: 006d  (Huion OEM → GAOMON)
#   - Pad (event8):       Express Keys 快捷键 (BTN_0 ~ BTN_9)
#   - Touch Strip (event9): 触控条
#   - Dial (event10):     旋钮
#   - Stylus (event28):   笔身按钮 (BTN_STYLUS / BTN_STYLUS2)
#
# 修改按键映射:
#   1. 用 `sudo evtest /dev/input/event8` 录制每个按键的 scan code
#   2. 修改下方 hwdb 条目中的 KEYBOARD_KEY_ 行
#   3. sudo nixos-rebuild switch --flake /etc/nixos
#   4. 可能需要重新插拔 USB 才生效
#
# hwdb scan code 格式说明:
#   KEYBOARD_KEY_<hex_scan_code>=<linux_key_name>
#   - scan code: evtest 输出的 code 字段 (十进制转十六进制)
#   - key name: /usr/include/linux/input-event-codes.h 中的名称 (小写)
#     常用: z(撤销), c(复制), v(粘贴), s(保存), space(空格/平移),
#           1-9(工具切换), f(全屏), esc(取消)
#   - 复合键不支持直接映射, 需用 xdotool/脚本

{ pkgs, ... }:

{
  # hwdb: 将 Pad 按键重映射为自定义键码
  # 匹配规则: Bus=0003 Vendor=256c Product=006d (所有固件版本)
  services.udev.extraHwdb = ''
    evdev:input:b0003v256cp006d*
     # === GAOMON 156 PRO Express Keys ===
     # 按键编号从左到右、从上到下 (以数位屏正面为准)
     # 默认映射为常用绘画快捷键, 根据个人习惯修改
     #
     # BTN_0 (最上): 撤销
     KEYBOARD_KEY_100=s
     # BTN_1: 保存
     KEYBOARD_KEY_101=ctrl
     # BTN_2: 缩放适配
     KEYBOARD_KEY_102=f
     # BTN_3: 切换笔刷
     KEYBOARD_KEY_103=b
     # BTN_4: 橡皮擦
     KEYBOARD_KEY_104=e
     # BTN_5: 吸管/取色
     KEYBOARD_KEY_105=i
     # BTN_6: 画布旋转
     KEYBOARD_KEY_106=r
     # BTN_7: 撤销 (备用)
     KEYBOARD_KEY_107=z
     # BTN_8: 重做
     KEYBOARD_KEY_108=y
     # BTN_9 (最下): 全屏切换
     KEYBOARD_KEY_109=f11
  '';

  # udev 权限: 让 input 组可以读写数位屏设备
  services.udev.extraRules = ''
    # GAOMON 156 PRO (Huion OEM)
    SUBSYSTEM=="input", ATTRS{idVendor}=="256c", ATTRS{idProduct}=="006d", MODE="0660", GROUP="input"
  '';

  # xdotool: 复合键映射时需要 (如 Ctrl+Z)
  environment.systemPackages = with pkgs; [
    xdotool
    evtest    # 调试: sudo evtest /dev/input/event8
  ];

  # 确保 input 组存在
  users.groups.input = {};
}
