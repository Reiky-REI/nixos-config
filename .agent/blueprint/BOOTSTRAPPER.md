# NixMEOW AI-Native · 启动手册

> 给负责构建此系统的 AI 的**可执行指引**。
> 最终目标是实现 BLUEPRINT.md 中定义的完整系统。
> 本文档描述构建顺序和验证方法——**不假设连续构建，每次会话从上次 checkpoint 继续**。

---

## ⚠️ 重要声明 — 每个 AI 必读

**本文档中的所有 Nix 代码、shell 脚本、配置文件均为「伪代码」。**

它们描述了**设计意图和逻辑结构**，但：
- 未曾通过 `nixos-rebuild build` 验证
- 可能存在语法错误、缺失依赖、路径问题
- 需要根据当前系统实际状态调整

**你的任务是**：
1. 理解每段伪代码的**设计意图**
2. 对照当前系统状态，写**真实可用的代码**
3. 通过 `nixos-rebuild dry-build` 验证
4. 通过 `bash /etc/nixos/.agent/blueprint/verify.sh <phase>` 验证
5. **每完成一个步骤，立即写记录到 `.agent/knowledge/session-logs/`**（见下方「记录铁律」）

**千万不要**：
- 直接复制粘贴伪代码到 `/etc/nixos/`
- 期望一次 build 就能通过
- 跳过 `nixos-rebuild dry-build` 验证步骤
- 假设本文档中的所有路径/包名/pin 都是正确的
- **跳过记录步骤**——下一个 AI 完全依赖你的记录来继续工作

---

### ⚠️ 记录铁律 — 跨会话知识传递的唯一桥梁

> 这个项目不是一个 AI、一次会话就能完成的。  
> 你的记录是**下一个 AI 唯一的知识来源**。  
> 没有记录 = 下一个 AI 从零开始，重复你的错误。

**每个步骤完成后必须写记录**。不是建议，是强制。

记录位置: `.agent/knowledge/session-logs/`

文件名格式: `步骤N-简短描述.md`

**必须包含**:

| 字段 | 内容 |
|------|------|
| 做了什么 | 一句话总结 |
| 写了/改了哪些文件 | 绝对路径列表 |
| 构建结果 | 通过 / 失败 / 未测试 |
| 🔴 踩过的坑 | 什么出错了、什么原因、怎么修好的 |
| 🟢 可复用经验 | 后续 AI 可以直接用的结论 |
| ⚠️ 未解决问题 | 留给下一个 AI 的待办 |
| [伪]→[已验证] | 把本步骤验证通过的伪代码段标记为 [已验证] |

**模板**（直接复制使用）:
```markdown
# 步骤 N: <描述>

- **日期**: YYYY-MM-DD
- **结果**: 成功 / 部分成功 / 失败
- **验证**: verify.sh <phase> → PASS/FAIL
- **Git**: step-N-done (tag) / commit abc123
- **分支**: ai/step-N-xxx (已 merge / 未 merge / 已删除)

## 做了什么
- 改了 /etc/nixos/xxx → <原因>
- 新建了 /etc/nixos/modules/xxx → <原因>

## 🔴 踩过的坑
| 错误 | 原因 | 修复 |
|------|------|------|
| `nix build` 报 hash 错误 | hatch 版本未锁定 | 用 `nix flake update` 后重试 |

## 🟢 可复用经验
- ollama 的 `loadModels` 首次需要手动 `ollama pull`
- organize-tool 的 symlink action 方向是反的，用 shell action 调用 ai-relocate

## ⚠️ 未解决问题
- <留给下个 AI 的问题>
```

**在 BOOTSTRAPPER.md 的伪代码中标记**:
```
[伪]      → 设计意图, 未验证
[已验证]  → 上一轮已验证可用 (标记后写 session-logs)
```

---

**延续会话指南**：
- 每次新会话开始：先跑 `verify.sh <phase>` 确认当前阶段过了哪些验证
- 读完 `.agent/knowledge/session-logs/` 最近 5 篇记录——了解前面的 AI 做了什么、踩了什么坑
- 如果上次会话未完成某阶段：跳过已验证步骤，从未通过那步继续
- 如果间隔很久：`nix flake update` + 重跑 `verify.sh <phase>` 确保依赖不过时

---

## 0. 总原则

### 0.1 渐进式构建

