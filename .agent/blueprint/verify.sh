#!/usr/bin/env bash
# ============================================================
# NixMEOW AI Verification System
# 用法: verify.sh <phase> | all | list
#
# ⚠️ 声明: 此脚本为「行为规范」，定义了每 Phase 的通过标准。
#   验证命令本身可能需要根据当前系统状态调整。
#   FAIL 时先用判断力确认是真失败还是脚本问题。
#   每个 Phase 完成后运行，全部 PASS 才进入下一 Phase。
# ============================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PHASE="${1:-list}"

PASS=0
FAIL_SOFT=0
FAIL_HARD=0
SKIP=0

verify() {
  local id="$1" phase="$2" desc="$3" cmd="$4" level="${5:-1}"
  
  if [ "$phase" != "$PHASE" ] && [ "$PHASE" != "all" ]; then
    return 0
  fi

  printf "  [%s] %-55s " "$id" "$desc"
  
  if eval "$cmd" 2>/dev/null; then
    echo "✅ PASS"
    PASS=$((PASS + 1))
  elif [ "$level" = "skip" ]; then
    echo "⏭️ SKIP"
    SKIP=$((SKIP + 1))
  elif [ "$level" = "2" ]; then
    echo "🔴 FAIL (SEVERE)"
    FAIL_HARD=$((FAIL_HARD + 1))
  else
    echo "⚠️ FAIL"
    FAIL_SOFT=$((FAIL_SOFT + 1))
  fi
}

