{pkgs, ...}: let
  # dsh-tui 启动器 — 原为手写脚本 ~/WorkSpace/bin/dsh-tui (改名后残留
  # /home/Reiky-REI 死路径导致 corepack EACCES), 现收编为声明式:
  # 跑 profile 里装的官方 TUI bin, node 由本 profile 提供。
  dshTui = pkgs.writeShellScriptBin "dsh-tui" ''
    set -euo pipefail

    PROFILE_DIR="''${DSH_HOME:-$HOME/.dsh}/profiles/dsh-tui"
    TUI_BIN="$PROFILE_DIR/node_modules/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js"

    if [ ! -f "$TUI_BIN" ]; then
      echo "[dsh-tui] profile 未初始化: $TUI_BIN" >&2
      echo "[dsh-tui] 初始化: dsh plugin --profile dsh-tui add @deepseek-harness-tui/dsh-tui@<version>" >&2
      exit 1
    fi

    if ! command -v dsh >/dev/null 2>&1; then
      echo "[dsh-tui] 警告: PATH 上找不到 dsh CLI, TUI 可能无法启动会话" >&2
    fi

    exec ${pkgs.nodejs}/bin/node "$TUI_BIN" "$@"
  '';
in {
  # dsh (DeepSeek Harness) CLI — 由 Reiky-nixpkgs 私源提供, 替代此前
  # 家目录下的 `npm install @deepseek-ai/dsh` 非声明式安装。
  #
  # 包一层守卫: web 子命令已由 systemd 服务 dsh-fence 托管(3080),
  # 手动 `dsh web` 会 EADDRINUSE 抢占端口并让服务陷入重启循环,
  # 故在服务 active 时直接拦截并给出替代操作; 其余子命令透传真实 dsh。
  home.packages = [
    (pkgs.writeShellScriptBin "dsh" ''
      if [ "''${1:-}" = "web" ] && ${pkgs.systemd}/bin/systemctl is-active --quiet dsh-fence 2>/dev/null; then
        echo "dsh web 已由 systemd 服务 dsh-fence 托管 (3080), 手动运行会抢占端口。" >&2
        echo "  访问: http://127.0.0.1:3080/" >&2
        echo "  重启: sudo systemctl restart dsh-fence" >&2
        echo "  查看: journalctl -u dsh-fence -f" >&2
        exit 1
      fi
      exec ${pkgs.dsh}/bin/dsh "$@"
    '')

    # dsh 的 profile 插件管理 (`dsh plugin ...`) 与 dsh-tui 的内置 /update 都用
    # spawnSync("pnpm") 从 PATH 找 pnpm, 缺了会直接报 "pnpm not found on PATH"。
    # 此前靠 corepack shim + 手写 COREPACK_HOME, 用户改名 (Reiky-REI → reiky) 后
    # 旧路径残留在环境里导致 corepack EACCES → 改为声明式提供。
    pkgs.pnpm

    dshTui
  ];
}
