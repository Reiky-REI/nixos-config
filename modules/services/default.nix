{lib, ...}: {
  imports = [
    ./media
    ./dsh-fence.nix
    ./astrabot.nix
    ./llama-cpp.nix
    ./opencode-root.nix
  ];

  # DSH 外层围栏:加固的 systemd 服务接管 dsh web。
  # 下次 nixos-rebuild switch 前,先停掉手动启动的 dsh 进程(端口 3080)。
  services.dsh-fence.enable = true;

  services.astrabot.enable = true;

  services.llama-cpp.enable = true;

  services.opencode-root.enable = true;

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
    AllowSuspend = "yes";
    AllowHibernation = "no";
    AllowHybridSleep = "yes";
    AllowSuspendThenHibernate = "yes";
  };

  environment.sessionVariables.XDG_DATA_DIRS = lib.mkAfter [
    "/var/lib/flatpak/exports/share"
    "$HOME/.local/share/flatpak/exports/share"
  ];
}
