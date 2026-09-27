# NixMEOW-CTR — Docker systemd 容器镜像

> 2026-09-27 建立。目标: 把同一套用户态工具环境打包成容器, 在别的机器以
> docker/podman 运行, 共享宿主内核, 不需要图形与桌面。

## 1. 定位

| 项 | 值 |
|----|----|
| 主机名 | `NixMEOW-CTR` (machines.nix: kind=container, roles=[server]) |
| 角色 | server — 无桌面、无本机硬件事实、无 boot loader |
| 镜像来源 | nixpkgs `virtualisation/docker-image.nix` 模块 (非已弃用的 nixos-generators) |
| 初始化 | systemd 作为 PID 1 |
| 用户 | `reiky` (来自 users.nix), 交互 shell 为 bash |

## 2. 构建

```bash
nix build .#packages.x86_64-linux.NixMEOW-CTR-docker \
  -o ~/.local/share/nixmeow-ctr-docker
ls -lh ~/.local/share/nixmeow-ctr-docker/tarball/
```

产物是 docker 可直接 `import` 的 rootfs tarball喵~

> 用 `-o <path>` 建一个 gcroot: 否则 `--no-link` 构建的 tarball 没有被任何 root 引用,
> 下一次 `nix-collect-garbage` 就会把它删掉 (3.3 GB 要重编)喵~

## 3. 导入与运行

docker 与 podman 都可以 (本机 podman 提供 docker 兼容命令):

```bash
# 导入 (docker / podman 二选一)
docker import ~/.local/share/nixmeow-ctr-docker/tarball/nixos-system-*.tar.xz nixmeow-ctr
podman import ~/.local/share/nixmeow-ctr-docker/tarball/nixos-system-*.tar.xz localhost/nixmeow-ctr:latest

# systemd 需要容器特权: 用 --privileged
podman run --privileged -d --name nixmeow localhost/nixmeow-ctr:latest /init

# 等 systemd 起好后进入容器
podman exec -it nixmeow /run/current-system/sw/bin/bash
```

> 该镜像以 systemd 为 PID 1, 因此不能按普通单进程容器以 `docker run image <cmd>`
> 的方式使用; 运行时需要相应特权。若只需要单进程工具环境, 应改用别的打包方式。

## 4. 与其它 host 的关系

- 与 `NixMEOW`/`NixMEOW-WSL` **共享** `users.nix`、`modules/`、`home/{profile}/` 能力实现。
- 差异只体现在 host 声明: `kind=container`、`roles=[server]`、`features=[]`。
- 因 `kind=container`, 容器内不启用 systemd-resolved (共享宿主 resolv.conf), 不装文档包,
  不启用桌面/图形/字体/硬件驱动能力。

## 5. 排障速查

```bash
# 镜像闭包里不该出现桌面组件
nix path-info -r ./result | grep -Ei 'niri|rofi|noctalia|hyprlock' || echo "无桌面组件"

# 配置求值
nix eval .#nixosConfigurations.NixMEOW-CTR.config.system.build.toplevel.drvPath
```

**已知约束**:

- `boot.isContainer = true` 下 NixOS 会使用宿主 resolv.conf, 与 `systemd-resolved` 互斥,
  故本 host 关闭 resolved。
- 容器内 `nix`/`nixos-rebuild` 不适用于重建自身; 镜像变更需在宿主侧重构并重新导入。
