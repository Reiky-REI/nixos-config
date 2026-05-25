#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)
cd "$ROOT"

echo "Reading config from Nix..."
ROOT_INSTRUCTIONS=$(nix eval .#opencodeConfig.rootInstructions --json)
HOST_INSTRUCTIONS=$(nix eval .#opencodeConfig.hostInstructions --json)
ROOT_MODEL=$(nix eval .#opencodeConfig.rootModel --json)
ROOT_DEFAULT_AGENT=$(nix eval .#opencodeConfig.rootDefaultAgent --json)
ROOT_AGENT_PLAN_PROMPT=$(nix eval .#opencodeConfig.rootAgentPlanPrompt --json)

patch_json() {
    local file="$1"
    local instructions_json="$2"
    local model="$3"
    local default_agent="$4"
    local plan_prompt="$5"
    python3 -c "
import json
with open('$file') as f:
    cfg = json.load(f)
cfg['instructions'] = $instructions_json
if '$model':
    cfg['model'] = '$model'
if '$default_agent':
    cfg['default_agent'] = '$default_agent'
if '$plan_prompt':
    cfg.setdefault('agent', {})
    cfg['agent'].setdefault('plan', {})
    cfg['agent']['plan']['prompt'] = '$plan_prompt'
with open('$file', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
"
    echo "  patched $file"
}

echo "Patching root config..."
patch_json "opencode.json" "$ROOT_INSTRUCTIONS" "$ROOT_MODEL" "$ROOT_DEFAULT_AGENT" "$ROOT_AGENT_PLAN_PROMPT"

echo "Patching host config..."
patch_json "hosts/MEOW/opencode.json" "$HOST_INSTRUCTIONS" "" "" ""

echo "Done."
