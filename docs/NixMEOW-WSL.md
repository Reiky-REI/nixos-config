# NixMEOW-WSL — Windows WSL2 上的 NixOS 试验台

> 2026-09-22~23 建立。目标: 无 NVIDIA 黑屏风险的 NixOS switch 迭代场 + 嵌套 niri 桌面,
> 所有会话相关的东西**都能自愈**(见"故障排查"一节)喵~
> 决策记录: `.agents/dialogue/2026-09-22-refactor-multi-host.md`

## 1. 定位与形态

| 项 | 值 |
|----|----|
| 发行版名 | `NixMEOW-WSL` (machines.nix: kind=wsl, profile=medium) |
| 虚拟磁盘 | `C:\WSL\NixMEOW-WSL\ext4.vhdx`, 上限 **50G**(安装时 `--vhd-size` 一次到位) |
| 安装来源 | NixOS-WSL 镜像 + 本仓库的 `nixosConfigurations.NixMEOW-WSL` |
| 桌面 | 嵌套 niri (Xvfb X11 后端 + noctalia 软件渲染壳层) |
| 主要用途 | 1) 架构重构的安全试验场 2) 无 GPU 环境下验证配置 3) 浏览器远程桌面 |

**铁律**: 在这台机子上 `nixos-rebuild switch` **随便跑** — 没有 NVIDIA 黑屏风险;
真机 (NixMEOW) 上仍然只 `build`, switch/explore 必须人工点击。

## 2. 安装与重建 (从零恢复的完整流程)

```powershell
# 1. 安装发行版 (VHD 上限一次到位)
wsl --install --from-file <nixos.wsl> --name NixMEOW-WSL --location C:\WSL\NixMEOW-WSL --vhd-size 50GB --no-launch
# nixos.wsl 来官方 release, 下载后 SHA256 校验过再装

# 2. 首次启动后 (systemd 已启用): 用户 nixos 的默认 u-nit 配置还在 /etc/nixos 下
#    首次启动提示后运行 sudo nix-channel --update (需要网络放开, 见 §3 网络)
```

**从 GitHub 拉本仓库进 WSL** (WSL 内没 git, 用 nixos-rebuild 之外的 nix-shell):

```powershell
# 先拉原始仓库 (私有 git 通过 token, 或在 Windows 侧 clone 后走 UNC 拷贝)
wsl -d NixMEOW-WSL -- nix-shell -p git --run "git clone https://github.com/Reiky-REI/nixos-config.git ~/nixos-config"
```

## 3. 网络 — 三条路，全在宿主 Clash

```
WSL2 NAT 模式下, WSL 里的 127.0.0.1 就是 Windows 的 127.0.0.1 (.wslconfig 的 hostAddressLoopback=true)
→ 代理环境变量直接写 http://127.0.0.1:7890 (不需要算网关 IP)
```
- GitHub 直连**极不稳定**，所有 CLI (nix/git) 走 Clash 才稳: `22MB/s` vs 几 KB/s
- nixpkgs 国内镜像在 WSL NAT 下超时/降级 (`mirrors.tuna`/`ustc` 会 TLS EOF 和超时),
  **只信 cache.nixos.org** (见 machines 配置 `nix.settings.substituters = mkForce [...]`)
- 走代理大文件必须 **http2=false** (真机 flake 里那个 `http2=false` 注释已说明原因)

**代理 + token 已声明式化 (2026-09-27 收尾)** 喵~

- `hosts/NixMEOW-WSL/default.nix` 里:
  - `systemd.services.nix-daemon.environment = { http_proxy/https_proxy = http://127.0.0.1:7890; }`
    ⚠️ Nix **没有** nix.conf 的 `proxy` 选项 (文档旧写法 `echo "proxy=..." >> /etc/nix/nix.conf`
    其实无效), daemon 出网只能靠环境变量。
  - `nix.settings.substituters = mkForce [cache.nixos.org]` + `http2 = false` (原有)。
- 手工重建用 **`wsl-rebuild`** 包装 (替代旧的 tmpfs `/root/nixrun.sh`):

  ```bash
  wsl-rebuild build  --flake ~/nixos-config#NixMEOW-WSL
  sudo wsl-rebuild switch --flake ~/nixos-config#NixMEOW-WSL
  ```

  它自动带代理, 并在有 token 文件时注入 `access-tokens`:
  - 普通用户: `~/.config/nix/access-token` (一行)
  - root/switch: `/etc/nix/access-token`

  找不到就跳过 —— 公开 flake 输入本身不需要 token, 只是为了避开 GitHub 限流。

