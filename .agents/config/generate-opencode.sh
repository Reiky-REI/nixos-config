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
    python3 -c "
import json, sys

file = sys.argv[1]
cfg_raw = json.loads(sys.argv[2])
model_raw = sys.argv[3]
agent_raw = sys.argv[4]
prompt_raw = sys.argv[5]

with open(file) as f:
    cfg = json.load(f)

cfg['instructions'] = cfg_raw
if model_raw:
    cfg['model'] = json.loads(model_raw)
if agent_raw:
    cfg['default_agent'] = json.loads(agent_raw)
if prompt_raw:
    cfg.setdefault('agent', {})
    cfg['agent'].setdefault('plan', {})
    cfg['agent']['plan']['prompt'] = json.loads(prompt_raw)

with open(file, 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
" "$file" "$2" "$3" "$4" "$5"
    echo "  patched $file"
}

echo "Patching root config..."
patch_json "opencode.json" "$ROOT_INSTRUCTIONS" "$ROOT_MODEL" "$ROOT_DEFAULT_AGENT" "$ROOT_AGENT_PLAN_PROMPT"

echo "Patching host config..."
patch_json "hosts/MEOW/opencode.json" "$HOST_INSTRUCTIONS" "" "" ""

echo "Done."
