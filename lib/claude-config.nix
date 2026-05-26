# Claude Code 配置中心
# 与 lib/opencode-config.nix 对应，管理 Claude Code 项目级设置。
# 通过 generate-claude.sh 生成 .claude/settings.json。
#
# OpenCode 对应: opencode.json 的 instructions / agent / permission
# Claude 特有: hooks 自动化（OpenCode 无此机制）
{
  flakeRoot,
  username,
}: let
  inherit (builtins) readFile;
in {
  # ===== settings.json 内容（项目级，提交到仓库）=====
  settings = {
    # 开工引导（等效 OpenCode 的 agent.plan.prompt）
    # 写入 CLAUDE.md 而非 settings.json，因为 CLAUDE.md 始终在 context 中
    # 见 claudeMdSections.startupWorkflow

    # 权限白名单（等效 OpenCode permission.allow）
    permissions = {
      allow = [
        "Bash(git *)"
        "Bash(nixos-rebuild build *)"
        "Bash(nix eval *)"
        "Bash(ls *)"
        "Bash(find *)"
        "Bash(grep *)"
        "Bash(cat *)"
        "Bash(mkdir *)"
        "Bash(touch *)"
        "Bash(cp *)"
        "Bash(mv *)"
      ];
    };

    # hooks 已废弃。复盘提醒由 justfile 的 rebuild recipe 内置，
    # git commit 前同步配置由 .git/hooks/pre-commit 负责。
  };

  # ===== CLAUDE.md 中由 Nix 管理的内容片段 =====
  claudeMdSections = {
    # 开机强制流程（等效 OpenCode 的 instructions: [AGENTS.md, INDEX.md, conventions.md]）
    startupWorkflow = ''
      ## ⚠️ 开机强制流程 — 每次会话先执行，不可跳过

      加载以下文件到 context，全部读完再开工：

      1. **AGENTS.md** → .agents/AGENTS.md — 总纪律、协作规则、Git 工作流
      2. **INDEX.md** → .agents/knowledge/INDEX.md — 全部知识索引 & 复盘列表
      3. **conventions.md** → .agents/knowledge/conventions.md — 编码约定 & 分层规则
      4. **known-issues.md** → .agents/knowledge/known-issues.md — 已知问题 & 避坑
      5. **architecture.md** → .agents/knowledge/architecture.md — 仓库架构

      按需加载：
      - 遇到报错时查 known-issues.md（如已加载则复用）
      - 管理密钥时读 secrets.md
      - 需要操作流程时读 SKILLS.md → 对应技能文件

      > 等同于 OpenCode 的 instructions: [AGENTS.md, INDEX.md, conventions.md]。
      > 不加载直接开工 → 不熟悉仓库 → 必然踩坑。
    '';

    # 工作流（Plan mode → build → retro）
    workflow = ''
      ## 工作流

      1. **Plan mode** — 修改配置前先进入 Plan mode 设计方案
      2. **查已知问题** — 遇到报错先查 .agents/knowledge/known-issues.md
      3. **改完验证** — nixos-rebuild build --flake /etc/nixos#NixMEOW
      4. **写复盘** — 配置变更完成后写复盘到 .agents/knowledge/retros/
    '';

    # 双 AI 对齐规则
    alignmentRules = ''
      ## 与 OpenCode 的对齐规则

      - 代码约定完全一致：以 .agents/ 下的约定为准
      - Git 工作流一致：feature branch → build 验证 → 提交 → 推送 → 复盘
      - **Claude 特有**：利用持久化记忆跨会话保持上下文
      - 经验教训共享：发现的新坑同时更新到 known-issues.md
    '';
  };
}
