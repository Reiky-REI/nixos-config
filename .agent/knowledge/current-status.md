# 当前系统状态基线

> 本文档记录 NixMEOW 的**已有功能**和**构建进度**。  
> AI 每次会话前必读，避免重复。每次完成新功能后必须更新。

---

## ✅ 已实现的功能

### 核心系统
- ✅ NixOS 25.11 (flake-based, 模块化)
- ✅ Niri WM（Wayland compositor）
- ✅ Hyprland（可选备用 WM）
- ✅ systemd-boot
- ✅ Intel CPU 微码

### 硬件驱动
- ✅ NVIDIA RTX 4070 (CUDA + PRIME)
- ✅ Intel 媒体驱动 (VA-API)
- ✅ MediaTek MT7922 蓝牙 (已打内核补丁)
- ✅ 音频 (PipeWire)

### 输入和显示
- ✅ fcitx5 中文输入法 (Super+Space 切换)
- ✅ kitty + alacritty 终端
- ✅ Rofi 启动器
- ✅ Adwaita 光标

### 网络
- ✅ NetworkManager
- ✅ Clash Verge (TUN 模式, localhost:7897)
- ✅ OpenSSH

### 密钥管理
- ✅ agenix (age 加密, ai_api_key_REIKY_REI)
- ✅ GitHub token (`.agent/config/token`)

### 用户态
- ✅ zsh + powerlevel10k
- ✅ Neovim (CookNixvim)
- ✅ Home-manager (声明式用户配置)
- ✅ Noctalia Shell

### 开发工具
- ✅ CUDA Toolkit
- ✅ Wine + Winetricks
- ✅ Docker (已启用)
- ✅ Flatpak

### 知识管理
- ✅ `.agent/knowledge/` AI 知识库
- ✅ `.agent/knowledge/session-logs/` 复盘记录
- ✅ `.agent/knowledge/troubleshooting/` 解决方案库
- ✅ `.agent/knowledge/FAQ.md` 常见问题索引
- ✅ `.agent/blueprint/` 蓝图设计文档
- ✅ `.agent/STARTUP.md` AI 启动清单
- ✅ `.agent/knowledge/boundaries.md` AI 权限边界

### 自动化
- ✅ `.agent/config/rebuild.sh` 一键 rebuild
- ✅ `.agent/config/env.sh` 环境变量注入

---

## ⚪ AI 构建进度

### Phase 1: 基础设施
- ⚪ Step 1: flake.nix 集成 llm-agents.nix + mcp-nixos
- ⚪ Step 2: ollama + CUDA 推理服务
- ⚪ Step 3: 创建 ai-agent + ai-sentinel 用户
- ⚪ Step 4: 手工验证文件整理管道可行性

### Phase 2: 技能系统
- ⚪ Step 5: organize-tool Nix derivation
- ⚪ Step 6: file-organizer SKILL.md
- ⚪ Step 7: 首次真实运行 + 复盘

### Phase 3: Agent 运行时 + 安全
- ⚪ Step 8: openclaw 常驻服务
- ⚪ Step 9: vulnix CVE 扫描
- ⚪ Step 10: 第一个 systemd timer

### Phase 4: 自进化 + 经验管道
- ⚪ Step 11: knowledge-recorder 自动复盘
- ⚪ Step 12: 社区 RSS 监控
- ⚪ Step 13: gno 知识库索引

### Phase 5: 哨兵 + 宪法 + 权限编排
- ⚪ Step 14: 权限转声明式 Nix 配置
- ⚪ Step 15: CONSTITUTION.md 就位
- ⚪ Step 16: 第一个哨兵规则

### Phase 6: 学习陪伴 + 发布
- ⚪ Step 17: learn-companion 框架
- ⚪ Step 18: 经验沉淀到 .ai-rules.toml

---

## 关键文件索引

```
/etc/nixos/flake.nix                          系统入口
/etc/nixos/hosts/MEOW/default.nix             Host 聚合
/etc/nixos/hosts/MEOW/hardware.nix            硬件配置
/etc/nixos/modules/default.nix                 模块聚合
/etc/nixos/modules/hardware/gpu/nvidia.nix     NVIDIA 配置
/etc/nixos/modules/hardware/gpu/cuda.nix       CUDA 配置
/etc/nixos/modules/desktop/fcitx5/            输入法配置
/etc/nixos/modules/networking/clash.nix       代理配置
/etc/nixos/home/Reiky-REI/default.nix         用户态入口
/etc/nixos/home/Reiky-REI/shell/zsh.nix       Shell
/etc/nixos/home/Reiky-REI/terminal/           终端
/etc/nixos/home/Reiky-REI/desktop/niri/       Niri WM
/etc/nixos/home/Reiky-REI/editors/            编辑器
/etc/nixos/home/Reiky-REI/dev/               开发工具
/etc/nixos/home/Reiky-REI/tools/             CLI 工具

.agent/
├── STARTUP.md             AI 启动清单 🔴必读
├── CONSTITUTION.md        AI 宪法(待创建
├── blueprint/             蓝图设计
│   ├── BLUEPRINT.md        完整蓝图
│   ├── BOOTSTRAPPER.md     启动手册
│   ├── VERIFICATION.md     验证规范
│   └── verify.sh          验证脚本
├── config/
│   ├── rebuild.sh          重建脚本
│   ├── env.sh              环境变量
│   └── token              GitHub token
├── knowledge/
│   ├── architecture.md     仓库架构
│   ├── conventions.md      编码约定
│   ├── system-maintenance.md 系统维护
│   ├── secrets.md          密钥管理
│   ├── current-status.md   本文档 ←
│   ├── boundaries.md       AI 权限边界
│   ├── FAQ.md              常见问题
│   ├── _template.md        复盘模板
│   ├── examples/           验证过的代码
│   ├── session-logs/       复盘记录
│   └── troubleshooting/    解决方案库
├── plans/                  实施计划
└── sessions/               会话记录
```

---

## 当前系统常量

```
主机名:    NixMEOW
用户:      Reiky-REI (uid=1000)
Shell:     zsh + powerlevel10k
WM:        Niri
代理:      http://127.0.0.1:7897 (clash)
系统包管理: nixpkgs 25.11 (flake locked)
用户包管理: home-manager
密钥管理:   agenix
构建命令:   sudo .agent/config/rebuild.sh switch
```
