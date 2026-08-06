{lib, ...}: {
  imports = [
    ./media
  ];

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
