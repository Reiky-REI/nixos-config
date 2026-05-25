{...}: {
  # CUDA intentionally removed from systemPackages to avoid pulling ~4GB into every rebuild.
  # Use on-demand: nix shell nixpkgs#cudatoolkit nixpkgs#cudaPackages.cuda_nvcc
}
