{
  config,
  pkgs,
  ...
}: {
  services.xserver.videoDirvers = ["nvidia"];

  hardware.grephics = {
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
