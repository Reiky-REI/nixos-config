# NixOS 配置仓库 — NixMEOW

> 一份由人类用户与多个 AI 客户端共同维护的声明式 NixOS 配置。

## 1. AI 协作体系

本仓库的特殊之处在于：**AI 不只是工具，而是配置仓库的一等维护者**。
OpenCode / Claude Code / Codex 共享同一套注册表、纪律、经验与运行时，下面按
**注册 → 协作 → 唤起 → 护栏 → 经验 → 运行时** 六层展开。
每层只给总览与入口，细节以 `.agents/`、`.claude/`、`.opencode/` 下的对应文件为准。

### 1.1 参与方与注册 (`agents.nix`)

- 三个客户端（OpenCode / Claude Code / Codex）共用一份注册表 `agents.nix`。
- 生效范围 = `(agent, user, host)` 三向求交：`hosts` 默认全部 host，`users` 必须显式列出，`privileged = true` 还必须写非空 `hosts.allow`。
- 未知 client/user/host、空 `users`、privileged 缺 allowlist 都会在 eval 阶段直接失败。
- `flake.nix` 经 `lib/agents.nix` 派生 `agentsConfig` / `opencodeConfig` / `claudeConfig` 与 Codex 的 `config.toml`；客户端专属样板仍在各自适配层。
- **规则单一真相**：根 `AGENTS.md`（入口索引）→ `.agents/AGENTS.md`（总纪律与工作流）。
  OpenCode 经 `opencode.json` 的 `instructions` 注入，Claude Code 走 `CLAUDE.md`。
- 自研 AI 工具（cc-switch / obsidian-mcp-server / deepsec 等）由私源 `Reiky-nixpkgs` 提供。
  声明式安装、随 nix 升级，不再有「手装在家目录又被 GC 收走」的漂移。

### 1.2 协作机制

- **三级工作流**：🏃 轻量（改一行）→ 📋 标准（feature branch → build → 复盘同 commit → 合 main → 删分支）→ 🧠 复杂（先 plan + 决策记录）。
- **绝不直接改 main**：每个任务开 feature branch，改完先 `nixos-rebuild build` 验证。
- **跨 AI 通信**：`.agents/config/dialogue.sh` 结构化消息板（`post` / `list` / `ack`）与 `requests/pending/`（处理后归档到 `archive/`）。
- **开工前互查**：`git status` + `git branch -a`、`dialogue.sh list --status pending`、扫 `requests/pending/`、看最新 `retros/`、查 `known-issues.md`。

### 1.3 自动唤起与互相唤起

- **编译完自动拉起 AI**：`.agents/config/rebuild.sh` 结束后调用 `wake-agent.sh`，在调用者 Wayland 会话里开 `alacritty -e opencode --continue` 并弹桌面通知。
- **开关策略**：`switch` 默认拉起、`build` 默认不拉（避免频繁打扰）。
  `REBUILD_WAKE_AGENT=1/0` 或标记文件 `~/.config/rebuild/wake-agent` 可覆盖（`sudo` 会重置环境，用标记文件更省事）。
- **去重**：已有交互式会话在跑时只通知、不重复拉起，并往消息板留一条 `watchdog→opencode` 记录。
- **强制唤起**：`.agents/config/queue-task.sh` 加 `--wake` 参数时用 `WAKE_FORCE=1`，即使已有会话也新开一个 TUI，真正做到「干完活把 AI 叫回来」。
- **断电续命**：`home/reiky/tools/agent-resume.nix` 部署 systemd 用户单元 `agent-resume.path`（队列一有任务秒触发）+ `agent-resume.timer`（每 2 分钟兜底）。
  配合 `loginctl enable-linger`，AI 进程被杀 / 会话中断后队列照样自动消费，结果再反过来唤醒 AI。
- **跨 AI 互相唤起** = 消息板留言 + 队列 payload 里执行对方客户端的启动命令。

### 1.4 护栏机制（高危操作）

