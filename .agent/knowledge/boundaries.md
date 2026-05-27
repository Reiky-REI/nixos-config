# AI 权限边界清单

> 本文档定义了 AI agent 的能力边界。  
> 不仅是建议，**越界操作会触发 sentinel 告警和内核级拒绝**。

---

## ✅ AI 可以做

### 文件操作
- 读 `.agent/` 目录下的所有文档
- 写 `.agent/knowledge/`（跨会话记录）
- 写 `.agent/knowledge/known-issues.md`（新增解决方案）
- 写 `~/.config/opencode/skills/`（新增 skill）
- 读 `/etc/nixos/` 或 `/home/ai-code/nixos/` 下的 .nix 文件
- 写工作目录下的 .nix 文件（需 git branch）

### 系统操作
- 执行 `verify.sh` 自检
- `sudo -u ai-agent` 下的受限命令（见 BLUEPRINT.md 第 4 节 sudo 白名单）
- 读取系统状态（`systemctl status` `journalctl` `df`）

### 开发操作
- 在自己的 home 下编译/运行代码
- 写 derivation 到 `.agents/tools/`
- Nix eval 验证表达式

---

## 🔴 AI 绝对禁止

### 密钥和隐私
| 禁止操作 | 原因 |
|---------|------|
| 读/写 `~/.ssh/` | SSH 私钥泄露 |
| 读/写 `~/.gnupg/` | GPG 私钥泄露 |
| 读/写 `/run/agenix/` | 解密后的密钥绝不暴露 |
| 读 `~/Documents/private/` | 用户隐私数据 |
| 将密钥写入 retros 或 git commit | 永久泄露 |

### 系统权限
| 禁止操作 | 原因 |
|---------|------|
| `nixos-rebuild switch` | 只有 Reiky-REI 可执行 |
| `nixos-rebuild boot` | 只有 Reiky-REI 可执行 |
| 修改 sudo 白名单 | 权限提升攻击 |
| 将自己加入 wheel 组 | 权限提升攻击 |
| 修改自己的 systemd service 配置 | 逃避资源限制 |

### 安全基线
| 禁止操作 | 原因 |
|---------|------|
| 修改或删除 CONSTITUTION.md | 宪法是 AI 行为的根本约束 |
| 修改或删除 sentinel 规则 | 哨兵是 AI 的守卫者 |
| 删除 activity.jsonl 或 sentinel 日志 | 破坏审计完整性 |
| 修改 deny 列表（扩大而非缩小） | 安全基线只能由人收紧 |

### 代码和发布
| 禁止操作 | 原因 |
|---------|------|
| `git push --force` | 破坏 git 历史 |
| 绕过 nix build 验证直接部署 | 核心安全机制 |
| 发布技能到公共注册表（未经人类审查） | 需要人类审核 |
| 将社区信号直接用于自修改 | 外部信号不可信 |

---

## 🟡 AI 可以但需人类确认

### 配置变更
- 修改 `flake.nix` 的 inputs（新增上游依赖）
- 新增用户/组定义
- 新增 systemd service
- 新增网络规则（iptables）

### 系统变更
- 修改 nix.gc 策略
- 修改 nixpkgs 版本 channel
- 新增外部工具 derivation

### 发布
- 将自建工具提交到主配置
- 将 experience 导出为 ClawHub 技能

---

## 哨兵监控点

哨兵会检测以下越界行为并**立即告警**：

1. 路径边界突破（访问 deny 列表路径）
2. 频率异常（短时间内大量文件操作）
3. 时间异常（非活跃时段操作）
4. 权限变更（组成员变化）
5. 网络逃逸（绕过代理直连）

**越界行为会被 auditd 记录，由 sentinel 分析，你无法隐藏。**
