#!/usr/bin/env bash
# nix-gcroot-audit — 揪出「僵尸引用链」并（可选）清理
#
# 背景 (2026-11-15): 8月17日一个降权进程在 `/` 下跑 nixos-rebuild build,
# nix 按约定写了 `/result` 软链; nix 又把每个 result 自动登记成 gcroot
# (/nix/var/nix/gcroots/auto/<hash> -> <result 路径>), 本意是"刚构建的产物别被 GC"喵~
# 副作用: 没人清理的 result 软链会永久钉住整个闭包 — 本机为此白留 21G 三周喵~
#
# 用法:
#   nix-gcroot-audit                 # 只读体检 (普通用户即可)
#   nix-gcroot-audit --sizes         # 附带非现役钉住统计
#   sudo nix-gcroot-audit --fix      # 清断头 gcroot + 超龄 result 软链, 再 GC
#        --max-age N                 # result 软链龄阈值, 默认 30 天
#        --quiet                     # 无问题时不输出 (cron/watchdog 用)
#
# 红线: 永不删世代; 永不删 /etc/nixos/result; 不碰未超龄 result喵~
set -uo pipefail

NIX_STORE_BIN="${NIX_STORE_BIN:-/run/current-system/sw/bin/nix-store}"
GCROOTS_AUTO="/nix/var/nix/gcroots/auto"
MAX_AGE_DAYS=30
MODE=preview
SIZES=0
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --fix) MODE=fix ;;
    --sizes) SIZES=1 ;;
    --quiet) QUIET=1 ;;
    --max-age) MAX_AGE_DAYS="${2:?需要天数}"; shift ;;
    -h | --help) head -n 21 "$0"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
  shift
done

FINDINGS=0
say() { [ "$QUIET" = 1 ] || echo "$@"; }
warn() { FINDINGS=$((FINDINGS + 1)); echo "$@"; }

DANGLING=()
RESULT_ROOTS=()
if [ -d "$GCROOTS_AUTO" ]; then
  for f in "$GCROOTS_AUTO"/*; do
    [ -L "$f" ] || continue
    target="$(readlink "$f" 2>/dev/null)" || continue
    if [ ! -e "$target" ]; then
      DANGLING+=("$f|$target")
      continue
    fi
    case "$target" in
      */result | */result-*) RESULT_ROOTS+=("$f|$target") ;;
    esac
  done
fi

if [ ${#DANGLING[@]} -gt 0 ]; then
  warn "⚠ 断头 gcroot ${#DANGLING[@]} 条 (目标已不存在, 纯记录垃圾):"
  for e in "${DANGLING[@]}"; do
    warn "    ${e%%|*}  ->  ${e##*|}"
    [ "$MODE" = fix ] && { rm -f "${e%%|*}" 2>/dev/null || sudo rm -f "${e%%|*}" 2>/dev/null; }
  done
fi

NOW=$(date +%s)
for e in "${RESULT_ROOTS[@]}"; do
  link="${e%%|*}"
  target="${e##*|}"
  case "$target" in */etc/nixos/result | /etc/nixos/result) continue ;; esac
  [ -e "$target" ] || continue
  mtime=$(stat -c %Y "$target" 2>/dev/null || echo "$NOW")
  age=$(( (NOW - mtime) / 86400 ))
  store="$(readlink -f "$target" 2>/dev/null)"
  if [ "$age" -ge "$MAX_AGE_DAYS" ]; then
    warn "⚠ 僵尸 result 软链 ${age} 天: ${target}  ->  ${store}"
    if [ "$MODE" = fix ]; then
      rm -f "$target" 2>/dev/null || sudo rm -f "$target" 2>/dev/null
      rm -f "$link" 2>/dev/null || sudo rm -f "$link" 2>/dev/null
      warn "    已删 (软链 + gcroot 登记)"
    fi
  else
    say "· 容忍期内 (${age} 天 < ${MAX_AGE_DAYS} 天): ${target}"
  fi
done

if [ "$SIZES" = 1 ]; then
  say ""
  say "== 现役 vs 全 store (路径数) =="
  HM="$(readlink -f "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)"
  { "$NIX_STORE_BIN" -qR /run/current-system 2>/dev/null
    [ -n "$HM" ] && [ -e "$HM" ] && "$NIX_STORE_BIN" -qR "$HM" 2>/dev/null
  } | sort -u > /tmp/.gcroot-live.$$
  ls -d /nix/store/* 2>/dev/null | sort > /tmp/.gcroot-all.$$
  LIVE=$(wc -l < /tmp/.gcroot-live.$$)
  ALL=$(wc -l < /tmp/.gcroot-all.$$)
  say "  现役: ${LIVE} 条 / store 顶层: ${ALL} 条 / 非现役: $((ALL - LIVE)) 条"
  rm -f /tmp/.gcroot-live.$$ /tmp/.gcroot-all.$$
fi

if [ "$MODE" = fix ]; then
  if [ "$FINDINGS" -gt 0 ]; then
    say ""
    say "== 执行 GC =="
    sudo "$NIX_STORE_BIN" --gc 2>&1 | tail -2
  else
    say "无僵尸引用, 未做任何改动"
  fi
elif [ "$FINDINGS" -eq 0 ]; then
  say "✅ 无断头 gcroot、无超龄 result 软链"
fi

[ "$FINDINGS" -eq 0 ]