三层护栏，越靠上越贴近 AI，越靠下越贴近内核：

1. **客户端权限层（声明式、入库）**
   - `opencode.json` 的 `permissions`：shell 通配 `allow`，高危操作显式 `deny` —— `git push --force` / `rm -rf /` / `rm -rf *` / `sudo rm -rf *` / `dd if=/dev/zero of=/dev/sda` / `curl * | sh`。
   - Claude Code 走白名单：`.claude/settings.json` 只放行 `mcp__kb__*`、`git *`、`nixos-rebuild build *`、`nix eval`、`ls/find/grep/cat/mkdir/touch/cp/mv`。
     该文件由 `lib/claude-config.nix` + `.agents/config/generate-claude.sh` 生成。
2. **高危操作 shell 脚本封装（默认安全 / 默认 dry-run）**
   - `.agents/config/rebuild.sh`：`switch` 前 5 秒 PRIME 黑屏警告，统一代理 / token / 镜像源，结束后自动跑世代保留预览 —— 不鼓励裸敲 `nixos-rebuild switch`。
   - `nix-prune-generations`（`modules/common/nix-prune.nix`）：默认只预览，`-y` 才执行，且仅在剩余空间低于阈值时才删世代，`current` 世代永不删。
   - `.agents/config/commit.sh`：固定 `opencode[bot]` 身份，只推当前 feature branch。
   - `.agents/config/queue-task.sh`：长任务入队时强制严格模式 + 重试计数 + 完成标记。
3. **系统级沙箱 / 围栏**
   - `modules/services/dsh-fence.nix`：用一个加固的 systemd 服务包住 DeepSeek Harness 进程树（`ProtectSystem=strict`、home 只读 + 仅 workspace 与 `~/.dsh` 可写、`PrivateTmp`、`NoNewPrivileges`、空 `CapabilityBoundingSet`、收窄地址族）。
   - 流程铁律：删文件前留证、迁移后校验哈希、禁止 `nix-collect-garbage -d` 一刀切清世代。

### 1.5 经验体系

- **入口**：`.agents/knowledge/INDEX.md`，按需读 `.agents/knowledge/conventions.md`、`.agents/knowledge/architecture.md`、`.agents/knowledge/known-issues.md`、`.agents/knowledge/secrets.md`。
- **沉淀**：`.agents/knowledge/retros/`（复盘）、`.agents/knowledge/decisions/`（决策）、`.agents/MEMORY.md`（跨会话状态）、`.agents/SKILLS.md` 与 `.agents/skills/`（按需加载技能）。
- **语义检索 kb-mcp**：`.agents/tools/kb-mcp/` 调用本机 llama.cpp 的 Qwen3-VL-Embedding-2B（:8081）与 Qwen3-VL-Reranker-2B（:8082），混合召回 + 精排。
  支持多根模式（每个目录有自己的经验体系），语料变更由事件钩子触发重建。
- **铁律速查**见 `.agents/AGENTS.md` 与 `known-issues.md`：删前留证 / 迁移校验哈希 / 禁 `-d` 清世代 / 精确 pid 操作。

### 1.6 运行时与工具链

- **客户端适配**：`lib/opencode-config.nix`、`lib/claude-config.nix`、Codex 包装脚本（用 `-c` 注入 provider）。
- **MCP 挂载**：项目 `.mcp.json` 与 `opencode.json` 挂 `kb-mcp`；`obsidian-mcp-server` 声明式安装。
- **本地推理**：`modules/services/llama-cpp.nix`（CUDA 多实例，支撑上面的 kb 检索）。
- **无人值守三件套**：`rebuild.sh` + `wake-agent.sh` + `agent-resume`（见 1.3）。
- 更多运维细节见第 12 章「Rebuild」与 `.agents/AGENTS.md`。

## 2. 仓库目标

管理 NixOS declarative 配置，host、user 与 agent 是相互独立的注册维度，按明确绑定组合共享能力。
不同用途与硬件的 host 可以共享模块，同时只启用各自需要的功能。

