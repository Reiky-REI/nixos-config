{pkgs, ...}: {
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
  ];
}