## 4. 桌面服务组 (browser-*) — 每个组件一个 systemd 服务

```
浏览器 --websocket--> websockify(0.0.0.0:8080) → x11vnc(:5901)
       → Xvfb(:93, 1920x1080x24) → niri(winit/X11, 软件渲染)
                        └─ spawn-at-startup → noctalia(but 服务化接管, 见 browser-noctalia)
```

| 单元 | 说明 |
|------|------|
| `browser-xvfb` | 无硬件 GL 的 X server, 软渲画 1920x1080 |
| `browser-niri` | winit/X11 后端; **必须设 `LD_LIBRARY_PATH` (libXcursor/libXrandr/libXi/libXinerama)** + `WINIT_UNIX_BACKEND=x11` + HOME/XDG_RUNTIME_DIR |
| `browser-niri` 的 `ExecStartPost` | 用 `xdotool` 把无 WM 环境里 winit 默认尺寸的窗口钉满 1920x1080 (X 直接调用, 不需要外层 WM) |
| `browser-vnc` | x11vnc `-passwd` 提供 VNC 通道 |
| `browser-novnc` | websockify (python3Packages) 静态 noVNC 页面 + ws 桥 |
| `browser-noctalia` | noctalia-shell 壳层, `QT_QUICK_BACKEND=software` 软渲, **不依赖** niri spawn-at-startup (那个走 systemd-run --user, 时机不稳) — 脚本自己找最新的 niri socket (`ls -t /run/user/1000/niri.*.sock \| head -1`) |

全部 `Restart = "always"` + `RestartSec = "3"` + `User = Reiky-REI` — 崩了自动复活。

### 为什么必须 `loginctl enable-linger Reiky-REI`

logind 的 `RemoveIPC` 默认 yes —— 最后一个 Reiky-REI 会话结束时:
`/run/user/1000` 被删除 + user systemd manager 被关闭 →
niri 的 IPC socket 落盘失败 → PermissionDenied 崩溃循环 → VNC 黑屏。
这是 whole-browser-* 组 "vnc 通但黑屏"的根因 (2026-09-23)。已 linger 持久化。

`/run/user/1000` 同时由 systemd-tmpfiles 提前创建 (listen 没起用户会话时兜底)。

### niri 服务的环境变量清单 (一个都不能漏)

| env | 为什么 |
|-----|--------|
| `DISPLAY=:93` | X11 后端连接 Xvfb |
| `WINIT_UNIX_BACKEND=x11` | 防止 WSL 注入的 `WAYLAND_DISPLAY` 抢走后端 |
| `LD_LIBRARY_PATH = lib.makeLibraryPath [ libXcursor libXrandr libXi libXinerama ]` | winit X11 后端运行时 dlopen |
| `HOME / XDG_RUNTIME_DIR` | IPC socket / noctalia |
| `PATH = mkForce (...)` | **保留** systemd 模块注入的基础二进制目录 + 用户 profile (`noctalia-shell`/xwayland-satellite 都在用户 profile)。不 mkForce 会与 systemd 默认 PATH 同优先级冲突 |
| `QT_QUICK_BACKEND=software` | 无 GPU 环境 QML 没硬件 GL |

## 5. 访问方式

### 5.1 浏览器 (局域网任何设备)

```
http://localhost:8080/vnc.html?autoconnect=1     密码: meow-8080-lan (在 default.nix vncPass)
http://<宿主机局域网IP>:8080/vnc.html             其他设备
```

局域网暴露依赖三层, 已配好:
1. netsh portproxy 0.0.0.0:8080 → WSL IP (需要 UAC 一次性)
2. 防火墙规则 `WSL noVNC 8080`
3. **计划任务 `WSL-noVNC-portproxy` (SYSTEM)**: 每次登录自动重写 portproxy (WSL IP 会变) + **保活 WSL VM** (`wsl sleep infinity`, 防 60s 空闲回收), 脚本 `C:\WSL\novnc-portproxy-refresh.ps1`

**保留动作**: 如果 `wsl --shutdown` 后浏览器死连接, 跑一次
`powershell -File C:\WSL\novnc-portproxy-refresh.ps1` 即可 (会顺带拉起 VM)。

### 5.2 WSLg 原生 (更快)

```powershell
wsl -d NixMEOW-WSL -u Reiky-REI -- niri
```
同一个配置文件, 但走 Windows 原生窗口 (WSLg) — 到目前这种方式更流畅, 剪切板也直接通。

### 5.3 终端/opencode