## 3. 分层原则

```
machines.nix (host → roles/features/users)
  → flake.nix → lib/mk-host.nix → hosts/{HOST}/default.nix
                                   → modules/{common,roles,hardware,desktop,...}
  → users.nix (user ID → home/profile)
                                   → home/{profile}/
```

- **系统入口**：`flake.nix` 拼装输入输出 → `hosts/{HOST}/default.nix` 作为 composition root
- **系统模块**：`modules/*` 存放 NixOS 系统级选项（daemon、kernel、硬件、桌面基础设施）
- **角色模块**：`modules/roles/` 按 host 用途组合启用能力（交互 shell、管理权限、字体等）
- **用户模块**：`home/{profile}/` 存放 home-manager 用户级选项（应用、shell、editor、WM 配置）

## 4. 目录树

```
/etc/nixos/
├── users.nix                       # 用户身份注册表 (stable ID → login/home/profile)
├── agents.nix                      # AI agent 注册表 (client/model/system/hosts/users)
├── config.nix                      # users.nix 的兼容视图，旧脚本过渡用
├── machines.nix                    # host 注册表 (hostname → roles/features/users/桌面设备映射)
├── flake.nix                       # 入口：inputs + mkHost 装配 (由注册表驱动)
├── flake.lock                      # 锁定依赖版本
├── justfile                        # 常用命令
├── opencode.json                   # OpenCode AI 配置
├── CLAUDE.md                       # Claude Code 工作指南
├── AGENTS.md                       # AI 辅助工作指南
├── docs/
│   ├── config-reproducibility.md    # 配置来源、可变状态与密钥边界
│   ├── archive/retired-integrations/ # 已退役服务与加密数据归档记录
│   ├── NixMEOW-WSL.md              # WSL 试验台的完整文档 (访问/网络/排障)
│   └── NixMEOW-CTR.md              # Docker 容器镜像 (构建/导入/运行约束)
├── hosts/
│   ├── NixMEOW/                    # 目录名 = 主机名 (machines.nix 的 key)
│   │   ├── default.nix            # Composition root (仅 imports + host-specific)
│   │   ├── boot-menu.nix          # 第一级启动菜单 (双系统 OS 选择, 仅本机 import)
│   │   ├── hardware.nix           # Host-specific 硬件策略（内核参数等）
│   │   └── hardware-configuration.nix  # nixos-generate-config 生成，不动
│   ├── NixMEOW-WSL/                # Windows WSL2 试验台 (详见 docs/NixMEOW-WSL.md)
│   │   └── default.nix
│   └── NixMEOW-CTR/                # Docker systemd 容器镜像 (详见 docs/NixMEOW-CTR.md)
│       └── default.nix
├── modules/
│   ├── default.nix                # 聚合所有子模块
│   ├── common/                    # 所有 host 通用的系统基础 + hardware profile + meow.* 选项
│   ├── roles/                     # 按 host 用途组合启用能力 (交互 shell/管理权限/字体)
│   ├── hardware/                  # CPU/GPU/蓝牙/设备策略 (微码与固件放 host 本地)
│   ├── desktop/                   # 桌面会话栈 (niri, ly, fcitx5, tablet, backlight)
│   ├── networking/                # 网络/代理/防火墙/SSH
│   ├── services/                  # 后台 daemon / 系统服务 (PipeWire, MPD, Flatpak)
│   ├── development/               # 开发工具链 (opencode 等)
│   ├── storage/                    # 存储与远程挂载 (NAS/SMB/NTFS 等)
│   ├── documentation/              # man 手册等文档工具 (按 role 启用)
│   └── virtualization/            # Podman, libvirtd
├── home/
│   └── reiky/                     # 可复用 Home Manager 配置集，由 users.nix.homeProfile 绑定
│       ├── default.nix            # 用户态入口 (按 meow.roles / features 分组自我屏蔽)
│       ├── desktop/               # 桌面态配置 (niri, noctalia, rofi, wallpaper)
│       ├── shell/                 # Zsh
│       ├── terminal/              # Kitty / Alacritty (仅桌面 host)
│       ├── editors/               # Neovim 等; desktop.nix 放 GUI 编辑器
│       ├── apps/                  # 浏览器、社交、媒体、办公 (workstation 专属)
│       ├── music/                 # 音乐播放器 (workstation 专属)
│       ├── dev/                   # AI CLI 工具 (claude-code / codex)
│       ├── lib/                   # JSON 合并激活辅助 (merge-json-activation.nix)
│       └── tools/                 # 系统工具、搜索、查看器; desktop.nix 放桌面专用工具
├── lib/
│   ├── mk-host.nix                 # 由 machines.nix 注册表生成 nixosConfigurations
│   ├── features.nix                # 已知 feature ID 清单，拼写错误在 eval 时失败
│   ├── roles.nix                   # 已知 role ID 清单
│   ├── agents.nix                  # agent 注册表解析/校验/按 host+user 求交
│   ├── claude-config.nix          # Claude Code 配置生成
│   └── opencode-config.nix        # OpenCode 配置生成
├── pkgs/
│   └── cursors/                   # MikuCat 光标主题
├── secrets/                       # 加密密钥 (agenix)
├── .agents/                       # AI 约定/知识库/复盘与 agent-resume 长任务队列
├── .claude/                       # Claude Code 项目配置
└── .opencode/                     # OpenCode 项目配置
```

