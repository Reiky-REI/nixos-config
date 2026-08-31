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
    # 2026-09-01: 一天三连黑屏强重启 (8-31 ~16:00 无日志期/8-31 19:53/9-1 01:34), 根因均为
    # Noctalia idle 自动挂起 (suspendTimeout=1800) + amdgpu deep 挂起唤醒必坏 (8-17 known-issue, 7.1.5 未修).
    # 触发源已在 noctalia settings.json 禁用 (suspendTimeout→0 + 会话菜单 suspend 按钮关闭, 运行时状态不入库),
    # 此处系统级封死 S3 故障态: 任何路径 (合盖/键bind/应用) 均无法进入挂起喵~
    # 恢复条件: 上游 amdgpu 唤醒修复 + 实测挂起-唤醒往返通过; 休眠 (S4) 另测, 与 S3 路径不同喵~
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "/var/lib/flatpak/exports/share"
    "$HOME/.local/share/flatpak/exports/share"
  ];
}
