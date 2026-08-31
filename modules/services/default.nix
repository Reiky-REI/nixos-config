{lib, ...}: {
  imports = [
    ./media
    ./dsh-fence.nix
    ./astrabot.nix
    ./llama-cpp.nix
    ./opencode-root.nix
    ./mcp-agents-bridge.nix
    ./netease-cdn-bypass.nix
  ];

  # DSH 外层围栏:加固的 systemd 服务接管 dsh web。
  # 下次 nixos-rebuild switch 前,先停掉手动启动的 dsh 进程(端口 3080)。
  services.dsh-fence.enable = true;
  services.dsh-fence.trustedHosts = ["nixmeow.miku-garibaldi.ts.net"];

  services.astrabot.enable = true;

  services.llama-cpp.enable = true;

  services.opencode-root.enable = true;

  services.mcp-agents-bridge.enable = true;

  services.netease-cdn-bypass.enable = true;

  services.udisks2.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.flatpak.enable = true;

  services.printing.enable = true;

  services.libinput.enable = true;

  services.timesyncd.enable = true;

  systemd.sleep.settings.Sleep = {
    # 睡眠恢复: 之前为防 Noctalia 待机挂起失败导致锁屏卡住而禁用,
    # 现在允许 suspend, 并在 niri 用 Meta+L 触发 hyprlock(高斯模糊)+ suspend
    AllowSuspend = "yes";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "/var/lib/flatpak/exports/share"
    "$HOME/.local/share/flatpak/exports/share"
  ];
}
