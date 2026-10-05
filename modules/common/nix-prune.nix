# nix-prune-generations — 空间闸门式世代保留 (2026-10-05)
#
# 背景: 原配置 nix.gc = "--delete-older-than 3d" 让每日 GC 无条件删回滚点;
# 2026-10-04 17:31 一次人工 `--delete-generations old` + `nix-collect-garbage -d`
# 后 boot 菜单只剩一个世代、无法回滚 (复盘:
# .agents/knowledge/retros/2026-10-05-boot-generation-gc.md)。
#
# 策略: 「空间够就不删, 空间不够才收口」。世代本身近乎零成本 (store 共享),
# 是回滚保单, 宁可多留; 只在磁盘吃紧时按规则收口。
#
# 当前规则 (nix.pruneGenerations.* 可调):
#   剩余空间 ≥ minFree   → 什么都不删 (无论世代多少)
#   剩余空间 <  minFree   → 7 天内全留, 7 天外保留最新 keepOld 条, 其余删除
#
# 手动管理:
#   sudo nix-prune-generations      # 预览 (永不改盘)
#   sudo nix-prune-generations -y   # 空间闸门触发时按规则执行并 nix-store --gc
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.nix.pruneGenerations = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "提供 nix-prune-generations 工具 (空间闸门式世代保留) 喵";
    };
    minFree = lib.mkOption {
      type = lib.types.str;
      default = "15G";
      description = ''
        剩余可用空间低于该值才触发世代清理 (numfmt --from=iec 语义, 如 15G) 喵。
        世代不是意图清理的对象 — 它们是回滚保单; 这个阈值只决定磁盘吃紧时何时兜底喵。
      '';
    };
    keepSince = lib.mkOption {
      type = lib.types.str;
      default = "7 days";
      description = "该时间跨度内的世代无条件保留 (GNU date -d 语义, 如 ''7 days''; 注意不是 nix-env 的 7d 语法) 喵";
    };
    keepOld = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "keepSince 跨度之外的世代仍保留最新 N 条 (最远触达的回滚点数) 喵";
    };
  };

  config = lib.mkIf config.nix.pruneGenerations.enable {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "nix-prune-generations";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          gnused
          nix
        ];

        text = ''
          # nix option 注入
          MIN_FREE="${config.nix.pruneGenerations.minFree}"
          KEEP_SINCE="${config.nix.pruneGenerations.keepSince}"
          KEEP_OLD=${builtins.toString config.nix.pruneGenerations.keepOld}

          MODE="preview"
          for arg in "$@"; do
            case "$arg" in
              -y | --yes) MODE="apply" ;;
              -h | --help)
                echo "用法: nix-prune-generations [-y]"
                echo "  默认预览; -y 才执行 (且仅在剩余空间 < ''${MIN_FREE} 时会删世代) 喵"
                echo "  规则: ''${KEEP_SINCE} 内全留 + 更早的保留最新 ''${KEEP_OLD} 条; 永不删 current 世代"
                exit 0
                ;;
              *)
                echo "未知参数: $arg (用法: nix-prune-generations [-y])" >&2
                exit 2
                ;;
            esac
          done

          if [ "$(id -u)" -ne 0 ]; then
            echo "需要 root 才能管理 system profile: sudo nix-prune-generations" >&2
            exit 1
          fi

          PROFILES_ROOT="$(realpath /nix/var/nix/profiles)"
          FREE_BYTES=$(df --output=avail -B1 "$PROFILES_ROOT" | tail -1)
          MIN_FREE_BYTES=$(numfmt --from=iec "$MIN_FREE")
          CUTOFF=$(date -d "$KEEP_SINCE ago" +%s)

          echo "剩余空间: $(numfmt --to=iec "$FREE_BYTES") / 阈值: $(numfmt --to=iec "$MIN_FREE_BYTES") / 保留窗口: $KEEP_SINCE + 更早最新 $KEEP_OLD 条"

          if [ "$FREE_BYTES" -ge "$MIN_FREE_BYTES" ]; then
            echo "空间充足 → 保留全部世代, 本轮未做任何删除喵"
            exit 0
          fi

          # 世代 profile 清单: system + 通道 + 各用户 home profile
          # 悬空链接 (如历史 home-manager profile 被 -d 清掉) 不自动处理, 仅提示
          profile_list() {
            for p in \
              "$PROFILES_ROOT/system" \
              "$PROFILES_ROOT"/per-user/*/profile \
              "$PROFILES_ROOT"/per-user/*/channels \
              /home/*/.local/state/nix/profiles/profile \
              /home/*/.local/state/nix/profiles/home-manager; do
              if [ -L "$p" ]; then
                if [ -e "$p" ]; then
                  echo "$p"
                else
                  echo "⚠ 悬空 profile 链接 (不做自动处理): $p" >&2
                fi
              fi
            done
          }

          CHANGED=0
          for profile in $(profile_list); do
            total=$(nix-env -p "$profile" --list-generations 2>/dev/null | wc -l)
            # 输出 7 天窗口外的世代号 (current 世代永不进入删除集合)
            old_txt=$(nix-env -p "$profile" --list-generations 2>/dev/null |
              awk -v cutoff="$CUTOFF" '
                /\(current\)/ { next }
                {
                  ts = $2 " " $3;
                  cmd = "date -d \"" ts "\" +%s";
                  cmd | getline ts_epoch;
                  close(cmd);
                  if (ts_epoch + 0 >= cutoff + 0) next;
                  print $1;
                }')
            mapfile -t old_gens <<< "$old_txt"
            n_old=''${#old_gens[@]}

            if [ "$n_old" -le "$KEEP_OLD" ]; then
              echo "  [$profile] 共 $total 条, 窗口外 $n_old 条 ≤ 保单数 $KEEP_OLD → 无需清理喵"
            elif [ "$n_old" -gt "$KEEP_OLD" ]; then
              del_count=$((n_old - KEEP_OLD))
              mapfile -t del_gens < <(printf '%s\n' "''${old_gens[@]:0:$del_count}")
              echo "  [$profile] 共 $total 条, 删除窗口外最旧 $del_count 条: ''${del_gens[*]} (保留最新 $KEEP_OLD 条)"
              if [ "$MODE" = "apply" ]; then
                if nix-env -p "$profile" --delete-generations "''${del_gens[@]}"; then
                  CHANGED=$((CHANGED + 1))
                else
                  echo "  ⚠ [$profile] 删除失败, 跳过该 profile 喵" >&2
                fi
              fi
            fi
          done

          if [ "$MODE" = "preview" ]; then
            echo "==> 预览模式, 未执行任何删除。确认无误后加 -y 执行喵"
            exit 0
          fi

          if [ "$CHANGED" -gt 0 ]; then
            echo "==> nix-store --gc 回收 store ..."
            nix-collect-garbage 2>&1 | grep -F 'freed' || true
          fi

          echo "完成喵"
        '';
      })
    ];
  };
}
