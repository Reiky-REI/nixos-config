# 仓库架构

## 分层结构
```
config.nix (用户标识定义)
  → flake.nix (import 并通过 specialArgs 传递 username/fullName)
    → hosts/{hostname}/default.nix → modules/{common,hardware,desktop,...}
                                   → home/{username}/
```

## 各层职责
- **modules/common/** — 全局基础设置 (nix, nixpkgs, time, i18n, fonts, shell 等)
- **modules/hardware/** — CPU/GPU/蓝牙/音频设备相关策略
- **modules/desktop/** — Wayland/X11 会话栈、display manager、compositor、fcitx5、通知、空闲管理、xwayland-satellite
- **modules/networking/** — 网络、代理、防火墙、SSH、VPN、Clash
- **modules/services/** — 后台 daemon、系统能力服务 (管道/打印/MPD/Flatpak/polkit)
- **modules/development/** — 系统级开发工具链和平台支持
- **home/{username}/** — 用户态配置

## 用户配置中心
- `config.nix` — 仓库根目录，定义 `username`、`fullName`、`githubHandle`
- 所有用户标识符统一在此定义，其他地方通过 `specialArgs` 引用
- 变量传递路径: `config.nix → flake.nix specialArgs/extraSpecialArgs → NixOS/home-manager 模块`
- 新增用户: 改 `config.nix` 中的定义，`secrets/secrets.nix` 添加公钥，创建对应 `.age` 文件
- **已知耦合**：`home/{username}/` 目录名与 `config.nix` 的 `username` 值需要保持一致。修改用户名时需要同时重命名目录和改 `config.nix`。当前未自动化，属于半完成抽象。

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
