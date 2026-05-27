# 复盘: 2026-05-27 安装 evtest + 工作流改进 + 权限修复

## 背景
用户需要安装 `evtest`（输入事件调试工具），同时改进 Git 工作流（完成 feature 后自动合回 main + 删除分支），以及修复用户对自己 home 配置目录的写权限。

## 变更内容

| 类型 | 文件 | 说明 |
|------|------|------|
| feat | `home/Reiky-REI/tools/essentials.nix` | 添加 `pkgs.evtest` 到 home.packages |
| doc | `.agents/AGENTS.md` | Git 工作流：第4条改为合回main，新增第5条merge后删分支，原第5条顺延 |
| doc | `.agents/knowledge/conventions.md` | 第40行同步：自己合并+立即删分支 |
| ops | `/etc/nixos/home/Reiky-REI/` | 递归 chown 为 Reiky-REI:users，解决 sudo 编辑问题 |

## 新 Git 工作流
1. feature branch → 修改 → build 验证
2. **自己合回 main**（除非标注需要 review）
3. **合并后立即删分支**: `git branch -d <分支名>` + `git push origin --delete <分支名>`
4. 写复盘

## 注意
`.agents/` 目录仍为 root 所有，后续如有编辑权限问题需额外处理。