## 5. 各层职责

| 层 | 目录 | 放什么 | 不放什么 |
|----|------|--------|----------|
| 全局基础 | `modules/common/` | `nix.settings`, `nixpkgs.config`, `time`, `i18n`, `nix.gc`, `nix.pruneGenerations`, `nix-ld`, `hardware.profile` | 交互 shell、桌面策略、硬件驱动、daemon |
| 角色 | `modules/roles/` | 按 role 启用的交互能力（字体、`programs.zsh`、sudo 免密、polkit wheel 规则） | 具体设备或桌面实现 |
| 硬件 | `modules/hardware/` | GPU 图形栈、蓝牙、通用硬件包（微码/固件放 host） | 软件包、桌面、服务策略 |
| 桌面 | `modules/desktop/` | Niri 系统级启用、Ly display manager、XWayland、Steam、fcitx5、Wayland env vars | 用户态 WM 配置、主题文件 |
| 网络 | `modules/networking/` | NetworkManager、代理、防火墙、SSH | 网络应用（浏览器等） |
| 服务 | `modules/services/` | PipeWire、MPD、Flatpak、CUPS、udisks2、电源管理 | 用户交互应用 |
| 开发 | `modules/development/` | wine 等 | 编辑器配置（放 home） |
| 存储 | `modules/storage/` | NAS/SMB 挂载等存储配置 | 用户数据、备份策略 |
| 文档 | `modules/documentation/` | man 手册等文档工具（按 workstation/devbox role 启用） | 知识库内容（放 `.agents/`） |
| 虚拟化 | `modules/virtualization/` | Docker、libvirtd、Waydroid | 容器内应用配置 |
| 用户态 | `home/{profile}/` | 应用、shell、编辑器、WM 配置文件、终端工具 | 系统 daemon、内核参数 |

### 壁纸管理

壁纸由 **Noctalia 自带渲染** (`noctalia-background` 顶层 layer) 统一管理，**已弃用 awww/swww**（2026-09-26）：

- 静态壁纸：`~/Pictures/Wallpapers/static/`（用户自管，不经 nix 部署）
- 视频壁纸：`~/Pictures/Wallpapers/videos/`（暂用 mpvpaper；受 Noctalia 顶层背景限制，待迁移到 Noctalia video-wallpaper 插件）
- 切换快捷键 `Mod+Shift+W` → `~/.config/wallpaper/script/wallpaper-rofi.sh`（rofi 选图，经 `noctalia-shell ipc call wallpaper set` 设置）
- 配置位置：`home/reiky/desktop/wallpaper/`

