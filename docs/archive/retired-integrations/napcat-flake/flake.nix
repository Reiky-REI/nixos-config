{
  description = "NapCatQQ - Modern QQ Bot based on NTQQ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/566acc07c54dc807f91625bb286cb9b321b5f42a";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # NapCatQQ version
    napcatVersion = "4.18.19";

    # Download NapCatQQ Shell release
    napcat-shell-raw = pkgs.fetchzip {
      url = "https://github.com/NapNeko/NapCatQQ/releases/download/v${napcatVersion}/NapCat.Shell.zip";
      hash = "sha256-CLDgnFzbJDOh9df/TmVNfaWSEj5lHvGvJ3d24fUaFiw=";
      stripRoot = false;
    };

    # Patch napcat.mjs: 移除 --no-sandbox（Electron 参数，Node.js 不支持）
    # 同时 patch 所有基于 process.execPath 定位 QQ 资源的路径
    napcat-shell = pkgs.runCommand "napcat-shell-patched" {} ''
      cp -r ${napcat-shell-raw} $out
      chmod -R u+w $out
      # 删除包含 --no-sandbox 的整行
      for f in $(find $out -name '*.mjs' -o -name '*.js'); do
        grep -v '\-\-no-sandbox' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      done
      # (主分支 napcat-main.mjs 试验已回退: 登录后初始化在 3.2.32 上仍崩,
      #  产物保留在源树 napcat-main.mjs, 待 NapCat 新版再试)
      echo "patched, checking no-sandbox count:"
      grep -c "no-sandbox" $out/napcat.mjs || echo "0 (all removed)"
    '';

    # QQ from unstable (3.2.32, URL 有效)
    qq = pkgs-unstable.qq;
    qqAppVersion = "3.2.32-52194";

    # NapCat Shell 必须运行在 QQ Electron 进程里（wrapper.node 需要
    # qq_magic_napi_register 这个由 QQ 主程序导出的符号）。
    # 做法：复制整个 QQ 根目录为符号链接树，再把 qq 主程序复制成真实文件
    # （保证 process.execPath 指向 fake 根），然后把 NapCat shell 覆盖进
    # resources/app。这就是 Nix 式“组合两个 store 产物”。
    fake-qq-env = pkgs.runCommand "napcat-fake-qq-env" {} ''
      # 1) QQ 根目录符号链接树
      cp -rs ${qq}/opt/QQ/. $out/
      chmod -R u+w $out

      # 2) qq 主程序要真实复制，不能是软链（软链会让 process.execPath
      #    解析回原 store 路径，NapCat 就找不到覆盖后的 resources/app）
      rm $out/qq
      cp ${qq}/opt/QQ/qq $out/qq
      chmod +x $out/qq

      # 3) 用符号链接树把 NapCat Shell 覆盖进 resources/app
      mkdir -p $out/resources/app
      # 先移除 NapCat 会覆盖的同名条目，避免 cp -rs 报 File exists
      for item in ${napcat-shell}/*; do
        rm -rf "$out/resources/app/$(basename "$item")"
      done
      cp -rs ${napcat-shell}/. $out/resources/app/
      chmod -R u+w $out/resources/app

      # 4) 关键：QQ 的 package.json 保留大部分字段，但把 main 改成
      #    ./napcat.mjs，让 Electron 主进程直接加载 NapCat Shell
      rm -f $out/resources/app/package.json
      cp ${qq}/opt/QQ/resources/app/package.json $out/resources/app/package.json
      chmod u+w $out/resources/app/package.json
      sed -i 's#"main": "./application\.asar/app_launcher/index\.js"#"main": "./napcat.mjs"#' $out/resources/app/package.json
      ln -sf ${qq}/opt/QQ/resources/app/application.json $out/resources/app/application.json 2>/dev/null || true

      echo "fake qq env created at $out"
      ls -l $out/qq $out/resources/app/napcat.mjs $out/resources/app/wrapper.node 2>&1 || true
    '';

    # Create a wrapper script
    napcat-wrapper = pkgs.writeShellScriptBin "napcat" ''
      #!${pkgs.bash}/bin/bash

      # Set up environment
      export NAPCAT_SHELL_DIR="${napcat-shell}"
      export QQ_DIR="${qq}"

      # NapCat 运行目录（可写），napcat.mjs 用 NAPCAT_WORKDIR 定位日志等文件
      NAPCAT_HOME="''${NAPCAT_HOME:-$HOME/.config/NapCat}"
      mkdir -p "$NAPCAT_HOME"
      mkdir -p "$HOME/.config/QQ"
      export NAPCAT_WORKDIR="$NAPCAT_HOME"

      # 告诉 NapCat QQ 的 package.json 在哪
      export NAPCAT_QQ_PACKAGE_INFO_PATH="${fake-qq-env}/resources/app/package.json"

      # 注意：不要加 LD_LIBRARY_PATH 强行加载 libstdc++
      # QQ 3.2.32 不在 NapCat 4.18.19 支持列表，原生 wrapper.node 一加载就崩。
      # 保持原生模块降级（ffmpeg 命令行/无 packet），OneBot WebSocket 仍正常工作。

      # 直接运行 QQ Electron 主程序（NapCat 已覆盖在 resources/app 里）
      # !! 2026-09-01 复盘：注入 libstdc++ 后原生模块可加载、首次出码正常，
      # 但 QR 过期刷新(5min)路径在 QQ 3.2.32 上稳定段错误(11/SEGV, 周期5m25s)，
      # 快速登录也会崩 —— NapCat 4.18.19 原生胶水确实只兼容到 3.2.23。
      # 故回到降级模式(ffmpeg CLI / 无 packet)，OneBot 收发正常。
      # 待办：换 QQ 3.2.23 历史 deb 或构建 NapCat 主分支后重新启用下行。
      # !! 2026-09-01 晚最终结论: 主分支 mjs 修好了 QR 刷新 SEGV, 但"登录成功后
      # 初始化"在 3.2.32 上仍崩溃(exit 1) —— 原生模式无法完成登录。
      # 定版: 降级模式(4.18.19 原生 zip), 登录可用、无 packet。根治待 NapCat
      # 新版本或 QQ 3.2.23~3.2.30 历史 deb(见 retros/2026-09-01)。
      # export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib or pkgs.gcc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

      # 始终运行在 Xvfb 虚拟屏：NapCat 交互全部走 WebUI，无需真实显示；
      # 同时避免 QQ 的 GUI 窗口出现在用户桌面会话里。
      # NIXOS_OZONE_WL/XDG_SESSION_TYPE 会让 Chromium 优先尝试 Wayland，
      # 服务环境里没有 Wayland socket 时直接平台初始化失败退出，必须清掉并钉死 X11。
      unset WAYLAND_DISPLAY NIXOS_OZONE_WL XDG_SESSION_TYPE
      "${pkgs.xorg.xvfb}/bin/Xvfb" :97 -screen 0 1280x720x24 &
      export DISPLAY=:97
      sleep 1

      cd "$NAPCAT_HOME"
      exec ${fake-qq-env}/qq --no-sandbox --disable-dev-shm-usage --disable-gpu --ozone-platform=x11 "$@"
    '';
  in {
    packages.${system} = {
      default = napcat-wrapper;
      napcat = napcat-wrapper;
      napcat-shell = napcat-shell;
      qq = qq;
    };

    apps.${system} = {
      napcat = {
        type = "app";
        program = "${napcat-wrapper}/bin/napcat";
      };
    };

    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.nodejs
        pkgs.corepack_22
        napcat-wrapper
        qq
      ];

      shellHook = ''
        echo "🐱 NapCatQQ Development Environment"
        echo "   NapCat Version: ${napcatVersion}"
        echo "   QQ Version: ${qq.version}"
        echo ""
        echo "Usage:"
        echo "  napcat          - Start NapCatQQ"
        echo "  nix run .#napcat - Start NapCatQQ"
      '';
    };
  };
}
