# ===== NixMEOW-WSL — Windows WSL2 试验台 =====
# 定位: 无 NVIDIA 黑屏风险的 nixos-rebuild switch 迭代场 + nested niri。
# 平台配置全部由 inputs.nixos-wsl 模块提供 (boot loader/文件系统由它接管)。
# 特性标签见 machines.nix —— 目前只开 compositor-niri。
{
  inputs,
  pkgs,
  lib,
  username,
  fullName,
  ...
}: let
  # ===== 浏览器桌面共量 =====
  # noVNC 链路: 浏览器 --websocket--> websockify(0.0.0.0:8080) --> x11vnc(:5901)
  #   --> Xvfb(:93) --> niri (winit/X11 软件渲染) + spawn-at-startup noctalia
  # 局域网访问走 Windows 侧 netsh portproxy 8080 -> WSL IP (计划任务随 IP 变自动刷新)
  # 每个组件独立服务 + Restart=always
  # (2026-09-23: 单脚本 wait 版里 websockify/x11vnc 死了不会被发现, 也不会被拉起)
  # ⚠️ VNC 密码明文在仓库里 —— 试验台/LAN 范围用, 改密码就改这里
  novncShare = "${pkgs.novnc}/share/webapps/novnc";
  websockifyPkg = pkgs.python3Packages.websockify;
  vncPass = "meow-8080-lan";
in {
  imports = [
    inputs.nixos-wsl.nixosModules.default

    # 共享模块树 —— 各模块按 machines.nix 的标签自我屏蔽
    ../../modules
  ];

  networking.hostName = "NixMEOW-WSL";

  # WSL NAT 下国内镜像不稳定: 只走官方 cache + 禁 HTTP/2 (走代理已知问题)
  nix.settings.substituters = lib.mkForce ["https://cache.nixos.org"];
  nix.settings.http2 = lib.mkForce false;

  # NAS: 挂 Windows 已认证的 Z: 映射 (drvfs 复用宿主 SMB 凭据, 不需要 NAS 密码)
  # 注意: PATH 必须含 /run/current-system/sw/bin 与 /sbin —— NixOS 单元脚本默认
  # PATH 里没有 mount/mountpoint (2026-09-23 switch 后 failed 的教训)
  systemd.services.nas-drvfs = {
    description = "Mount Windows Z: (NAS share) via drvfs";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      PATH=/run/current-system/sw/bin:/sbin:/usr/sbin:$PATH
      mkdir -p /mnt/z
      if ! mountpoint -q /mnt/z; then
        mount -t drvfs Z: /mnt/z
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    x11vnc
    xorg.xvfb
    websockifyPkg
    novnc
  ];

  systemd.services.browser-xvfb = {
    description = "Xvfb :93 for niri-in-browser";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = username;
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
      ExecStart = "${pkgs.xorg.xvfb}/bin/Xvfb :93 -screen 0 1920x1080x24 -nolisten tcp";
    };
  };

  systemd.services.browser-niri = {
    description = "niri on Xvfb :93 (browser desktop session)";
    wantedBy = ["multi-user.target"];
    after = ["browser-xvfb.service"];
    requires = ["browser-xvfb.service"];
    environment = {
      HOME = "/home/${username}";
      DISPLAY = ":93";
      XDG_RUNTIME_DIR = "/run/user/1000";
      # winit X11 后端运行时 dlopen libXcursor/libXrandr/libXi (非硬链接依赖)
      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs.xorg; [
        libXcursor
        libXrandr
        libXi
        libXinerama
      ]);
    };
    serviceConfig = {
      User = username;
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
      ExecStart = "${pkgs.niri}/bin/niri";
    };
  };

  systemd.services.browser-vnc = {
    description = "x11vnc :5901 serving Xvfb :93";
    wantedBy = ["multi-user.target"];
    after = ["browser-niri.service"];
    serviceConfig = {
      User = username;
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
      ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display :93 -rfbport 5901 -forever -shared -passwd ${vncPass}";
    };
  };

  systemd.services.browser-novnc = {
    description = "websockify 0.0.0.0:8080 (noVNC static + WebSocket bridge)";
    wantedBy = ["multi-user.target"];
    after = ["browser-vnc.service"];
    environment = {
      HOME = "/home/${username}";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    serviceConfig = {
      User = username;
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
      WorkingDirectory = novncShare;
      ExecStart = "${websockifyPkg}/bin/websockify 0.0.0.0:8080 --web ${novncShare} localhost:5901";
    };
  };

  # browser-noVNC 需要从局域网访问 (Windows portproxy 转发进来)
  networking.firewall.allowedTCPPorts = [8080];

  # 试验台不开文档生成: nixos-render-docs 的 python 依赖在 cache.nixos.org 上 404
  # (上游 Hydra 没构建), 会让整个 build 打地鼠; NixMEOW 不受影响
  documentation.nixos.enable = false;
  documentation.man.cache.enable = lib.mkForce false;
  home-manager.users.${username}.manual.manpages.enable = false;

  wsl.enable = true;
  wsl.defaultUser = username;

  users.users.${username} = {
    description = fullName;
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = ["wheel" "audio" "video"];
  };

  system.stateVersion = "26.05";
}
