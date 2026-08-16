{pkgs, ...}: {
  # Mihomo 代理 (headless, 独立于 Clash Verge GUI)
  #
  # 背景: Clash Verge GUI 在 Wayland 下 GTK 初始化失败/随会话死亡,
  # mihomo 作为其子进程一起消失 → 全局代理 (networking.proxy → 7897)
  # 静默失效, opencode/nix/git 全断 (见 known-issues.md)。
  # 方案: systemd user unit 直接跑 verge-mihomo, 不依赖 GUI。
  # 与 clash-verge 共用同一运行配置 (profiles 合并后的 clash-verge.yaml)。
  #
  # 加固点 (2026-08-16 排查):
  #   - 改用 TCP 控制器 -ext-ctl 127.0.0.1:9097, 不再用 -ext-ctl-unix
  #     (与 GUI 双开抢 unix socket → address already in use)。
  #   - ExecStartPre 清理遗留 socket + 确保 runtime 目录存在, 防止
  #     bind 失败。
  #   - StartLimitIntervalSec = 0: 与 GUI 并存抢端口时持续重试而不是
  #     crash-loop 到 systemd 默认 5次/10s 限制后停摆。
  systemd.user.services.mihomo = {
    Unit = {
      Description = "Mihomo proxy (headless)";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStartPre = ''
        ${pkgs.coreutils}/bin/mkdir -p '%t/clash-verge-rev'
        ${pkgs.coreutils}/bin/rm -f '%t/clash-verge-rev/verge-mihomo.sock'
      '';
      ExecStart = ''
        ${pkgs.clash-verge-rev}/bin/verge-mihomo \
          -d %h/.local/share/io.github.clash-verge-rev.clash-verge-rev \
          -f %h/.local/share/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml \
          -ext-ctl 127.0.0.1:9097
      '';
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