### 双系统启动菜单 (MEOW Boot Menu, 仅 NixMEOW)

UEFI 启动链是两级的：固件 → **MEOW Boot Menu**（自建 GRUB，选系统）→ 选 NixOS 时再进 systemd-boot 选世代。

- 模块：`hosts/NixMEOW/boot-menu.nix`（host 本地设备事实；无 Windows 的 host 不 import）
  - 单文件 EFI `grubx64.efi`（grub-mkstandalone 内嵌 Catppuccin Mocha 主题 / 28px 字体 / 图标 / 全部模块），经 systemd-boot 的 `extraFiles` 部署到 `/EFI/MEOW-OS/`
  - 默认项 = 上次选择的系统（`grubenv` 的 `saved_entry`，`meow-boot-menu.service` 幂等维护 + 启动项路径自愈）
  - Windows 项 chainload `bootmgfw.efi`；不删除任何原有启动项（F12 → Linux Boot Manager 永远兜底）
- 背景（运行期生成，统一 50% 黑遮罩；第三方图不入 git）：
  - `boot-background-nixos.png` ← Noctalia 当前壁纸（或 `~/.config/meow-boot/background` 软链/一行路径指定）
  - `boot-background-windows.png` ← Windows `TranscodedWallpaper`
  - 二者缺失时回退内嵌的 Catppuccin 官方背景（`meow-boot-menu-wallpaper.{service,path}` 负责刷新）
- 调整：字体大小 / 遮罩强度 / 主题模板都在 `boot-menu.nix`；背景切换优先级见上
- 详见复盘 `retros/2026-10-01-stage1-grub-os-selector.md`（文件名保留历史命名）与决策 `decisions/two-stage-boot-grub-systemd-boot.md`

### 世代保留策略 (nix-prune-generations)

systemd-boot 菜单只列出**当前存活的 system profile 世代**——世代被删，菜单条目随之消失，不在失败清单上。
策略核心是**空间闸门**（规则与动机见 `modules/common/nix-prune.nix` 头注释）：

| 条件 | 行为 |
|------|------|
| 剩余空间 ≥ `nix.pruneGenerations.minFree`（默认 15G） | **什么都不删**——世代是回滚保单，宁可多留 |
| 剩余空间 < 阈值 | 7 天内全留 + 7 天外保留最新 5 条，其余删除，然后 `nix-store --gc` 回收 |

- 每日 00:00 的 `nix-gc` **只做 store 回收，不删世代**（`options = ""`，删除职责全部收口在 prune）
- `rebuild.sh switch/test/boot` 成功后自动跑一次 prune 预览（dry-run，只在空间不够时列出可删清单）
- 手动：`sudo nix-prune-generations` 预览 / `sudo nix-prune-generations -y` 执行
- ⚠️ **禁止 `nix-collect-garbage -d` / `nix-env --delete-generations old`**：一刀切清光回滚点（2026-10-04 曾导致 boot 菜单只剩一个世代、无法回滚，复盘 `retros/2026-10-05-boot-generation-gc.md`）

## 6. 职责边界

| 角色 | 职责 |
|------|------|
| **Host** (`hosts/{HOST}/`) | 仅作 composition root：imports + host-specific 配置（用户定义、hostname、boot loader、stateVersion） |
| **Module** (`modules/*`) | NixOS 系统选项：daemon、kernel、hardware、系统能力、图形会话基础设施 |
| **Home** (`home/{username}/`) | home-manager 用户选项：应用、shell、editor、WM config、终端工具、用户偏好 |

### 系统层 vs Home 层