```
不要: 一次实现所有角色、所有技能、所有监控
要:   每次只加一个能力，验证它工作，再继续

原因: 这是我们自己的生产环境。一个错误的 useradd 可以锁死登录。
      每一步都要可回滚。
```

### 0.2 先跑起来再优化

```
步骤 A: 手工能工作    → 证明概念正确 (不需要写 Nix 模块)
步骤 B: 写成 Nix 模块  → 声明式可复现   (通过 dry-build)
步骤 C: 加自动化 timer → 无人值守       (通过 verify.sh)
步骤 D: 加哨兵监控     → 安全兜底       (通过 verify.sh phase4)
```

### 0.3 任何系统级操作前

```bash
# 1. 确认当前 generation 可用
sudo nixos-rebuild list-generations | head -5

# 2. 先 dry-build (不应用)
sudo nixos-rebuild dry-build --flake /etc/nixos#NixMEOW

# 3. git 备份点（见 0.6 提交规范）
cd /etc/nixos && git add -A && git commit -m "nixos(ai): checkpoint before <change>"

# 4. 应用
sudo nixos-rebuild switch --flake /etc/nixos#NixMEOW

# 5. 验证不成功 → 立即回滚
sudo nixos-rebuild --rollback
```

### 0.4 当前系统的真实状态

```
主机名: NixMEOW
NixOS channel: 25.11 (或更新的)
主力 agent: opencode (已配置, DeepSeek V3 后端)
已有代理: Clash Verge (localhost:7897, TUN 模式)
已有密钥: agenix (ai_api_key_REIKY_REI)
已有编辑器: nvim (CookNixvim)
已有 shell: zsh + starship
已有 WM: niri
文件系统: ext4 (不支持 btrfs 快照 → restic 替代)
GPU: NVIDIA RTX 4070 Laptop (8GB VRAM)
CPU: Intel
配置文件: /etc/nixos/ (flake-based, 模块化)
```

### 0.5 本文档中的代码标注

```
伪代码标记:
  [伪] = 设计意图，需验证和调整
  [已验证] = 在你之前的会话中已通过 build 验证 (knowledge 中有记录)

如果某段代码没有 [已验证] 标记，它就是伪代码。
请先 dry-build，验证通过后更新标记。
```

### 0.6 Git 提交规范 — AI 必须遵守

> 提交信息是下一个 AI 理解「这段代码为什么存在」的第一线索。  
> 混乱的提交 = 下一个 AI 迷失。

**提交消息格式**（Conventional Commits）:
```
nixos(<scope>): <简短描述>

<详细说明（可选）>

Ref: step-<N>
```

**scope 分类**:
| Scope | 含义 | 示例 |
|-------|------|------|
| `ai` | AI agent 配置和服务 | `nixos(ai): add ollama service with CUDA` |
| `users` | 用户和组定义 | `nixos(users): create ai-agent and ai-sentinel` |
| `skills` | SKILL.md 生成 | `nixos(skills): generate file-organizer skill` |
| `flake` | flake inputs 和 outputs | `nixos(flake): add llm-agents.nix input` |
| `config` | 系统配置修改 | `nixos(config): update nix.gc to 7d` |
| `service` | systemd service | `nixos(service): add openclaw daemon` |
| `sandbox` | 沙箱和安全 | `nixos(sandbox): add iptables uid=1001 rule` |
| `blueprint` | 蓝图文档更新 | `nixos(blueprint): update CONSTITUTION.md` |
| `chore` | 杂项维护 | `nixos(chore): cleanup unused imports` |

**何时提交**（每步至少提交一次）:
```
1. 步骤开始前:  git commit -m "nixos(ai): checkpoint before step<N>"
2. dry-build 通过后: git commit -m "nixos(<scope>): <change>  Ref: step-<N>"
3. switch 成功后:  git commit -m "nixos(<scope>): verified after switch  Ref: step-<N>"
4. 步骤结束时:      git tag "step-<N>-done"
```

**分支规范**:
```
main                  ← 稳定的系统配置 (永远)
ai/step-<N>-<desc>    ← AI 的工作分支 (dry-build 通过后 merge 回 main)
ai/proposal/<topic>   ← AI 的提案分支 (需要人类审查)
```

