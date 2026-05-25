#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)
cd "$ROOT"

echo "Reading instruction paths from Nix..."
ROOT_INSTRUCTIONS=$(nix eval .#opencodeConfig.rootInstructions --json)
HOST_INSTRUCTIONS=$(nix eval .#opencodeConfig.hostInstructions --json)

patch_json() {
    local file="$1"
    local instructions_json="$2"
    python3 -c "
import json
with open('$file') as f:
    cfg = json.load(f)
cfg['instructions'] = $instructions_json
with open('$file', 'w') as f:
    json.dump(cfg, f, indent=2)
    f.write('\n')
"
    echo "  patched $file"
}

echo "Patching root config..."
patch_json "opencode.json" "$ROOT_INSTRUCTIONS"

echo "Patching host config..."
patch_json "hosts/MEOW/opencode.json" "$HOST_INSTRUCTIONS"

echo "Done."
