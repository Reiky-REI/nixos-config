# ===== Paseo: 多 agent 编排 daemon =====
#
# 多 session / 多 agent 并行时的隔离与调度层喵, 设计说明见
# .agents/knowledge/multi-agent-coordination.md 喵~
#
# 设计要点:
#   - 以真实用户身份运行 (User=<primary>), agent 进程才能拿到 home-manager
#     profile 里的 opencode / claude / codex / hermes 喵
#   - 只监听回环 127.0.0.1, relay 关闭: 远程访问走 tailscale 直连客户端喵
#   - settings 由 nix 拥有: 每次启动覆写 ~/.paseo/config.json 喵
#     想改用桌面端/CLI 管配置, 就删掉下面 settings 那段喵
{
  config,
  inputs,
  lib,
  pkgs,
  primaryUser,
  ...
}: let
  user = primaryUser.username;

  # 上游 package.nix 没给 expo/Metro 打包设 NODE_OPTIONS 喵~
  # 5685 个模块在默认 4G heap 下会在 99.9% 处 OOM, build:web 直接 exit 1 喵~
  # 这里把 heap 提到 6G (本机 14G 内存, 留够给系统) 喵~
  paseoPackage = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    env = (old.env or {}) // {NODE_OPTIONS = "--max-old-space-size=6144";};
  });
in {
  services.paseo = lib.mkIf (config.meow.enabled ? "paseo") {
    enable = true;
    package = paseoPackage;
    inherit user;
    group = config.users.users.${user}.group;
    port = 6767;
    listenAddress = "127.0.0.1";
    openFirewall = false;
    # 不走官方 hosted relay: 外网访问用 tailscale 直连 6767
    relay.enable = false;

    settings = {
      daemon.listen = "127.0.0.1:6767";
      # daemon 自带 web 客户端, 浏览器可直接开 http://localhost:6767
      features.webUi.enabled = true;
    };
  };
}