**禁止操作**:
```
git push --force          ← 绝对禁止 (已在 opencode.json 中 deny)
git commit --amend        ← 禁止修改已 push 的提交
git reset --hard HEAD~    ← 禁止丢弃已提交的工作
```

**提交前自检**:
```bash
# 确认没有提交密钥
git diff --cached | grep -i "secret\|api_key\|password\|token" && echo "⚠️ 发现疑似密钥！" || echo "✅ 无密钥"

# 确认提交消息合规
git log -1 --oneline | grep -qE "^(nixos|docs|fix|feat)\(.*\):" || echo "⚠️ 提交消息格式不符合规范"
```

## 第一阶段: 基础设施

### 依赖关系

此阶段不依赖任何其他部分。可以独立构建和验证。

---

### 步骤 1: flake.nix + 两个新 input

```
目标: 让 llm-agents.nix 和 mcp-nixos 可用
风险: 极低 — 只是加 flake input, 不改任何系统行为
```

**设计意图** [伪]:
在 `/etc/nixos/flake.nix` 的 `inputs` 块中新增两个上游：
```nix
# 在 inputs = { ... } 块中新增:
llm-agents.url = "github:numtide/llm-agents.nix";
mcp-nixos.url = "github:utensils/mcp-nixos";
# 注意: mcp-nixos 在 nixpkgs 中也有 pkgs.mcp-nixos
#       但 flake 版本更新更频繁。两者可选。
```

**验证方式**:
```bash
cd /etc/nixos
nix flake update llm-agents mcp-nixos
nix flake check
nix eval .#nixosConfigurations.NixMEOW.config.system.build.toplevel.drvPath
# 无报错 = flake evaluation 成功
```

**git checkpoint 之后才能继续下一步**。

---

### 步骤 2: ollama 本地推理服务

```
目标: 本地 LLM 推理可用
前提: 步骤 1 完成
风险: 低 — 只是加一个 service, 不影响现有系统
```

**设计意图** [伪]:
创建 `/etc/nixos/modules/services/ai/ollama.nix`：
```nix
{ config, lib, pkgs, ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "127.0.0.1";
    port = 11434;
    loadModels = [ "qwen3:4b" "nomic-embed-text" ];
  };
}
```

同时创建 `/etc/nixos/modules/services/ai/default.nix` 并在 `/etc/nixos/modules/default.nix` 中 import `./services/ai`。

**验证方式**:
```bash
nixos-rebuild dry-build --flake /etc/nixos#NixMEOW
sudo nixos-rebuild switch --flake /etc/nixos#NixMEOW
ollama list  # 应显示 qwen3:4b 和 nomic-embed-text
ollama run qwen3:4b "hello, 用中文回复"
```

---

### 步骤 3: 创建 AI 用户骨架

```
目标: 创建 ai-agent 和 ai-sentinel 用户（先不配组权限，只建用户）
前提: 步骤 2 完成
风险: 极低 — 只是 useradd, 无 sudo, 无共享组
```

**设计意图** [伪]:
创建 `/etc/nixos/modules/users.nix`：
```nix
{ config, lib, pkgs, ... }:
let
  sharedHome = "/home";
in {
  users.users.ai-agent = {
    isNormalUser = true;
    home = "${sharedHome}/ai-agent";
    group = "ai-agent";
    createHome = true;
    shell = pkgs.zsh;
    description = "NixMEOW AI System Agent";
    extraGroups = [ "render" "video" ];
    openssh.authorizedKeys.keys = [];
  };
  users.groups.ai-agent = {};

  users.users.ai-sentinel = {
    isSystemUser = true;
    home = "/var/lib/ai-sentinel";
    group = "ai-sentinel";
    createHome = true;
    description = "NixMEOW AI Sentinel";
  };
  users.groups.ai-sentinel = {};

  users.groups.ai-shared = {};
  users.groups.ai-reader = {};
  users.groups.ai-builder = {};
  users.groups.ai-auditor = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/ai-sentinel 0700 ai-sentinel ai-sentinel -"
    "d ${sharedHome}/ai-agent/learn 0700 ai-agent ai-agent -"
    "d ${sharedHome}/ai-agent/build 0700 ai-agent ai-agent -"
  ];
}
```

导入: 在 `/etc/nixos/hosts/MEOW/default.nix` 的 imports 中加入 `../../modules/users.nix`。

