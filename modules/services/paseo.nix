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

  # 两处上游 nix 打包的坑, 都必须 override 掉才能用的:
  #
  # 1) preBuild = "npm run postinstall":
  #    nix 构建带 --ignore-scripts, 上游 postinstall (patch-package) 不会跑喵~
  #    少打 @gorhom/bottom-sheet 的补丁 → BottomSheetModalInternalProvider
  #    是 undefined → web UI 首屏就崩 "Minified React error #130" 喵~
  #    上游 issue #7673 证实 (desktop 与 daemon web-ui 共用同一份 app bundle)喵~
  #
  # 2) NODE_OPTIONS heap 6G:
  #    上游只在 desktop-package.nix 设了 4G, daemon 包没设喵~
  #    expo export 打 5685 个模块时会在 99.9% 处 OOM, 静默 exit 1 喵~
  paseoPackage = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    preBuild = "npm run postinstall";
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
