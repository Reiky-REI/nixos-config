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
in {
  inherit rootInstructions hostInstructions;
}