**验证方式**:
```bash
nixos-rebuild dry-build --flake /etc/nixos#NixMEOW
sudo nixos-rebuild switch --flake /etc/nixos#NixMEOW

id ai-agent   # uid=1001, groups=ai-agent,render,video
id ai-sentinel  # uid=1002, groups=ai-sentinel
sudo -u ai-agent whoami   # ai-agent
sudo -u ai-agent sudo -n true 2>&1 | grep "not allowed"
```

---

### 步骤 4: 手动验证文件整理管道可行性

```
目标: 手工跑通 "下载文件 → 分类 → 留软链接" 全流程
前提: 步骤 3 完成
风险: 零 — 在 ~/Downloads/test-ai-org/ 中进行，不影响真实文件
```

**设计意图** [伪]:
```bash
mkdir -p ~/Downloads/test-ai-org && cd ~/Downloads/test-ai-org
touch report-2025.pdf photo-beach.jpg contract.docx notes.txt

# 测试 organize-tool 的 dry-run 分类
nix-shell -p python3 --run "pip install --user organize-tool"
organize sim --config /dev/stdin <<'EOF'
rules:
  - locations: ~/Downloads/test-ai-org
    filters: [{extension: pdf}]
    actions: [{move: ~/documents/papers/}]
  - locations: ~/Downloads/test-ai-org
    filters: [{extension: [jpg, jpeg, png]}]
    actions: [{move: ~/screenshot/archive/}]
EOF
```

**测试 ai-relocate 原型** [伪]:
```bash
cat > /tmp/ai-relocate.sh <<'SCRIPT'
#!/usr/bin/env bash
src="$1"; dst_dir="$2"; keep_days="${3:-30}"
fname=$(basename "$src")
mv "$src" "$dst_dir/"
ln -s "$dst_dir/$fname" "$src"
echo "{\"ts\":\"$(date -Iseconds)\",\"src\":\"$src\",\"dst\":\"$dst_dir/$fname\",\"symlink\":\"$src\",\"expires\":\"$(date -Iseconds -d "+$keep_days days")\"}" >> /tmp/symlink-registry.jsonl
SCRIPT
chmod +x /tmp/ai-relocate.sh
```

**验证方式**:
```bash
touch ~/Downloads/test-ai-org/test-file.txt
/tmp/ai-relocate.sh ~/Downloads/test-ai-org/test-file.txt ~/documents/
ls -la ~/Downloads/test-ai-org/test-file.txt  # 应是软链接
readlink ~/Downloads/test-ai-org/test-file.txt  # 指向实际文件
rm -rf ~/Downloads/test-ai-org ~/documents/test-file.txt 2>/dev/null
```

**此步骤完成后必须写复盘到 `.agent/knowledge/session-logs/`**。记录：
- organize-tool 的 symlink action 方向是反的 (不能直接用)
- organize-tool 的 `shell` action 可调用 ai-relocate 脚本
- organize-tool 不在 nixpkgs 中，需要写 derivation

---

### 阶段一验证

```bash
bash /etc/nixos/.agent/blueprint/verify.sh phase1
```
全部 PASS 才进入第二阶段。

---

## 第二阶段: 第一个完整技能 — 下载文件夹整理

### 依赖关系

此阶段依赖第一阶段的 ollama + AI 用户 + 文件整理管道概念验证。

---

### 步骤 5: organize-tool Nix derivation

```
目标: 把 organize-tool 打包为 Nix derivation
前提: 第一阶段完成
风险: 低
```

**设计意图** [伪]:
```nix
# 注意: 此代码从未通过 nix build 验证
# 需要: 1) 查 PyPI 确定正确的 version/hash/dependencies
#       2) 可能需要 buildPythonPackage 或 fetchFromGitHub
{ pkgs }:
pkgs.python3Packages.buildPythonPackage rec {
  pname = "organize-tool";
  version = "3.3.0";
  format = "pyproject";
  src = pkgs.python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-...";  # 第一次 build 会报错告诉你正确值
  };
  propagatedBuildInputs = with pkgs.python3Packages; [
    appdirs colorama send2trash simplematch pyyaml
  ];
  doCheck = false;
}
```

**验证方式**: `nix build -f ./modules/services/ai/organize-tool.nix`

---

### 步骤 6: 第一个 SKILL.md — file-organizer

