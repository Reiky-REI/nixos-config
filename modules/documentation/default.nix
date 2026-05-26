{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    man-pages
    man-pages-posix
  ];
  documentation = {
    enable = true;
    man = {
      enable = true;
      generateCaches = true;
      man-db = {
        enable = true;
      };
    };
  };
}
