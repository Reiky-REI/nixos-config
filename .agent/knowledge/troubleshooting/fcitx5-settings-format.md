# Fcitx5 NixOS 模块的 settings 选项陷阱

## 现象
在 `i18n.inputMethod.fcitx5.settings` 中添加自定义 key 时报错:
```
The option `i18n.inputMethod.fcitx5.settings."Behavior/OverrideEnabled"' does not exist.
```

## 根因
NixOS fcitx5 模块的 `settings` 属性 **不是 freeform attrs** — 它有严格的类型定义，只接受预定义的 key path。

## 当前有效的 fcitx5 settings key

查看 nixpkgs 中 fcitx5 模块源码 (`nixos/modules/services/x11/fcitx5.nix`) 确定支持的 key。已知支持:
- `globalOptions.Behavior.*` — 行为设置
- `globalOptions.Hotkey.*` — 快捷键
- `addons.*` — 插件配置
- `inputMethod` (单独的选项)

## 哪些 key 不被支持

| Key | 状态 | 替代方案 |
|-----|------|----------|
| `Behavior/OverrideEnabled` | ❌ 不被 settings 类型接受 | 用 `home.activation` 写 profile 文件 |
| `Group/AppDefault/*` | ❌ | 同上 |
| Per-app IM state | ❌ | 用 `fcitx5-configtool` GUI 手动设置 |

## 正确的配置方式
```nix
# ✅ 有的 key: 放在 settings 里
i18n.inputMethod.fcitx5.settings = {
  globalOptions = {
    "Behavior" = { "PreeditEnabledByDefault" = "False"; };
    "Hotkey/TriggerKeys" = {"0" = "Super+space";};
    "Hotkey/EnumerateForwardForInputWindow" = {"0" = "Shift_L"; "1" = "Shift_R";};
  };
};

# ❌ 不要在 settings 里放不支持的 key
# "Group/AppDefault/0" = { ... };  # 会被模块拒绝
```

## Per-app 终端英文怎么实现
- 默认 IM 已是 `keyboard-us`(英文)
- `Hotkey/EnumerateForwardForInputWindow` = Shift_L / Shift_R → 左右 Shift 切换
- 终端打开就是英文，需要中文时按 Shift 切换
- 如果需要 per-app 永久记忆: 用 `fcitx5-configtool` GUI 设置后自动保存到 `~/.config/fcitx5/profile`

## 教训
1. Fcitx5 NixOS 模块的 `settings` 类型严格，**不能随便加字段**
2. 先查 nixpkgs 源码确认 key 是否存在
3. 终端默认英文 = 默认 IM 排 keyboard-us 第一 + Shift 切换
