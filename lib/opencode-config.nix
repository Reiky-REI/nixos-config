{
  flakeRoot,
  agentsConfig,
}: let
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
  # 模型 / 默认 agent / plan 系统提示统一来自 agents.nix 注册表
  rootModel = agentsConfig.opencode.model;
  rootDefaultAgent = agentsConfig.opencode.defaultAgent;
  rootAgentPlanPrompt = agentsConfig.opencode.planSystem;
in {
  inherit rootInstructions hostInstructions rootModel rootDefaultAgent rootAgentPlanPrompt;
}
