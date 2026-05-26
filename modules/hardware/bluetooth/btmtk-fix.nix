{
  pkgs,
  lib,
  config,
  ...
}: let
  kernel = config.boot.kernelPackages.kernel;
  kernelVersion = kernel.modDirVersion;
  kernelBuild = "${kernel.dev}/lib/modules/${kernelVersion}/build";

  patched-btmtk = pkgs.stdenv.mkDerivation {
    name = "btmtk-patched-${kernelVersion}";

    # 我们不使用 src（自行从 kernel.src tarball 选择性提取）
    phases = ["buildPhase" "installPhase"];

    nativeBuildInputs =
      [pkgs.gnutar pkgs.xz]
      ++ kernel.moduleBuildDependencies;

    buildPhase = ''
      runHook preBuild

      # 只提取 btmtk.c 和 btmtk.h（几 KB，瞬间完成）
      tar xf ${kernel.src} --strip-components=1 \
        linux-${kernelVersion}/drivers/bluetooth/btmtk.c \
        linux-${kernelVersion}/drivers/bluetooth/btmtk.h

      # 打 WMT 事件校验补丁
      patch -p1 < ${../../../patches/btmtk-wmt-fix.patch}

      # 创建最小 Kbuild（只编译 btmtk.ko）
      echo 'obj-m := btmtk.o' > drivers/bluetooth/Kbuild

      # 用已有 kernel build tree 编译
      # -O1 -g0：asm goto 要求至少 O1，但仍比 O2 快很多
      make -C ${kernelBuild} \
        KCFLAGS="-O1 -g0" \
        M=$PWD/drivers/bluetooth \
        modules

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      make -C ${kernelBuild} \
        M=$PWD/drivers/bluetooth \
        INSTALL_MOD_PATH=$out \
        modules_install

      runHook postInstall
    '';
  };
in {
  boot.extraModulePackages = [patched-btmtk];
}
