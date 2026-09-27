# 仓库架构

## 分层结构
```
machines.nix (host → features + user IDs)
  ├→ lib/mkHost.nix → hosts/{hostname}/default.nix + modules/{common,hardware,desktop,...}
  └→ users.nix (stable user ID → login/home/profile)
       └→ Home Manager: home/{profile}/
```

## 各层职责
- **modules/common/** — 全局基础设置 (nix, nixpkgs, time, i18n, fonts, shell 等)
- **modules/hardware/** — CPU/GPU/蓝牙/音频设备相关策略
- **modules/desktop/** — Wayland/X11 会话栈、display manager、compositor、fcitx5、通知、空闲管理、xwayland-satellite
- **modules/networking/** — 网络、代理、防火墙、SSH、VPN、Clash
- **modules/services/** — 后台 daemon、系统能力服务 (管道/打印/MPD/Flatpak/polkit)
- **modules/development/** — 系统级开发工具链和平台支持
- **home/{username}/** — 用户态配置

## Host 与 User 两个独立维度
- `machines.nix` 注册 host，声明 `features`、`users` 和兼容用的 `primaryUser`
- `users.nix` 按稳定 user ID 注册 `username`、`fullName`、`homeDirectory`、`homeProfile` 等身份字段
- 同一 user ID 可以绑定多个 host；一个 host 可以绑定多个 user ID
- `home/{profile}/` 是可复用 Home Manager 配置集，由 `users.nix.homeProfile` 显式选择，不再从登录名推导
- `lib/mkHost.nix` 为每个绑定用户生成 NixOS 用户与 Home Manager 用户；`primaryUser` 目前仅供尚未迁移的单用户 system modules 兼容
- `config.nix` 保留为旧脚本兼容视图，新配置应直接使用 `users.nix`
- 未知 user ID、重复绑定、重复登录名/home 路径及缺失 Home profile 会在求值时报错；feature ID 由 `lib/features.nix` 类型校验

## 分类决策规则
- daemon / 后台长期运行 → **services**
- 图形会话入口 / Wayland stack → **desktop**
- 用户交互应用 → **home**
- 硬件驱动和微码 → **hardware**
- 全局基础设置 → **common**

## 系统层 vs Home 层边界
- **系统层 (NixOS modules)**: daemon, kernel, hardware, 系统能力, 图形会话基础设施
- **Home 层 (home-manager)**: 用户应用, shell, editor, WM config, 终端工具, GUI apps, 用户偏好

---

## 信息流向（Agent 上下文投递）

Agent 每次工作时，信息从哪来、任务结束写回哪：

### 加载路径（开工前）

```
INDEX.md → 决定读哪些文件
  ↓
architecture.md → 理解模块归属和边界
conventions.md  → 确认编码规范和 git 流程
known-issues.md → 避免已知踩坑
  ↓
retros/.retros-index.md → 检索相关历史复盘
```

### 写回路径（完成后）

```
任务结果 → git commit（不可变历史记录）
  ↓
复盘写入 → retros/YYYY-MM-DD-topic.md（结构化经验）
新踩坑   → known-issues.md 追加
新约定   → conventions.md 更新
```

### 三层记忆映射

参考 "Everything is Context" 论文的三层模型与本项目对应：

| 层 | 定义 | 本项目对应 | 生命周期 |
|----|------|-----------|---------|
| History | 不可变原始日志 | git commit history | 永久，不可修改 |
| Memory | 结构化知识 | `.agents/knowledge/` 下全部文件 | 长期，按需更新 |
| Scratchpad | 推理草稿 | git branch + 工作目录 | 临时，任务结束归档或清除 |
