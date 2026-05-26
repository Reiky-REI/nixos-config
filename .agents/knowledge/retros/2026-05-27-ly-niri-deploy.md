# 复盘: Ly 部署 + Niri session 修复

## 起因

合并 `feature/ly-theme` 后 Ly 出现三重问题：
1. Session 列表只有 xinitrc/shell，没有 Niri
2. 主题色显示白色（不生效）
3. Shell/xinitrc 密码进不去

## 根因 — `asterisk` 值非法导致配置文件整份被丢弃

### 直接原因

`modules/desktop/ly/settings.nix` 中：
```
asterisk = "q(>w<)p";
```

`asterisk` 字段只接受 **单个字符** 或 **UTF-32 编码点**（如 `0x2022`），`q(>w<)p` 是多字符字符串，Ly 无法解析。

### 连锁反应

Ly 日志 `/var/log/ly.log` 确认：

```
unable to parse config file: InvalidCharacter
failed to convert value 'q(>w<)p' of option 'asterisk'
  to type '?u32': InvalidCharacter
```

配置文件解析失败 → **NixOS 生成的整个 config.ini 被丢弃** → Ly 回退到编译期硬编码默认值：

| 问题 | 默认值导致 | 连锁后果 |
|------|-----------|---------|
| 🎨 主题色白色 | `bg=0x00000000`（终端默认色，你的终端背景白） | 颜色全部失效 |
| 🪟 无 Niri session | `waylandsessions=/usr/share/wayland-sessions`（不存在） | 只剩内置 xinitrc/shell |
| 🔑 Shell/xinitrc 进不去 | `setup_cmd=$CONFIG_DIRECTORY/ly/setup.sh`（不存在） | Session 启动失败立刻 `logged out` |
| 🔑 Xinitrc 额外卡住 | `xauth_cmd=$PREFIX_DIRECTORY/bin/xauth`（不存在） | xauth 失败 → XauthFailed |

### 为什么之前没发现

- `nixos-rebuild build` 只检查 Nix 求值，不会验证生成的文件内容
- 需要人工检查或者运行 `nix eval` 看 config.ini 输出
- Ly 的配置错误日志写 `/var/log/ly.log`，不打印到构建输出

## 本次改动

| 操作 | 文件 | 说明 |
|------|------|------|
| edit | `modules/desktop/ly/settings.nix` | `asterisk = "q(>w<)p"` → `"♥"`（U+2665） |
| build | — | `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅ |
| (下一步) switch | — | 用户执行 `nixos-rebuild switch` 或 reboot |

## 验证

- `nixos-rebuild build` ✅
- 新 config.ini 包含 `asterisk=♥` ✅
- 新 config.ini 包含全部颜色值和正确的 `waylandsessions` 路径 ✅

## 教训

1. **Ly 的配置很脆弱** — 任何字段值不合法就会丢弃整个配置文件，不留默认值
2. **构建通过不代表配置生效** — Nix 不验证生成文件的内容语义
3. **排查姿势** — Ly 问题先查 `/var/log/ly.log`
4. **以后加 Ly 配置要提交前确认**：新 config 内容是否正确
