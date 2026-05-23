{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    cudatoolkit
    cudaPackages.cudaa_nvcc
  ];
}