- **系统层 (NixOS modules)**：`services.mpd`, `services.pipewire`, `virtualisation.docker`, `services.openssh`, `services.flatpak`, `hardware.nvidia`, `programs.niri`, `services.displayManager`
- **Home 层 (home-manager)**：`programs.kitty`, `programs.rofi`, `programs.waybar`, `programs.wlogout`, `programs.zsh`, `programs.bat`, `programs.fzf`, home 文件部署

## 7. 机器注册与特性标签 (meow.*)

本仓库支持多机器共享配置，通过 **machines.nix** 注册每台机器的标签：

```nix
# machines.nix
{
  "NixMEOW" = {
    system = "x86_64-linux";   # 可省略, 默认 x86_64-linux
    profile = "high";          # 硬件档位: high/medium/low (构建并行度)
    kind = "laptop";           # 机器种类: laptop/desktop/wsl/vm
    roles = [ "workstation" ]; # 用途组合: workstation/devbox/server/embedded
    desktopEffects = "full";   # 桌面效果档: full/minimal
    users = [ "reiky" ];       # users.nix 中的稳定身份 ID
    primaryUser = "reiky";     # 尚未迁移的单用户 system module 的兼容身份
    features = [ "bluetooth" "gpu-nvidia" "compositor-niri" ... ];  # 特性标签
    note = "主力机 — RTX 4070 + AMD 核显";
  };
  "NixMEOW-WSL" = {
    profile = "medium";
    kind = "wsl";
    roles = [ "devbox" ];
    desktopEffects = "minimal";
    users = [ "reiky" ];
    primaryUser = "reiky";
    features = [ "compositor-niri" ];
    note = "Windows WSL2 试验台";
  };
}
```

**各组字段的用法不同**：

| 字段 | 决定什么 | 消费方式 |
|------|---------|---------|
| **profile** | 硬件性能档（构建并行度、性能布尔量） | `hardware.profile`（`isHighPerf` 等，也传给 home-manager） |
| **roles** | 用途组合（是否要交互 shell、桌面、管理权限） | 各模块读 `config.meow.roles` 自我屏蔽 |
| **desktopEffects** | 桌面效果档（full/minimal） | niri 选择 kdl 段等 |
| **kind** | 设备形态/运行环境（laptop/desktop/wsl/vm） | 平台差异判断（如 WSL 代理端口、Mod 键） |
| **features** | 可组合能力开关 | 各模块 `lib.mkIf (config.meow.enabled ? "tag")` 自我屏蔽 |
| **users / primaryUser** | 该 host 部署哪些身份、legacy 单用户回退 | `lib/mk-host.nix` 生成系统账号与 Home Manager 用户 |

- feature / role ID 清单分别在 `lib/features.nix`、`lib/roles.nix`，未知标签会导致 eval 失败
- flake 级标签（`kernel-715` / `agenix-secrets`）由 `lib/mk-host.nix` 消费
- `meow` 同样注入 home-manager (`extraSpecialArgs`)，`home/reiky/default.nix`
  按 role/能力分组自我屏蔽（如 server 角色不导入桌面与 GUI 应用组）
- `kind=container` 的 host 会关闭 systemd-resolved 与文档包，镜像产物暴露为
  `packages.<system>.<host>-docker`（见 `docs/NixMEOW-CTR.md`）

### 用户身份与 host 绑定

`users.nix` 使用稳定 ID 注册登录名、home 路径和可复用 Home Manager profile；每个 host 通过 `machines.nix.users` 显式绑定一个或多个身份。当前 NixMEOW 与 WSL 都绑定 `reiky`，原 `home/reiky/` 目录继续使用；`config.nix` 暂时保留为兼容视图。`primaryUser` 仅供仍采用单一默认用户的系统模块兼容使用，新代码应使用 host 的 user 列表或具体 user 身份。

### AI agent 注册 (`agents.nix`)

