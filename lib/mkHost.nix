# ===== mkHost: 由 machines.nix 注册表生成 nixosConfigurations =====
# 用法 (flake.nix):
#   mkHost = import ./lib/mkHost.nix { inherit inputs system; };
#   nixosConfigurations = builtins.mapAttrs mkHost (import ./machines.nix);
#
# 加一台新机器 = machines.nix 注册 + hosts/<name>/default.nix, flake 不用动。
# 本文件从 flake.nix 原样搬入 (2026-09-22 refactor/multi-host), NixMEOW 行为不变。
{
  inputs,
  system ? "x86_64-linux",
}: let
  user = import ../config.nix;
  lib = inputs.nixpkgs.lib;

  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  # 7.1.5 内核专用打包集 (仅 kernelPackages 使用)
  pkgs-715 = import inputs.nixpkgs-715 {
    inherit system;
    config.allowUnfree = true;
  };
  # 7.1.5 kernelPackages + 键盘背光补丁驱动 (复刻下方 overlay 的 tuxedo 扩展)
  kernelPackages715 =
    (pkgs-715.linuxPackages_7_1).extend (kfinal: kprev: {
      tuxedo-drivers = kfinal.callPackage ../pkgs/tuxedo-drivers-patched {};
      tuxedo-keyboard = kfinal.callPackage ../pkgs/tuxedo-drivers-patched {};
    });

in
  # mapAttrs 的回调签名: name -> machine(注册表条目)
  name: machine: let
    # 本机是否启用某特性 (标签来自 machines.nix)
    has = f: builtins.elem f machine.features;
  in
    lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs pkgs-unstable;
        username = user.username;
        fullName = user.fullName;
      };

      modules = [
        # 机器标签 (来自注册表) —— 各模块据此自我屏蔽
        {
          meow = {
            inherit (machine) kind features;
          };
        }

        ../hosts/${name}

        inputs.agenix.nixosModules.default
        inputs.catppuccin.nixosModules.catppuccin

        (lib.mkIf (has "agenix-secrets") {
          age.secrets.ai_api_key_REIKY_REI = {
            file = ../secrets/ai_api_key_REIKY_REI.age;
            owner = user.username;
          };
          age.secrets.nas-smb-credentials = {
            file = ../secrets/nas-smb-credentials.age;
            owner = "root";
            group = "root";
            mode = "0600";
          };
          age.identityPaths = ["/home/${user.username}/.ssh/id_ed25519"];
        })

        {
          nixpkgs.overlays = [
            # 个人私源: 提供 zen-browser (nixpkgs 未收录, 官方通用二进制打包)
            inputs.Reiky-nixpkgs.overlays.default
            (final: prev: {
              # Zen/GTK3 输入法候选窗: 强制走 Wayland text-input-v3 (fcitx5 waylandim),
              # 让 fcitx5 classicui 在 compositor input-popup 上画主题候选窗(Catppuccin)。
              # 否则 GTK 会选 fcitx5-gtk 的 dbus 模块(default_locales=ja:ko:zh:* 被 locale
              # 自动命中), 候选窗由 GTK 客户端自绘 -> 灰白无主题。不能全局设
              # GTK_IM_MODULE=wayland (会让 X11/XWayland GTK 应用加载 im-wayland.so 崩溃),
              # 故只给 zen 包额外包一层。见复盘 2026-09-12-zen-wayland-ime.md
              zen-browser = prev.zen-browser.overrideAttrs (old: {
                postFixup =
                  (old.postFixup or "")
                  + ''
                    wrapProgram $out/bin/zen --set GTK_IM_MODULE wayland
                  '';
                });
              # 回退 niri 到旧 nixpkgs-unstable rev (f83fc3c): 新 rev 的 niri 26.04 有
              # QSH/壁纸层闪烁回归, 见 known-issues "niri 26.04 layer-shell 壁纸层闪到最前"
              niri = pkgs-unstable.niri;
              # QQ: stable 版本 deb 也被腾讯下架(404), 使用 unstable 版本
              qq = pkgs-unstable.qq;
              # 键盘背光补丁版驱动 (COLORFIRE MEOW R16 固件误报背光类型)
              linuxPackages = prev.linuxPackages.extend (kfinal: kprev: {
                tuxedo-drivers = kfinal.callPackage ../pkgs/tuxedo-drivers-patched {};
                tuxedo-keyboard = kfinal.callPackage ../pkgs/tuxedo-drivers-patched {};
              });
              # 网易云音乐 CDN 防盗链绕过 API
              netease-cdn-bypass = final.callPackage ../pkgs/netease-cdn-bypass {};
            })
          ];
        }

        ({lib, ...}: {
          # 内核 7.1.5 (nixpkgs-715 pin): 覆盖 hardware.nix 的 linuxPackages_7_1
          boot.kernelPackages =
            lib.mkIf (has "kernel-715") (lib.mkForce kernelPackages715);
        })

        inputs.home-manager.nixosModules.home-manager
        {
          environment.systemPackages = [inputs.agenix.packages.${system}.default];
        }
        ({config, ...}: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs pkgs-unstable;
            username = user.username;
            fullName = user.fullName;
            inherit (config.hardware) profile isLowPerf isHighPerf isMediumPerf;
          };
          home-manager.users.${user.username} = {
            imports = [
              inputs.catppuccin.homeModules.catppuccin
              inputs.agenix.homeManagerModules.default
              inputs.noctalia.homeModules.default
              ../home/${user.username}
            ];
            home.packages = [
              pkgs-unstable.mpvpaper
              inputs.CookNixvim.packages.${system}.default
            ];
          };
        })
      ];
    }