```
目标: 生成完整可用的 file-organizer skill
范围: 仅 ~/Downloads 目录、PDF/图片/压缩包分类、软链接保留
前提: 步骤 5 完成
```

**设计意图** [伪]:
通过 Nix 生成 `~/.config/opencode/skills/file-organizer/SKILL.md`。Skill 内容描述:
- 识别新文件 → 规则分类 → organize sim → organize run → 记录 activity.jsonl → 通知
- 安全约束: 不访问 ~/.ssh/ 等、移动前 dry-run、操作后留软链接 30 天

**验证方式**: `test -f ~/.config/opencode/skills/file-organizer/SKILL.md`

---

### 步骤 7: 手工运行并记录第一次真实经验

```
目标: 在真实 ~/Downloads 上首次运行 file-organizer
前提: 步骤 6 完成
```

用 opencode + file-organizer skill 在真实 Downloads 上先 dry-run，确认后再实际运行。完成后写复盘到 `.agent/knowledge/session-logs/`。

---

### 阶段二验证

```bash
bash /etc/nixos/.agent/blueprint/verify.sh phase3
# 注: phase3 对应 Skills 验证 (verify.sh 使用技能编号而非阶段编号)
```

---

## 第三阶段: Agent 后台运行 + 安全监控

### 依赖关系

此阶段依赖第一阶段的基础设施。

---

### 步骤 8: openclaw 常驻服务

```
目标: openclaw 作为 systemd user service 持久运行
前提: 第一阶段完成 (flake input 中已有 openclaw)
注意: 先不接权限白名单——先跑起来, 观察, 再加限制
```

**设计意图** [伪]:
创建 `/etc/nixos/modules/services/ai/openclaw-daemon.nix`。
systemd user service, `ConditionACPower=true`(电池暂停),
`Restart=always`, 密钥通过 agenix 注入。

**验证方式**: `systemctl --user status openclaw-gateway` 正常

---

### 步骤 9: vulnix CVE 扫描

```
目标: AI 第一次执行安全扫描
前提: 步骤 3 完成 (用户 + 组)
```

手工运行 `sudo vulnix --system --json`，用 opencode + security-monitor skill 分析报告。

---

### 步骤 10: 第一个 systemd timer — 安全扫描

```
目标: 安全扫描每日自动运行
前提: 步骤 9 完成
```

**设计意图** [伪]:
在 `/etc/nixos/modules/services/ai/timers.nix` 中定义:
```nix
systemd.timers.ai-security-check = {
  wantedBy = ["timers.target"];
  timerConfig.OnCalendar = "08:00,20:00";
};
systemd.services.ai-security-check = {
  serviceConfig.Type = "oneshot";
  serviceConfig.User = "ai-agent";
};
```

**验证方式**: `systemctl list-timers | grep ai-security`

---

### 阶段三验证

```bash
bash /etc/nixos/.agent/blueprint/verify.sh phase2
```

---

## 第四阶段: 自进化基础 + 经验管道

### 依赖关系

此阶段依赖前三个阶段的经验积累。

---

### 步骤 11: knowledge-recorder 经验自动记录

```
目标: AI 完成操作后自动生成复盘
前提: 至少有一次 rebuild 经验
```

**设计意图** [伪]:
在 rebuild.sh 成功后追加 knowledge-recorder 调用，基于 git diff 和 activity.jsonl，按 `_template.md` 格式生成复盘，写入 `session-logs/`。

---

### 步骤 12: 社区 RSS 监控

```
目标: 验证 NixOS Discourse API 可访问
前提: 网络代理可用
```

手工测试 Discourse API 和 GitHub API 的可达性。

---

### 步骤 13: gno 知识库索引

```
目标: 让 AI 能搜索已有的 troubleshooting
前提: gno 已集成
```

**设计意图** [伪]: `gno index --path /etc/nixos/.agent/knowledge/`

---

### 阶段四验证

```bash
bash /etc/nixos/.agent/blueprint/verify.sh phase5
```

---

## 第五阶段: 权限编排 + 哨兵 + 宪法

### 依赖关系

此阶段依赖第一阶段的用户骨架 + 至少一周的 AI 操作数据。

---

### 步骤 14: 权限转声明式

将第一阶段验证过的"agent 不能读 ~/.ssh"等权限转为 Nix 组的声明式配置。

---

### 步骤 15: CONSTITUTION.md

