{
  config,
  lib,
  ...
}: {
  # 2026-10-04 网络链路解耦: 关闭 Clash Verge 的 root service mode。
  # 由 home-manager 的 mihomo.service (独立配置目录) 独占 7890/7897/9097。
  # 保留 enable (GUI 仍可手动启动做订阅管理), 但 serviceMode=false 保证
  # 开机不再拉起 root mihomo 抢端口 / 覆盖运行配置; tunMode 也交给我方
  # mihomo 配置决定。
  programs.clash-verge = lib.mkIf (config.meow.enabled ? "clash") {
    # 2026-10-04: GUI 在 niri/Wayland 渲染损坏, 已改用面板 + noctalia bar 组件,
    # 故不再安装 clash-verge GUI (仅保留 pkgs.clash-verge-rev 供 headless
    # mihomo.service 取用 verge-mihomo 二进制)。
    enable = false;
    # package = pkgs-unstable.clash-verge-rev;
    autoStart = false;
    tunMode = false;
    serviceMode = false;
  };
}
