{pkgs, ...}: let
  # `proxy` 命令行 + man 手册页 (`man proxy`), 由 home-manager 装进 profile
  proxyCli = pkgs.stdenvNoCC.mkDerivation {
    pname = "mihomo-proxy-cli";
    version = "1.0.0";
    dontUnpack = true;
    installPhase = ''
      install -Dm755 ${./proxy.sh} $out/bin/proxy
      install -Dm644 ${./proxy.1} $out/share/man/man1/proxy.1
    '';
    meta = {
      description = "Control the headless mihomo proxy (on/off/node/status)";
      mainProgram = "proxy";
    };
  };
in {
  home.packages = [ proxyCli ];

  # Mihomo 代理 (headless, 独立于 Clash Verge GUI)
  #
  # 背景: Clash Verge GUI 在 Wayland 下 GTK 初始化失败/随会话死亡,
  # mihomo 作为其子进程一起消失 → 全局代理 (networking.proxy → 7897)
  # 静默失效, opencode/nix/git 全断 (见 known-issues.md)。
  # 方案: systemd user unit 直接跑 verge-mihomo, 不依赖 GUI。
  # 配置目录/文件本服务私有, 与 Clash Verge 数据目录彻底解耦 (2026-10-04):
  #   - 配置: %h/.config/mihomo/config.yaml (订阅内容由此维护)
  #   - 面板: %h/.config/mihomo/ui (metacubexd, 由 external-ui 托管)
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
      # 注意: 必须用列表生成多条独立 ExecStartPre= 行, 不能写多行块字符串 —
      # home-manager 序列化时会丢掉续行缩进, 生成的行会顶到行首被 systemd
      # 当成新键解析 (expected entry key name but got '/')。
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p '%h/.config/mihomo'"
      ];
      ExecStart = ''
        ${pkgs.clash-verge-rev}/bin/verge-mihomo \
          -d %h/.config/mihomo \
          -f %h/.config/mihomo/config.yaml \
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
