---
date: 2026-10-08
type: delete-manifest
target: home/reiky/apps/splayer-settings.json
sha256: acae855e00d0cdb9db3aa75de417e89af2ded0dfafcc6cd4cc30af2778bd63fd
size_bytes: 1387
status: deleted
---

# 删除清单: SPlayer 孤儿设置文件 (2026-10-08)

## 对象

| 项 | 值 |
|----|----|
| 路径 | `home/reiky/apps/splayer-settings.json` |
| 大小 | 1387 字节 |
| SHA256 | `acae855e00d0cdb9db3aa75de417e89af2ded0dfafcc6cd4cc30af2778bd63fd` |
| 位置 | `feat/waydroid-aixue` 工作区的 **untracked 副本**（不在 git 索引中） |

## 判定依据

- 该文件内容与提交 `5c5b5f1`（waydroid 接入 + SPlayer 卸载）**删除前**的 blob
  （`5c5b5f1^:home/reiky/apps/splayer-settings.json`）逐字节相同，SHA256 一致喵
- SPlayer 已于 2026-10-07 卸载，`home/reiky/apps/runtime-configs.nix` 的
  `mergeSPlayerSettings` 一并移除；该副本是提交之后在工作区被意外重建的孤儿喵
- 内容在 git 历史（`5c5b5f1^`）中仍完整保留，可随时用
  `git show 5c5b5f1^:home/reiky/apps/splayer-settings.json` 取回喵

## 影响范围

- 仅删除 `feat/waydroid-aixue` 工作区的 untracked 副本，使 `git status` 干净喵
- **不影响 `main`**：main 仍启用 SPlayer，`home/reiky/apps/splayer-settings.json` 在 main 上仍被
  `runtime-configs.nix` 引用；本清单不涉及对 main 该跟踪文件的删除喵
- 待 `feat/waydroid-aixue` 合入 main 时，该文件随 `5c5b5f1` 一并从 main 移除喵

## 原始内容

````json
{
  "window": {
    "useBorderless": true,
    "maximized": false
  },
  "lyric": {
    "config": {
      "isLock": false,
      "playedColor": "#fe7971",
      "unplayedColor": "#ccc",
      "shadowColor": "rgba(0, 0, 0, 0.5)",
      "fontFamily": "system-ui",
      "fontSize": 24,
      "fontWeight": 400,
      "showTran": true,
      "showYrc": true,
      "isDoubleLine": true,
      "position": "both",
      "limitBounds": false,
      "textBackgroundMask": false,
      "backgroundMaskColor": "rgba(0, 0, 0, 0.5)",
      "alwaysShowPlayInfo": false,
      "animation": true
    }
  },
  "taskbarLyric": {
    "position": "auto",
    "autoMaxWidth": true,
    "maxWidth": 400,
    "colorMode": "taskbar",
    "doubleLine": true,
    "showTranslation": true,
    "showCover": true,
    "wordByWord": true,
    "fontSize": 14,
    "fontFamily": ""
  },
  "macos": {
    "statusBarLyric": {
      "enabled": false
    }
  },
  "proxy": "",
  "amllDbServer": "https://amlldb.bikonoo.com/ncm-lyrics/%s.ttml",
  "cacheLimit": 10,
  "websocket": {
    "enabled": false,
    "port": 25885
  },
  "downloadThreadCount": 8,
  "enableDownloadHttp2": true,
  "taskbar": {
    "enabled": false,
    "maxWidth": 30,
    "showCover": true,
    "position": "automatic",
    "showWhenPaused": true,
    "autoShrink": false,
    "margin": 10,
    "minWidth": 10
  },
  "updateChannel": "stable"
}
````
