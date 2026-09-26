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

  # WSL 内手工重建的包装 (声明式替代文档里的 tmpfs /root/nixrun.sh):
  #   - 强制走宿主 Clash 代理 (WSL2 NAT 下 GitHub 直连不稳)
  #   - 可选 GitHub token: 写一行到 ~/.config/nix/access-token (root 用 /etc/nix/access-token)
  #   用法: wsl-rebuild build --flake ~/nixos-config#NixMEOW-WSL
  #         sudo wsl-rebuild switch --flake ~/nixos-config#NixMEOW-WSL
  wslRebuild = pkgs.writeShellScriptBin "wsl-rebuild" ''
    set -euo pipefail
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890

    cfg="extra-experimental-features = nix-command flakes
    http2 = false"
    tok_file=""
    for f in "''${NIX_ACCESS_TOKEN_FILE:-}" "$HOME/.config/nix/access-token" /etc/nix/access-token; do
      if [ -n "$f" ] && [ -r "$f" ]; then tok_file="$f"; break; fi
    done
    if [ -n "$tok_file" ]; then
      tok="$(tr -d ' \r\n' < "$tok_file")"
      cfg="$cfg
    access-tokens = github.com=$tok"
    fi
    export NIX_CONFIG="$cfg"

    exec nixos-rebuild "$@"
  '';
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

  # Nix 没有 nix.conf 里的 proxy 选项 —— daemon 出网只能靠环境变量。
  # 宿主 Clash 混合端口 7890, WSL2 的 127.0.0.1 即 Windows 的 127.0.0.1
  # (.wslconfig: hostAddressLoopback=true)。
  systemd.services.nix-daemon.environment = {
    http_proxy = "http://127.0.0.1:7890";
    https_proxy = "http://127.0.0.1:7890";
  };

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
    wslRebuild
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
      # 强制 X11 后端: WSL 可能向服务环境注入 WAYLAND_DISPLAY, 抢掉 Xvfb 的 DISPLAY
      WINIT_UNIX_BACKEND = "x11";
      # winit X11 后端运行时 dlopen libXcursor/libXrandr/libXi (非硬链接依赖)
      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs.xorg; [
        libXcursor
        libXrandr
        libXi
        libXinerama
      ]);
      # spawn-at-startup 的 noctalia/fcitx5 二进制在用户 profile 里,
      # systemd 默认 PATH 找不到 (spawn 静默失败 → 桌面"光有 niri")
      # mkForce + 保留 systemd 模块的基础路径 (否则与其默认 PATH 同优先级冲突)
      PATH = lib.mkForce (lib.concatStringsSep ":" [
        "/etc/profiles/per-user/${username}/bin"
        "/run/current-system/sw/bin"
        (lib.makeBinPath [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.systemd
        ])
      ]);
      # Xvfb/软件渲染下 QML 没硬件 GL, noctalia(QtQuick) 走软件后端
      QT_QUICK_BACKEND = "software";
    };
    serviceConfig = {
      User = username;
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
      ExecStart = "${pkgs.niri}/bin/niri";
      # 无外层 WM, 窗口按 winit 默认大小出 (没吃满屏幕的坑) — X 直接改窗口几何
      # (niri 的 output 会动态跟随窗口尺寸, 所以改窗口 = 改桌面大小)
      ExecStartPost = pkgs.writeShellScript "browser-niri-resize" ''
        for i in 1 2 3 4 5; do
          sleep 2
          for id in $(${pkgs.xdotool}/bin/xdotool search --onlyvisible --name ""); do
            ${pkgs.xdotool}/bin/xdotool windowmove "$id" 0 0 2>/dev/null
            ${pkgs.xdotool}/bin/xdotool windowsize "$id" 1920 1080 2>/dev/null
          done
        done
      '';
    };
  };

  # logind 建用户 session 才会有 /run/user/1000 → niri socket PermissionDenied
  # (2026-09-23 黑屏根因); tmpfiles 在服务启动前建好
  systemd.tmpfiles.rules = [
    "d /run/user 0755 root root -"
    "d /run/user/1000 0700 Reiky-REI users -"
  ];

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

  # noctalia 壳: 不走 niri 的 spawn-at-startup (systemd-run 依赖 user session 就绪,
  # 时机不稳) —— 独立服务 Restart, 每次启动自己找最新的 niri wayland socket
  systemd.services.browser-noctalia = {
    description = "noctalia-shell in browser desktop session";
    wantedBy = ["multi-user.target"];
    after = ["browser-niri.service"];
    environment = {
      HOME = "/home/${username}";
      XDG_RUNTIME_DIR = "/run/user/1000";
      QT_QUICK_BACKEND = "software";
    };
    serviceConfig = {
      User = username;
      Type = "simple";
      Restart = "always";
      RestartSec = "3";
    };
    script = ''
      SOCK=$(ls -t /run/user/1000/niri.*.sock 2>/dev/null | head -1)
      if [ -n "$SOCK" ]; then
        exec env WAYLAND_DISPLAY="$(basename "$SOCK")" /etc/profiles/per-user/${username}/bin/noctalia-shell
      fi
      exit 0
    '';
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
