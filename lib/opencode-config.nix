{ flakeRoot }:
let
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
  rootAgentPlanPrompt = "先查看.agents文件夹内容";
in {
  inherit rootInstructions hostInstructions rootModel rootDefaultAgent rootAgentPlanPrompt;
}
