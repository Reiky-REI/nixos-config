# 编码约定

## Nix 格式
- 使用 `alejandra` 自动格式化，不手动纠结缩进/逗号风格
- 提交前运行 `just fmt` 或 `just check-fmt` 预览
- 函数参数按字母顺序排序: `config, lib, pkgs, ...`
- `{ ... }: {` 左大括号留空格（alejandra 会自动处理）
- import 路径使用相对路径 (从使用文件出发)

## 模块命名
- 目录下 default.nix 作为入口
- 文件名小写 + 连字符: `fcitx5.nix`, `go-musicfox.nix`
- 与 NixOS 选项名一致: `mdp.nix` → `mpd.nix` 因为选项是 `services.mpd`

## 分层规则
- 系统层模块只放 NixOS options (`services.*`, `programs.*`, `hardware.*`, `boot.*` 等)
- home-manager options (`home.packages`, `home.file`, `programs.waybar` 等) 放在 home 层
- `environment.sessionVariables` 按语义拆分到对应模块

## 用户标识集中管理
- 用户名及相关标识统一在仓库根目录 `config.nix` 中定义
- NixOS 模块通过 `specialArgs` 接收 `username` 和 `fullName` 参数
- home-manager 模块通过 `extraSpecialArgs` 接收
- 新增/删改用户时只需修改 `config.nix`，所有模块自动引用新值
- 详见 `architecture.md` 中的变量传递路径

## 环境变量归类
- `NIXOS_OZONE_WL` → desktop
- `QT_IM_MODULE` / `XMODIFIERS` → desktop/fcitx5 (输入法)
- `TERMINAL` → home (用户偏好)
- `XDG_DATA_DIRS` (flatpak) → services

## Git 工作流 (多 AI 协作)
- 提交信息语言不限，与仓库历史风格一致即可
- 每次验证通过后提交一个步骤
- **始终在 feature branch 上工作**，禁止直接在 main 上修改
- 开工前执行 `git status` + `git branch` 确认工作区干净
- **复盘先写再提交**: 配置变更完成后先写复盘，复盘和代码在同一个 commit 里
- **OpenCode 提交**使用 `.agents/config/commit.sh`（bot 身份）
- **Claude Code 提交**用 `git -c user.name="claude-code[bot]" -c user.email="claude-code[bot]@users.noreply.github.com" commit`（bot 身份）
- 提交并验证通过后，**自己合并回 main**（除非标注需要 review）
- **合并后立即删分支**: `git branch -d <分支名>` + `git push origin --delete <分支名>`

## 复盘格式
复盘强制使用以下 frontmatter 格式（AI 写复盘时自动生成）：

```yaml
---
date: YYYY-MM-DD
module: 改动的文件路径
tags: [标签1, 标签2]
layer: common          # 架构层级：common/hardware/desktop/networking/services/home
severity: low          # 影响程度：low/medium/high/critical
related:
  - ../retros/关联复盘.md (关联原因)
  - ../../known-issues.md (相关章节)
experience:
  - "可复用的经验或教训"
---
```

- `module`: 主要改动路径，如 `modules/common/default.nix`
- `tags`: 便于搜索，如 `性能`, `build`, `niri`, `noctalia`, `nix-config`
- `layer`: 所属架构层级，便于按层筛选复盘
- `severity`: 影响程度，快速识别高风险变更
- `related`: 手动关联相关复盘、已知问题、决策记录。AI 写复盘时顺手加
- `experience`: 可复用的经验或教训，长期积累后可聚合成技能
- 轻量级变更（一行改动/git typo）不写复盘

## AI 工作流约定
- 开工前先读 INDEX.md → 按上下文加载指南逐步加载知识
- 遇到报错先查 known-issues.md
- 非平凡变更必须写复盘，复盘和代码在同一 commit
- 复盘使用上述 frontmatter 格式填写所有字段
- 提交用 bot 身份（见上方 git 工作流）
- 完成任务后检查是否有新坑需追加到 known-issues.md
- **喵~规则**: 见 AGENTS.md `## 🐱 喵~规则`，AI 输出自然语言时强制遵守喵~ **Plan mode 同样适用**，不豁免喵~

## 多 AI 协作规范
- 两个 AI 都遵守 `.agents/` 下的全部约定
- 修改复杂配置前先读 `known-issues.md` 避免踩坑
- 新知识及时补充到对应知识文件或 `known-issues.md`
- 仅非平凡变更才写复盘到 `knowledge/retros/`
