---
date: 2026-09-20
module: .opencode/plugins/edit-backup.js, home/Reiky-REI/tools/opencode.nix, ~/.config/opencode/opencode.jsonc
tags: [opencode, permission, 备份, 插件, 自动化]
layer: home
severity: medium
related:
  - ../conventions.md (打包归属/多 AI 协作)
  - 2026-08-14-fix-kbdlight-ly-brightness.md (flake 只跟踪 git 文件, 新文件必须先 git add)
experience:
  - "opencode 默认 external_directory=ask 是外部目录反复弹授权的根因, 不是 bash 规则; 放开全目录访问要显式设 external_directory"
  - "放权必须先给安全网: tool.execute.before 钩子在 edit/write/patch 前快照旧文件到 ~/.local/state/opencode-edit-backups/<date>/<绝对路径>, 30 天保留"
  - "插件放 .opencode/plugins (项目级) + HM home.file 软链到 ~/.config/opencode/plugins (全局), 一处维护两处生效"
---

# opencode 免授权 + 改文件自动快照

## 背景
用户反馈 opencode 频繁要求授权（"每次都没法睡觉"）喵~ 明确要求：只要确保有文件备份，就直接放开所有文件夹的访问权限喵~

## 诊断
`~/.config/opencode/opencode.jsonc` 里只配了 `permission.bash`（`git push: ask`），而 opencode **默认 `external_directory = ask`** —— 凡触碰工作目录之外的路径（`/tmp`、`~/WorkSpace`、`~/.config` 等）都会弹一次授权，这才是真正的弹窗来源喵~

## 改动
1. **权限放开**（live config）：`external_directory: { "*": "allow" }`、`doom_loop/edit/webfetch/websearch = allow`、`bash.* = allow` + `git push = allow`；保留 `git push --force` 与 `rm -rf /` 的 `deny`（静默拦截，不产生弹窗）喵~
2. **安全网（新增）**：`.opencode/plugins/edit-backup.js` —— `tool.execute.before` 钩子在 `edit/write/patch` 前把已存在文件的旧内容快照到 `~/.local/state/opencode-edit-backups/<YYYY-MM-DD>/<原绝对路径>`，保留 30 天喵~ 新文件无需备份；独立进程实测可正确落盘喵~
3. **声明式全局化**：`.opencode/package.json` 加 `"type": "module"`；HM `home.file.".config/opencode/plugins/edit-backup.js".source` 指向仓库内同一文件，项目级与全局共用一份源码喵~
4. `.agents/knowledge/conventions.md` 新增「打包归属」小节：nixpkgs 没有的包一律回收到 Reiky-nixpkgs 私源，禁止 npm/curl 长期驻留喵~

## 生效方式
opencode 启动时读取配置与插件 → **重启 opencode 会话**后生效喵~
