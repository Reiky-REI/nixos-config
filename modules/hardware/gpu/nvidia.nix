{
  config,
  pkgs,
  ...
}: {
  services.xserver.videoDrivers = ["nvidia"];

  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    modesetting = {
      enable = true;
    };
    open = false;
    nvidiaSettings = true;
  };
}
