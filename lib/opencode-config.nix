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
in {
  inherit rootInstructions hostInstructions rootModel;
}
