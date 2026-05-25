# 复盘: Waydroid ARM 翻译层安装 (ndk_translation zork)

## 改动
- `modules/virtualization.nix`: 添加 ndkTranslation 包 (fetchurl + unzip) + activationScript 自动部署
- `home/Reiky-REI/desktop/niri/config.kdl`: 添加 `spawn-at-startup "waydroid" "session" "start"`

## 修复过程
1. 确认 APK 是纯 ARM64 (lib/arm64-v8a)，Waydroid 为 x86_64，需 ARM 翻译层
2. 初次安装 guybrush R119 ndk_translation → APK 安装成功但运行闪退
3. logcat 显示 `SIGSEGV at ndk_translation::AppProcessPostInit()+50`
4. 尝试 qwerty12356-wart 补丁 (AND 0xFA→0xFF)，但 guybrush 此 build 中无对应模式
5. 换 zork R125 (Android 13, 同样是 AMD 平台) → 正常安装+运行

## 坑
- waydroid-helper 的 patched 补丁基于特定 Ghidra 分析，Guybrush R119 build 不包含补丁要修改的指令
- 补丁偏移计算: `Ghidra_offset - 0x101000`，但文件大小仅 2.4MB，补丁期望 3MB+ 的文件
- activationScript 的 flag 文件条件判断需要留意: `[ ! -f "$FLAG" ] || [ "$FLAG" -ot "${storePath}" ]`，如果 flag 比 store path 新就不会重新拷贝

## 当前状态
- ✅ Maimemo (墨墨背单词) ARM64 APK 在 Waydroid 安装并运行成功
- ✅ binfmt_misc arm/arm64 处理器注册正常
- ✅ ndk_translation 通过 NixOS 配置持久化
- ✅ Waydroid session 配置了 Niri 自启 (下次登录生效)
