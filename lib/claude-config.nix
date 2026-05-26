# Claude Code 配置中心
# 与 lib/opencode-config.nix 对应，管理 Claude Code 项目级设置。
# 通过 generate-claude.sh 生成 .claude/settings.json。
#
# OpenCode 对应: opencode.json 的 instructions / agent / permission
# Claude 特有: hooks 自动化（OpenCode 无此机制）
{ flakeRoot, username }:
let
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
    # 开工流程（等效 OpenCode 的 agent.plan.prompt + default_agent）
    startupWorkflow = ''
      ## 开工流程

      1. **读入口** — 先读 `.agents/AGENTS.md` `.agents/knowledge/INDEX.md` `.agents/knowledge/conventions.md`
      2. **Plan mode** — 修改配置前先进入 Plan mode 设计方案
      3. **查已知问题** — 遇到报错先查 `.agents/knowledge/known-issues.md`
      4. **改完验证** — `nixos-rebuild build --flake /etc/nixos#NixMEOW`
      5. **写复盘** — 配置变更完成后写复盘到 `.agents/knowledge/retros/`
    '';

    # 双 AI 对齐规则（CLAUDE.md 中引用 AGENTS.md，此处强调 Claude 特有规则）
    alignmentRules = ''
      ## 与 OpenCode 的对齐规则

      - 代码约定完全一致：以 `.agents/` 下的约定为准
      - Git 工作流一致：feature branch → build 验证 → 提交 → 推送 → 复盘
      - **Claude 特有**：利用 hooks 自动同步配置（pre-commit 触发 `just generate-claude`）
      - **Claude 特有**：利用持久化记忆跨会话保持上下文
      - 经验教训共享：发现的新坑同时更新到 `known-issues.md`
    '';
  };
}
