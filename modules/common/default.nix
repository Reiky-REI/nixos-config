{
  config,
  lib,
  pkgs,
  selectedUsers,
  ...
}: {
  imports = [
    ./hardware-profile.nix
    ./options.nix
  ];

  # users setting
  nix.settings.trusted-users = ["root"] ++ map (user: user.username) (builtins.attrValues selectedUsers);
  nixpkgs.config.allowUnfree = true;
  # 临时允许 EOL electron (传递依赖), 等上游 / 26.05 修复后移除:
  #  - electron-39.8.10: 旧 vscode 链遗留
  #  - electron-41.10.7: 2026-10-04 bump 官方 nixpkgs(2026-10-02) 后 electron_41 被标 EOL,
  #    由 home/reiky/apps/media.nix 的 splayer (electron = electron_41) 拉入喵~
  nixpkgs.config.permittedInsecurePackages = ["electron-39.8.10" "electron-41.10.7"];
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # 国内镜像优先 (清华 TUNA / 中科大 USTC / 上交 SJTU), 官方 cache 兜底。
  # 注: 阿里云没有 Nix 二进制缓存 (nix-cache-info 404), 故不列入 substituters。
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://mirror.sjtu.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  # 关键解耦 (2026-10-04): nix-daemon 对国内镜像绕过代理。
  # networking.proxy 会把 http(s)_proxy 注入 nix-daemon; 代理一挂, 连
  # TUNA/USTC 都连不上 → 系统构建全断。no_proxy 让镜像始终直连。
  systemd.services.nix-daemon.environment = {
    no_proxy = lib.mkForce "localhost,127.0.0.1,::1,mirrors.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,mirror.sjtu.edu.cn";
    NO_PROXY = lib.mkForce "localhost,127.0.0.1,::1,mirrors.tuna.tsinghua.edu.cn,mirrors.ustc.edu.cn,mirror.sjtu.edu.cn";
  };
  nix.settings.max-jobs = lib.mkDefault (
    if config.hardware.isHighPerf
    then 16
    else if config.hardware.isMediumPerf
    then 8
    else 4
  );
  nix.settings.cores = 16;
  nix.settings.min-free = 5368709120;
  nix.settings.max-free = 10737418240;

  # timezone and local
  time.timeZone = "Asia/Shanghai";
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_CTYPE = "zh_CN.UTF-8";
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = ["04:00"];

  # nix gc
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "daily";
    options = lib.mkDefault "--delete-older-than 3d";
  };

  # allow none nix packages
  programs.nix-ld.enable = true;

  # 关机/重启加速: 缩短僵尸服务等待时间, 避免长时间卡在黑屏
  # 背景: nvme1 (Windows 盘) 关机时 I/O 超时 + NVIDIA GSP 异常曾导致关机耗时 4 分钟
  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    cachix
    gh
  ];
}
