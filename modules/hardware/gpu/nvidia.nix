{
  pkgs,
  lib,
  ...
}: {
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = ["amdgpu" "nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      nvidiaBusId = "PCI:0:1:0:0";
      amdgpuBusId = "PCI:0:6:0:0";
    };
  };
}
