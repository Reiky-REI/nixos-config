---
date: 2026-05-27
module: home/Reiky-REI/desktop/niri/config.kdl
tags: [niri, input, mouse, keyboard, 2.4g, debug]
related:
  - ../../knowledge/known-issues.md
---

# 复盘: 修复外置键鼠无法使用 — niri `mouse { off }`

## 发现经过

用户反馈外置鼠标和键盘（2.4G 无线）无法使用，仅内置键鼠正常。

通过 `libinput list-devices` 和 `dmesg` 排查发现：
- 内核正确识别所有外部设备（Microsoft 2.4GHz Transceiver、Hangsheng RK2.4G Dongle）
- `evtest` 确认内核事件正常发出
- 问题出在 niri compositor 层

## 根因

`home/Reiky-REI/desktop/niri/config.kdl` 中 `input.mouse` 区块设了 `off`：

```kdl
mouse {
    off         // ← 这行导致 niri 忽略所有指针设备
}
```

`mouse { off }` 让 niri 不处理任何被 libinput 归类为 pointer 的设备。这直接影响：
1. **外置鼠标**（Microsoft 2.4GHz Mouse、Hangsheng Dongle Mouse）— 被归类为 pointer
2. **部分外置键盘**（Hangsheng RK2.4G Dongle Keyboard）— 被 libinput 归类为 `keyboard pointer`，设备级拥有键盘+鼠标双重能力，`mouse { off }` 导致 niri 完全跳过该设备

内置触控板（`Capabilities: pointer gesture`）因走 `touchpad` 块不受影响，内置键盘（`Capabilities: keyboard`）单独配置也正常。

## 修复

删除 `mouse { off }` 一行，保留注释掉的配置选项以便将来按需启用。

## 推测：什么时间误关的

据用户反馈，应该是之前某次编辑 niri 配置时手误或为了解决某个问题（比如不小心碰到触摸板？）把 `mouse { off }` 加上了，之后外置键鼠就一直不能用。
