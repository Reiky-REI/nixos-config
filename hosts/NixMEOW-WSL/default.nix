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
}: {
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
  # 重启后 systemd 自动重挂
  # 注意: PATH 必须含 /run/current-system/sw/bin 与 /sbin —— NixOS 单元脚本默认 PATH
  # 没有 mount/mountpoint (见 2026-09-23 switch 后 failed 的教训)
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

  # ===== 浏览器桌面: noVNC on :8080 (暴露给局域网) =====
  # 链路: 浏览器 --websocket--> websockify(0.0.0.0:8080) --> x11vnc(:5901)
  #       --> Xvfb(:93) --> niri (winit/X11 软件渲染) + spawn-at-startup noctalia
  # 局域网访问需要 Windows 侧 netsh portproxy 8080 -> WSL IP (防火墙另放行)
  # ⚠️ VNC 密码明文在仓库里 —— 试验台/LAN 范围用, 改密码就改这里
  systemd.services.browser-desktop = {
    description = "niri desktop in browser via noVNC (0.0.0.0:8080)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    path = with pkgs; [
      x11vnc
      xorg.xvfb
      (pkgs.python3Packages.websockify)
      coreutils
    ];
    environment = {
      HOME = "/home/${username}";
      XDG_CONFIG_HOME = "/home/${username}/.config";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
    serviceConfig = {
      User = username;
      Type = "simple";
    };
    # Type=simple + 末尾 wait = systemd 托管整个 cgroup, stop 时全部干净收掉
    script = let
      novncShare = "${pkgs.novnc}/share/webapps/novnc";
      websockify = "${pkgs.python3Packages.websockify}/bin/websockify";
      vncPass = "meow-8080-lan";
    in ''
      # WSLg 的 /tmp/.X11-unix 是只读挂载 (777 可写但不能 chmod)
      # → sticky bit 警告无害, 别 chmod (会导致 unit 报错退出)
      ${pkgs.xorg.xvfb}/bin/Xvfb :93 -screen 0 1920x1080x24 -nolisten tcp \
        > /tmp/browser-desktop-xvfb.log 2>&1 &
      sleep 1
      ${pkgs.niri}/bin/niri > /tmp/browser-desktop-niri.log 2>&1 &
      sleep 2
      ${pkgs.x11vnc}/bin/x11vnc -display :93 -rfbport 5901 -forever -shared \
        -passwd "${vncPass}" > /tmp/browser-desktop-x11vnc.log 2>&1 &
      ${websockify} 0.0.0.0:8080 --web "${novncShare}" localhost:5901 \
        > /tmp/browser-desktop-websockify.log 2>&1 &
      wait
    '';
  };

  # browser-desktop 需要从局域网访问 (Windows portproxy 转发进来)
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
