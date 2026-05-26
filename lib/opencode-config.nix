{flakeRoot}: let
  rootInstructions = [
    ".agents/AGENTS.md"
    ".agents/knowledge/INDEX.md"
    ".agents/knowledge/conventions.md"
  ];
  hostInstructions = [
    "../../.agents/AGENTS.md"
    "../../.agents/knowledge/INDEX.md"
    "../../.agents/knowledge/conventions.md"
  ];
  rootModel = "deepseek/deepseek-v4-flash";
  rootDefaultAgent = "plan";
  rootAgentPlanPrompt = ''
    开工前检查:
    1. git status → 确认工作区干净，无未提交变更
    2. git branch → 确认不在 main 上（须在 feature branch）
    3. 查看 retros/ → 了解进行中的任务，避免冲突
    4. 查 known-issues.md → 避免已知踩坑
    改完后:
    5. nixos-rebuild build --flake /etc/nixos#NixMEOW 验证
    6. 写复盘到 .agents/knowledge/retros/<date>-<topic>.md
    7. 用 commit.sh 提交 + 推送分支
  '';
in {
  inherit rootInstructions hostInstructions rootModel rootDefaultAgent rootAgentPlanPrompt;
}