三个客户端共用一份注册表 `agents.nix`，按 `(agent, user, host)` 三向求交决定生效范围。
完整机制（注册规则、协作流程、唤起、护栏、经验体系、运行时）见 [第 1 章「AI 协作体系」](#1-ai-协作体系)。

### 添加新机器（**不需要动 flake.nix**）

```bash
# 1. 生成新机器的硬件配置
nixos-generate-config --root /mnt
# 得到 /mnt/etc/nixos/hardware-configuration.nix

# 2. 在 machines.nix 注册 (hostname + profile + kind + roles + features + users)

# 3. 创建 hosts/<hostname>/default.nix (imports ../../modules + 本机专属配置)
#    ⚠ 目录名必须与 machines.nix 的 key 一致

# 4. 构建
nixos-rebuild build --flake /etc/nixos#<hostname>
```

`nixosConfigurations` 由 `lib/mk-host.nix` 依据 machines.nix 自动生成 —— 新增机器 =
**machines.nix 写一行 + hosts/<hostname>/ 建一个目录**，不复贴 flake.nix。

**注意**：未在 `machines.nix` 注册的 hostname 会直接 `abort` 报错退出，防止意外部署。

## 8. 如何新增一个系统模块



```bash
# 1. 创建模块目录
mkdir -p modules/<category>/<module-name>
touch modules/<category>/<module-name>/default.nix

# 2. 在 default.nix 中编写 NixOS 选项
# 3. 在 modules/<category>/default.nix 中添加 import
# （或如果你的模块是独立新分类，在 modules/default.nix 中添加）
```

## 9. 如何新增一个 home module

> `{profile}` 是 `users.nix` 的 `homeProfile` 字段，当前为 `reiky`（与登录名一致），字段保留以支持多身份/多用户复用。

```bash
# 1. 创建模块目录
mkdir -p home/{profile}/<module-name>
touch home/{profile}/<module-name>/default.nix

# 2. 在 default.nix 中编写 home-manager 选项
# 3. 在 home/{profile}/default.nix 的 imports 中添加 ./<module-name>
```

## 10. 软件归类判断规则

| 类别 | 判断标准 | 示例 |
|------|----------|------|
| `services/` | daemon / 后台长期运行 | `openssh`, `flatpak`, `mpd`, `pipewire`, `docker` |
| `desktop/` | 图形会话入口 / Wayland 栈 | `programs.niri`, `programs.hyprland`(legacy), `displayManager`, `xwayland`, `fcitx5` |
| `home/` | 用户交互应用 / 个人偏好 | `kitty`, `rofi`, `mpv`, `waybar`, `go-musicfox`, `yazi`, `fastfetch`, `TERMINAL` |
| `hardware/` | 硬件驱动和微码 | NVIDIA 驱动, intel-media-driver, bluetooth, CPU microcode |
| `common/` | 全局基础设置 | timezone, locale, fonts, nix settings, sudo, hardware profile |
| `development/` | 系统级开发工具链 | wine, 编译器 |

**环境变量归类**：
- `NIXOS_OZONE_WL` → `modules/desktop/`
- `QT_IM_MODULE` / `XMODIFIERS` → `modules/desktop/fcitx5/`
- `TERMINAL` → `home/{username}/`
- `XDG_DATA_DIRS` (flatpak) → `modules/services/`

## 11. Just 命令

```bash
just generate-opencode    # 生成 OpenCode 配置
just generate-claude      # 生成 Claude Code 配置
just generate-all         # 上面两个一起生成
just fmt                  # 格式化所有 nix 文件 (alejandra)
just check-fmt            # 预览格式化改动
just lint                 # 静态分析 (statix)
just check                # 完整验证：fmt check + lint + nix flake check
just rebuild              # 构建配置 (build 模式，不 switch)
just switch               # 切换系统 (经 rebuild.sh，结束后自动做世代保留预览)
just install-apk name url # 下载 APK 并安装到 Waydroid
```

## 12. Rebuild

```bash
# 使用 .agents/config/rebuild.sh (自动设置 proxy + GitHub token)
sudo .agents/config/rebuild.sh              # dry-activate (默认)
sudo .agents/config/rebuild.sh build        # 构建验证（推荐）
sudo .agents/config/rebuild.sh switch       # 实际切换（⚠️ NVIDIA PRIME 崩溃风险）

# 或手动执行
nixos-rebuild build --flake /etc/nixos#NixMEOW
```

> **⚠️ NVIDIA PRIME 系统**：`switch` 会重启 polkit → compositor 失去 DRM master → 黑屏。
> 日常验证用 `build` + 手动 `reboot`，避免直接 `switch`。

### 编译完成自动拉起 AI (默认 switch 开)

每次 `build`/`switch` 结束时都会尝试"唤醒 AI"：在你的会话里弹桌面通知，
并在**没有**其它 OpenCode 会话运行时开一个 `opencode --continue` 终端。
若已有交互会话在跑，则只通知、不重复拉起。

默认策略：**`switch` 开，`build` 关**（`build` 太频繁，避免打扰）。

```bash
# 强制开 / 强制关
sudo REBUILD_WAKE_AGENT=1 .agents/config/rebuild.sh build
sudo REBUILD_WAKE_AGENT=0 .agents/config/rebuild.sh switch

# 或标记文件 (sudo 会重置环境, 这个更省事): 让 build 也拉起
mkdir -p ~/.config/rebuild && touch ~/.config/rebuild/wake-agent
```

实现见 `.agents/config/wake-agent.sh`（由 `rebuild.sh` 在 nixos-rebuild 结束后调用，
成功/失败都会尝试）。

### 不可中断长任务 (agent-resume)

长任务通过用户级 systemd 队列执行，与 OpenCode 会话生命周期解耦。

- Home Manager 声明 `agent-resume.service/path/timer`，配置见 `home/reiky/tools/agent-resume.nix`。
- runner 唯一源码为 `.agents/config/agent-resume-runner.sh`，启动时会恢复遗留 `running/` 任务。
- 推荐用 `.agents/config/queue-task.sh` 入队，自动启用严格错误处理、重试计数与 payload 完成标记。

```bash
.agents/config/queue-task.sh \
  --id rebuild-check-20260927 --desc '长任务说明' \
  --exec 'nix build --no-link .#nixosConfigurations.NixMEOW.config.system.build.toplevel' \
  --runtime-max 3600 --max-retries 3 --wake
```

`--wake` 会在任务结束后强制拉起 `opencode --continue`，即使已有交互会话也会新开窗口。
任务状态、日志与使用纪律见 `.agents/AGENTS.md`。runner 回归测试为
`bash .agents/config/test-agent-resume-runner.sh`。

## 13. 排查配置归属错误

- 选项不存在 → 检查模块是否在正确的层（系统 vs home），以及是否被导入
- 选项冲突 → 在对应模块的 `default.nix` 中搜索该选项定义
- 行为不符合预期 → 检查 `hosts/{HOST}/default.nix` 是否包含不应在 composition root 中的配置
- 找不到模块 → 检查 `modules/default.nix` 或 `home/{username}/default.nix` 的 imports

## 14. WSL2 试验台 (NixMEOW-WSL)

第二台"机器"：Windows WSL2 里跑的 NixOS，定位是**无 NVIDIA 黑屏风险的 switch 迭代场** +
嵌套 niri 桌面。完整文档见 **[docs/NixMEOW-WSL.md](docs/NixMEOW-WSL.md)**，覆盖：

- 安装/重建流程 (VHD 50G 上限)
- 网络三件套: 宿主 Clash 代理 / 代理环境 / nixrun.sh
- browser-* 服务组 (Xvfb + niri + x11vnc + noVNC + noctalia) 与踩坑
- 从浏览器访问 (`localhost:8080`, portproxy + 保活计划任务)
- 运行时活文件同步清单 (noctalia/cliphist/zsh_history/opencode)

铁律: 试验台上 `nixos-rebuild switch` 随便跑；真机仍然只 `build`，switch 由人工执行。