```powershell
wsl -d NixMEOW-WSL -u Reiky-REI
opencode   # 配置+auth 已从真机同步
```

## 6. 同步的运行时活文件 (不在 git 仓库)

| WSL 内 | 来自真机 | 用途 |
|--------|---------|------|
| `~/.config/niri/config.kdl` | HM 自动生成 ✓ (替换 Mod→Alt) | 不用管 |
| `~/.config/noctalia/` (18M) | `/mnt/wsl/PHYSICALDRIVE1p2/home/Reiky-REI/.config/noctalia` | 主题/小组件 |
| `~/.cache/cliphist/` (26M) | 同上 `.cache/cliphist` | 剪切板历史 |
| `~/.zsh_history` | 同上 | 终端自动补全的"燃料" |
| `~/.local/share/opencode/{auth.json}` + `~/.config/opencode/` | 真机 | opencode 登录态 |
| `~/.config/opencode/plugins` (含 node_modules) | 真机 | noVNC 云的插件 |

同步方法: 从挂载盘拷 (需 root, 见 AGENTS.md WSL 章节) 或用 `scp`/共享路径。

### 6.1 知识层 `~/.agents` — 共享知识库 (2026-09-27)

`~/.agents`（skills / rules / knowledge / memory / dialogue）**不在 nixos-config 仓库里**,
是独立 git 仓。它现在有了私有远端, 双系统共享知识层就靠它喵~:

```bash
# WSL / Windows 侧首次:
git clone git@github.com:Reiky-REI/agents-knowledge.git ~/.agents

# 已有旧本地仓 → 接上远端:
git -C ~/.agents remote add origin git@github.com:Reiky-REI/agents-knowledge.git
git -C ~/.agents fetch origin && git -C ~/.agents reset --hard origin/main
```

口径喵: **配置靠 `nixos-rebuild` 复现 (同一份 flake), 知识层靠 `git clone/pull` 同步 (同一个仓)**,
两边从此是同一套, 不再"各有一份、靠拷文件对齐"喵~

## 7. 故障排查速查

```bash
# 谁死了谁复活, 重启了几次:
systemctl show browser-novnc -p NRestarts,Result,ExecMainStatus
systemctl status browser-niri --no-pager -l      # ExecStartPost 阻塞, 起过几次
journalctl -u browser-niri -n 20 --no-pager      # 每个 browser-* 都有独立的 journal

# 当前 VNC socket 生死:
/run/current-system/sw/bin/ss -tlnp | grep -E ":8080|:5901"

# WSL VM 是否在跑(重要: 静置 60s 会自动回收, 保活靠 Windows 侧计划任务):
wsl -l -v
```

**已知问题** (待解决/接受的):
1. **noVNC "Failed to connect to server"** — 100% 开页面成功但 ws 握手失败，
   WSL 内部裸握手正常，怀疑与 `portproxy` 或 NoVNC 的反向代理有关 (待查)。
   **绕过**: WSLg 原生窗口 ✓ 价格更高体验更好
2. Xvfb 无 GPU 软渲染 — 桌面慢, 小组件动画低帧; noctalia 的额外效果会卡
3. `xwyland-satellite` spawn 失败 → X11 应用无论 Xvfb 还是 WSLg 均处理不了;
   WSL native 桌面只有 Wayland 应用 (alacritty ✓)
4. `dsh-fence`/`astrabot` 等真机服务不在试验台 (特性标签未全部开启)
5. squash: 夜里 6 小时未动手 wsl VM 会退出 (keepalive 脚本已做 但可能失效)

## 8. 迭代手册 (改配置 → build → switch)

```powershell
# Windows 侧编辑: \\wsl.localhost\NixMEOW-WSL\home\nixos\nixos-config\
# WSL 侧 (root) :

cd /home/nixos/nixos-config
/root/nixrun.sh build "path:.#nixosConfigurations.NixMEOW-WSL.config.system.build.toplevel" --out-link /root/result-wsl
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
nixos-rebuild switch --flake path:.#NixMEOW-WSL
```

- `switch` 前不需要手工下载任何东西 (nixrun 走宿主 clash)
- `swap` 里 `#NixMEOW` 全量 reproducible build 验证 (零行为变化的硬指标, 见决策记录)
- git 用 `nix-shell -p git --run ...` 或 Windows 侧 UNC 路径 (`\\wsl.localhost\...`) 操作
- PATH 环境: nixos 用户模式下 git 可用; root 模式在真机(非仓库 owner)会 rejected, 用 `nixos` 用户