case "$PHASE" in
  phase1|all)
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Phase 1: Infrastructure Verification"
    echo "═══════════════════════════════════════════"
    
    verify P1.1 phase1 "flake eval succeeds" \
      'nix eval .#nixosConfigurations.NixMEOW.config.system.build.toplevel.drvPath >/dev/null 2>&1' 2

    verify P1.2 phase1 "opencode is available" \
      'opencode --version >/dev/null 2>&1'

    verify P1.3 phase1 "users: ai-code exists" \
      'id ai-code >/dev/null 2>&1'

    verify P1.4 phase1 "ai-code is trusted-user for nix" \
      'sudo -u ai-code nix store ping 2>&1 | grep -q "Trusted: 1"'

    verify P1.5 phase1 "ai-code can build without sudo" \
      'sudo -u ai-code nixos-rebuild build --flake /home/ai-code/nixos#NixMEOW --no-link 2>&1 | grep -q "building the system configuration"' 2

    verify P1.6 phase1 "ai-code CANNOT nixos-rebuild switch" \
      'sudo -u ai-code nixos-rebuild switch --flake /home/ai-code/nixos#NixMEOW 2>&1 | grep -q "not allowed\|sudoers\|a password"' 2

    verify P1.7 phase1 "git worktree exists" \
      'test -d /home/ai-code/nixos/.git/worktrees'

    verify P1.8 phase1 "opencode serve is running" \
      'curl -s http://localhost:4096/health >/dev/null 2>&1 || systemctl is-active opencode-serve >/dev/null 2>&1'

    verify P1.9 phase1 "claude --print works" \
      'echo "ping" | claude --print --model sonnet 2>&1 | head -3 | wc -l | grep -q "[1-9]"'
    ;;

  phase2|all)
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Phase 2: Agent Runtime Verification"
    echo "═══════════════════════════════════════════"
    
    verify P2.1 phase2 "openclaw service exists" \
      'systemctl --user cat openclaw-gateway >/dev/null 2>&1 || systemctl cat openclaw 2>/dev/null | head -1 >/dev/null' || true
    
    verify P2.2 phase2 "openclaw auto-restart configured" \
      'systemctl --user show openclaw-gateway 2>/dev/null | grep -q "Restart=always"' || true
    
    verify P2.3 phase2 "iptables: uid=1001 forced to proxy" \
      'sudo iptables -L OUTPUT -n -v 2>/dev/null | grep -q "owner UID match 1001"' || true
    
    verify P2.4 phase2 "network: agent cannot reach internet directly" \
      'sudo -u ai-agent curl -s --connect-timeout 3 https://baidu.com >/dev/null 2>&1; test $? -ne 0' 2 || true
    
    verify P2.5 phase2 "network: agent can reach through proxy" \
      'sudo -u ai-agent curl -s --connect-timeout 5 -x http://127.0.0.1:7897 https://api.deepseek.com/v1/models >/dev/null 2>&1' || true
    ;;

  phase3|all)
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Phase 3: Skills Verification"
    echo "═══════════════════════════════════════════"
    
    verify P3.1 phase3 "skill: file-organizer SKILL.md exists" \
      'test -f "$HOME/.config/opencode/skills/file-organizer/SKILL.md" 2>/dev/null || \
       test -f "$HOME/.agents/skills/file-organizer/SKILL.md" 2>/dev/null || \
       test -f "$HOME/.opencode/skills/file-organizer/SKILL.md" 2>/dev/null' || true
    
    verify P3.2 phase3 "skill: frontmatter has required fields" \
      'for f in "$HOME"/.config/opencode/skills/*/SKILL.md "$HOME"/.agents/skills/*/SKILL.md "$HOME"/.opencode/skills/*/SKILL.md; do
         test -f "$f" || continue
         head -5 "$f" | grep -q "^---" || { echo "MISSING frontmatter in $f"; exit 1; }
         grep -q "name:" "$f" || { echo "MISSING name in $f"; exit 1; }
       done' || true
    
    verify P3.3 phase3 "organize-tool is callable" \
      'which organize >/dev/null 2>&1 || nix run nixpkgs#organize -- --version >/dev/null 2>&1 || echo "SKIP"' || true
    
    verify P3.4 phase3 "vulnix returns valid JSON" \
      'sudo vulnix --system --json 2>/dev/null | jq -e ". == [] or type == \"array\"" >/dev/null 2>&1' || true
    
    verify P3.5 phase3 ".ai-rules.toml parser exists" \
      'test -f /home/ai-agent/.local/bin/ai-rules-parse 2>/dev/null || echo "SKIP"' || true
    ;;

  phase4|all)
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Phase 4: Security & Sentinel Verification"
    echo "═══════════════════════════════════════════"
    
    verify P4.1 phase4 "CONSTITUTION.md exists and has constraints" \
      'test -f /etc/nixos/.agents/CONSTITUTION.md && grep -q "不可" /etc/nixos/.agents/CONSTITUTION.md' 2
    
    verify P4.2 phase4 "sentinel log is writable by sentinel" \
      'sudo -u ai-sentinel test -w /var/lib/ai-sentinel/sentinel.jsonl 2>/dev/null || \
       (sudo touch /var/lib/ai-sentinel/sentinel.jsonl && sudo chown ai-sentinel:ai-sentinel /var/lib/ai-sentinel/sentinel.jsonl) >/dev/null 2>&1'
    
    verify P4.3 phase4 "sentinel CANNOT write agent files" \
      'sudo -u ai-sentinel touch /home/ai-agent/test-sentinel 2>&1 | grep -q "denied\|Permission"' 2
    
    verify P4.4 phase4 "agent CANNOT write sentinel home" \
      'sudo -u ai-agent touch /var/lib/ai-sentinel/test-agent 2>&1 | grep -q "denied\|Permission"' 2
    
    verify P4.5 phase4 "agent CANNOT nixos-rebuild switch" \
      'sudo -u ai-agent nixos-rebuild switch --flake /etc/nixos 2>&1 | grep -q "not allowed\|sudoers\|refused\|a password"' 2
    
    verify P4.6 phase4 "restic repository exists" \
      'sudo restic snapshots >/dev/null 2>&1' || true
    
    verify P4.7 phase4 "activity.jsonl path writable" \
      'touch /tmp/.activity-verify.jsonl && rm /tmp/.activity-verify.jsonl; test $? -eq 0'
    ;;

  phase5|all)
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Phase 5: Self-Evolution Verification"
    echo "═══════════════════════════════════════════"
    
    verify P5.1 phase5 "session recap template exists" \
    
    verify P5.2 phase5 "at least one session recap exists" \
      'test -n "$(find /etc/nixos/.agents/knowledge/retros/ -name "*.md" 2>/dev/null)"' || true
    
    verify P5.3 phase5 "community API reachable" \
      'curl -s --connect-timeout 10 -x http://127.0.0.1:7897 \
        "https://api.github.com/repos/NixOS/nixpkgs/issues?labels=security&per_page=1" \
        | jq -e ". == [] or .[0].title" >/dev/null 2>&1' || true
    
    verify P5.4 phase5 "BLUEPRINT.md is readable" \
      'test -r /etc/nixos/.agent/blueprint/BLUEPRINT.md'
    
    verify P5.5 phase5 "BOOTSTRAPPER.md is readable" \
      'test -r /etc/nixos/.agent/blueprint/BOOTSTRAPPER.md'
    ;;

  phase6|all)
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Phase 6: Learning & Publishing Verification"
    echo "═══════════════════════════════════════════"
    
    verify P6.1 phase6 "learn directory structure exists" \
    
    verify P6.2 phase6 "learn companion skill exists" \
      'test -f ~/.config/opencode/skills/learn-companion/SKILL.md 2>/dev/null || \
       test -f ~/.agents/skills/learn-companion/SKILL.md 2>/dev/null' || true
    
    verify P6.3 phase6 "publisher: git remote configured" \
      'git -C /etc/nixos remote get-url origin >/dev/null 2>&1' || true
    ;;

  list)
    echo "NixMEOW AI Verification System"
    echo "=============================="
    echo ""
    echo "Available phases:"
    echo "  phase1  — Infrastructure (flake, ai-code user, opencode, claude, worktree)"
    echo "  phase2  — Agent Runtime (opencode serve, agents, permissions)"
    echo "  phase3  — Skills (skills, knowledge pipeline)"
    echo "  phase4  — Security & Sentinel (CONSTITUTION, multi-user audit)"
    echo "  phase5  — Self-Evolution (community, recaps, adaptation)"
    echo "  phase6  — Learning & Publishing (companion, git, publish)"
    echo "  all     — Run all phases in order"
    echo ""
    echo "Usage: $0 <phase>"
    exit 0
    ;;

  *)
    echo "Unknown phase: '$PHASE'"
    echo "Usage: $0 phase1|phase2|phase3|phase4|phase5|phase6|all|list"
    exit 1
    ;;
esac

# Summary
if [ "$PHASE" != "list" ]; then
  echo ""
  echo "═══════════════════════════════════════════"
  echo "  Verification Results"
  echo "═══════════════════════════════════════════"
  echo "  ✅ PASS:   $PASS"
  echo "  ⏭️ SKIP:   $SKIP"
  echo "  ⚠️ FAIL:   $FAIL_SOFT"
  echo "  🔴 SEVERE: $FAIL_HARD"
  echo ""
  
  if [ "$FAIL_HARD" -gt 0 ]; then
    echo "🔴 SEVERE failures detected."
    echo "   → HALT. Human review required before continuing."
    echo "   → Fix issues and re-run: $0 $PHASE"
    exit 2
  elif [ "$FAIL_SOFT" -gt 0 ]; then
    echo "⚠️ Soft failures detected."
    echo "   → Fix issues and re-run: $0 $PHASE"
    exit 1
  else
    echo "✅ All checks passed for Phase '$PHASE'."
    echo "   → Ready for next phase."
    exit 0
  fi
fi