按 BLUEPRINT.md 第 6 节的 19 条原则，写入 `.agent/CONSTITUTION.md`。

**这是哨兵和自进化的前置条件**。

---

### 步骤 16: 哨兵规则上线

运行第一个哨兵检测（路径边界检查），确认 activity.jsonl 中没有越界操作。

---

### 阶段五验证

```bash
bash /etc/nixos/.agent/blueprint/verify.sh phase4
```

---

## 第六阶段: 学习陪伴 + 软链接清理

### 依赖关系

此阶段依赖第五阶段的宪法 + 第二阶段的文件整理。

---

### 步骤 17: learn-companion 框架就位

创建 `~/.config/ai-companion/learn/` 目录骨架和主题模板。

---

### 步骤 18: symlink-cleaner

测试过期软链接清理管道。

---

### 阶段六验证

```bash
bash /etc/nixos/.agent/blueprint/verify.sh phase6
```

---

## 附录 A: 每次工作后的自检清单

```markdown
## 今天的构建完成后

### 功能验证
- [ ] 核心功能按预期工作
- [ ] 边缘情况(空目录、大文件、特殊字符文件名)有处理

### 安全验证
- [ ] sudo -u ai-agent <危险操作> 被拒绝
- [ ] ai-agent 不能读 ~/.ssh/
- [ ] ai-agent 不能写 /etc/nixos/
- [ ] activity.jsonl 有本次操作的记录

### 回滚验证
- [ ] nixos-rebuild --rollback 可用
- [ ] git reflog 显示本次 checkpoint 提交

### 文档
- [ ] .agent/knowledge/session-logs/ 有本次复盘
- [ ] 新的 troubleshooting 条目已写入
- [ ] 伪代码中验证通过的部分标记为 [已验证]
```

## 附录 B: "出问题了"快速指南

```
nixos-rebuild switch 失败
→ sudo nixos-rebuild --rollback
→ 回到上一次成功的 generation

AI 修改了不该修改的文件
→ restic restore latest --tag pre-ai-change --target /
→ git checkout main (如果是 /etc/nixos 的文件)

openclaw 占用资源过多
→ systemctl --user stop openclaw-gateway
→ 调整 MemoryMax/CPUQuota 后 redeploy

误给了 agent 过多权限
→ 修改 users.nix → nixos-rebuild switch
→ auditd 日志可追溯 agent 在此期间的操作
```

## 附录 C: 每次 AI 会话启动提示

```
每次新会话开始，AI 在开始任何工作前：

1. 读取 .agent/CONSTITUTION.md（如有）
   → 明确今天不能违反哪些原则
2. 读取 .agent/knowledge/architecture.md
   → 了解系统结构
3. 读取 .agent/knowledge/session-logs/ 最近 5 篇复盘
   → 吸取之前 AI 的教训——这是跨会话知识传递的唯一桥梁
4. git log --oneline -10 && git tag -l "step-*"
   → 确认工作区状态、最新变更、已完成步骤
5. 运行 verify.sh <phase> 确认当前进度
   → 避免重复已验证的步骤
6. 看本文档对应阶段的步骤
   → 从上次未完成的那一步继续
7. 开始工作
8. 每完成一步: git commit + 写 session-logs
9. 阶段结束: git tag "step-N-done" + 写完整复盘
```

## 附录 D: 子系统独立构建顺序

```
不需要等待, 可以独立构建和测试:

  独立:  ollama                (不需要任何 AI agent)
        organize-tool derivation (独立, 用 shell 测试)
        vulnix                (独立安装, 不需要 AI)
        user/group 定义        (纯 Nix 模块)

  依赖 Phase 1:
        file-organizer skill   (依赖 organize-tool + ollama)
        security-monitor skill (依赖 vulnix)

  依赖 file-organizer:
        symlink-cleaner        (依赖 ai-relocate 原型)

  依赖 openclaw flake input:
        openclaw service       (依赖 Phase 1 基础设施)

  依赖 有操作数据后:
        knowledge-recorder     (依赖 git diff + activity.jsonl)
        sentinel               (依赖至少一周的操作数据)

  依赖 网络代理 + 权限:
        community-pulse        (依赖 curl + 代理)
        tool-builder           (依赖 nix build + 沙箱)

  最后:
        learn-companion        (依赖 gno + ollama + 宪法)
```
