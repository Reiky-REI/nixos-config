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
    ./nix-prune.nix
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

  # nix gc — 只做 store 垃圾回收, 世代清理统一走 nix-prune-generations
  # (空间闸门式保留, 规则见 modules/common/nix-prune.nix 与 README「世代保留策略」)。
  # 背景: 原 --delete-older-than 3d 每天 GC 都无条件删回滚点; 2026-10-04 与一次
  # 人工 `--delete-generations old` 叠加后 boot 菜单只剩一个世代且无法回滚。
  # mkForce 是为了让该语义不被其它模块的第三方 default 悄悄改回删世代路径。
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "daily";
    options = lib.mkForce "";
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
