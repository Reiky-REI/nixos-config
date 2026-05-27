# NixMEOW AI · 验证系统

> 自动化验收标准——AI 自检每一步，避免偏离蓝图。  
> 每完成一个 Phase，运行对应验证。**全部通过才进入下一 Phase。**

---

## ⚠️ 重要声明

**verify.sh 中的验证命令是「行为规范」，不是「已测试脚本」。**

它们定义了每步的**通过标准**，但：
- verify.sh 本身可能未通过完整测试
- 某些检查需要先手动确认前置条件
- 假阴性应写入 knowledge 供后续 AI 优化

**给 AI 的话**：如果验证命令返回 FAIL，先用你的判断确认是真的失败还是验证脚本本身的问题。修好问题后，把修复方法写入 troubleshooting。

---

## 0. 验证系统使用规则

### 谁运行
- **AI 自己**：完成 Phase 后主动运行验证
- **Reiky-REI**：随时 `bash /etc/nixos/.agent/blueprint/verify.sh <phase>` 独立验证

### pass/fail 规则
```
每一个验证项返回:
  0 = PASS
  1 = FAIL (简单失败——AI 可自查原因)
  2 = FAIL (严重偏离——需要人类介入)
  3 = SKIP (可选验证项，不做不算失败)

只有所有 PASS 和 SKIP 项都通过，Phase 才算完成。
出现 FAIL (严重) 必须人工审查。
```

### 失败处理
```
FAIL 级别 1:
  1. AI 读错误输出，理解原因
  2. 修复代码/配置
  3. 重新运行验证
  4. 通过后记录到复盘

FAIL 级别 2:
  1. 立即停止当前 Phase
  2. AI 写一份简短的解释: "哪个验证失败，为什么可能偏离蓝图"
  3. swaync 通知 Reiky-REI
  4. 等待人类决定: 继续 / 回滚 / 重新设计
```

### 自动化脚本
`verify.sh` 可被 systemd timer 或 AI 直接调用：
```bash
/etc/nixos/.agent/blueprint/verify.sh phase1    # 验证 Phase 1
/etc/nixos/.agent/blueprint/verify.sh all        # 顺序验证所有 Phase
/etc/nixos/.agent/blueprint/verify.sh list       # 列出所有验证项
```

---

## Phase 1 验证: 基础设施

### P1.1 flake inputs
```bash
# 验证命令
test "$(nix eval --raw .#nixosConfigurations.NixMEOW.config.system.build.toplevel.drvPath 2>/dev/null | wc -l)" -gt 0
```
- **PASS**: 命令返回 0，system evaluation 成功
- **FAIL (级别 1)**: `llm-agents` 或 `mcp-nixos` 未正确添加到 flake.nix

### P1.2 opencode 可用性
```bash
# 验证命令
opencode --version > /dev/null 2>&1 && opencode agent list > /dev/null 2>&1
```
- **PASS**: opencode 可用，agent 列表正常
- **FAIL (级别 1)**: opencode 未安装或 agent 系统异常

### P1.3 opencode serve 作为 daemon
```bash
# 验证命令
curl -s http://localhost:4096/health > /dev/null 2>&1 || systemctl is-active opencode-serve > /dev/null 2>&1
```
- **PASS**: opencode serve 在运行
- **FAIL (级别 1)**: daemon 未启动，检查 systemd service 状态

### P1.4 Claude Code --print 可用
```bash
# 验证命令
echo "test" | claude --print --model sonnet 2>&1 | grep -q "test\|你好\|Hello"
```
- **PASS**: Claude Code --print 返回正常输出
- **FAIL (级别 1)**: Claude Code 未安装或 API 配置异常

### P1.5 AI 用户创建
```bash
# 验证命令
id ai-code > /dev/null 2>&1
```
- **PASS**: ai-code 用户存在
- **FAIL (级别 1)**: 用户未创建

### P1.6 nixos-rebuild build 无需 root
```bash
# 验证命令
sudo -u ai-code nixos-rebuild build --flake /home/ai-code/nixos#NixMEOW --no-link 2>&1 | grep -q "building the system configuration"
```
- **PASS**: ai-code 能直接 build，无需 sudo
- **FAIL (级别 1)**: 权限不足，检查 trusted-users 配置

### P1.7 git worktree 存在
```bash
# 验证命令
test -d /home/ai-code/nixos/.git/worktrees
```
- **PASS**: git worktree 正确设置
- **FAIL (级别 1)**: 未创建 worktree，参考 BOOTSTRAPPER.md 0.5 节groups ai-agent | grep -q "render" && groups ai-agent | grep -q "video"
```
- **PASS**: ai-agent 在 render 和 video 组中
- **FAIL (级别 1)**: groups.nix 配置不完整

### P1.6 AI 用户不能 sudo
```bash
# 验证命令
sudo -u ai-agent sudo -n true 2>&1 | grep -q "not allowed\|not in the sudoers"
```
- **PASS**: sudo 被拒绝
- **FAIL (级别 2 — 严重)**: ai-agent 意外获得了 sudo 权限

### P1.7 AI 用户目录结构
```bash
# 验证命令
test -d /home/ai-agent && test -d /home/ai-agent/learn && test -d /home/ai-agent/build
```
- **PASS**: 目录都存在
- **FAIL (级别 1)**: systemd.tmpfiles 规则未生效

### P1.8 nixos-rebuild 可构建
```bash
# 验证命令
sudo nixos-rebuild build --flake /etc/nixos#NixMEOW 2>&1 | tail -5 | grep -q "successfully built\|cached"
```
- **PASS**: 构建成功（或缓存命中）
- **FAIL (级别 2 — 严重)**: 系统配置有语法/类型错误，需立即修复

### P1.9 蓝图文档可读
```bash
# (SKIP — AI 自检)
test -r /etc/nixos/.agent/blueprint/BLUEPRINT.md && \
test -r /etc/nixos/.agent/blueprint/BOOTSTRAPPER.md && \
test -r /etc/nixos/.agent/blueprint/VERIFICATION.md
```
- **PASS**: 三个文档都可读
- **SKIP**: 文档不存在时不算失败，但建议补上

---

## Phase 2 验证: Agent 运行时

### P2.1 openclaw 系统服务运行
```bash
# 验证命令
systemctl --user is-active openclaw-gateway 2>/dev/null || systemctl is-active openclaw 2>/dev/null
```
- **PASS**: 服务状态为 active
- **FAIL (级别 1)**: 服务未启动，检查 service config

### P2.2 openclaw 故障恢复
```bash
# 验证命令
systemctl --user show openclaw-gateway 2>/dev/null | grep "Restart=always" > /dev/null
```
- **PASS**: Restart=always 已配置
- **FAIL (级别 1)**: 缺少自动重启

### P2.3 CLI 工具可直接调用 opencode
```bash
# 验证命令 (SKIP — 如果 opencode 已在 PATH)
which opencode > /dev/null 2>&1
```
- **PASS**: opencode 在 PATH 中
- **SKIP**: 如果使用 nix run 或 nix shell，不算失败

### P2.4 iptables 网络强制
```bash
# 验证命令
sudo iptables -L OUTPUT -n -v 2>/dev/null | grep -q "owner UID match 1001"
```
- **PASS**: uid=1001 的出站规则存在
- **FAIL (级别 1)**: 网络强制未配置

### P2.5 网络强制实际生效
```bash
# 验证命令
sudo -u ai-agent curl -s --connect-timeout 3 https://baidu.com > /dev/null 2>&1
test $? -ne 0
```
- **PASS**: ai-agent 无法直连外网
- **FAIL (级别 2 — 严重)**: 网络强制未生效，ai-agent 可绕过代理

### P2.6 代理可访问
```bash
# 验证命令
sudo -u ai-agent curl -s --connect-timeout 3 -x http://127.0.0.1:7897 https://api.deepseek.com/v1/models > /dev/null 2>&1
test $? -eq 0
```
- **PASS**: 通过代理可访问 API
- **FAIL (级别 1)**: 代理未运行或配置错误

---

## Phase 3 验证: Skills 矩阵

### P3.1 SKILL.md 文件生成
```bash
# 验证命令
test -f ~/.config/opencode/skills/file-organizer/SKILL.md
```
- **PASS**: 文件存在且由 Nix 生成
- **FAIL (级别 1)**: skill 配置未正确生成

### P3.2 SKILL.md 格式正确
```bash
# 验证命令
head -5 ~/.config/opencode/skills/file-organizer/SKILL.md | grep -q "^---" && \
grep -q "name:" ~/.config/opencode/skills/file-organizer/SKILL.md && \
grep -q "allowed-tools:" ~/.config/opencode/skills/file-organizer/SKILL.md
```
- **PASS**: YAML frontmatter 包含必填字段
- **FAIL (级别 1)**: 格式不符合 agentskills.io 标准

### P3.3 organize-tool 可用
```bash
# 验证命令
organize --version > /dev/null 2>&1
```
- **PASS**: organize-tool 已安装且可调用
- **FAIL (级别 1)**: derivation 或 pip install 未完成

### P3.4 dry-run 零错误
```bash
# 验证命令
mkdir -p ~/Downloads/test-verify
touch ~/Downloads/test-verify/test.pdf
organize sim ~/Downloads/test-verify/ 2>&1 | grep -q "Would move" || echo "dry-run passed"
rm -rf ~/Downloads/test-verify
```
- **PASS**: dry-run 无崩溃
- **FAIL (级别 1)**: organize-tool 配置有语法错误

### P3.5 vulnix 可扫描
```bash
# 验证命令
sudo vulnix --system --json 2>/dev/null | jq '. == [] or type == "array"' > /dev/null
```
- **PASS**: vulnix 返回有效 JSON (即使是空数组也通过)
- **FAIL (级别 1)**: vulnix 未安装或 NVD 数据未下载

### P3.6 每个声明的 skill 有对应文件
```bash
# 验证命令 (SKIP — 仅当完整 skills 矩阵完成后)
expected_skills="file-organizer file-classifier learn-companion work-assistant publisher privacy-guard security-monitor community-pulse disk-cleaner backup-router health-doctor"
for s in $expected_skills; do
  test -f "$HOME/.config/opencode/skills/$s/SKILL.md" || echo "MISSING: $s"
done
```
- **PASS**: 11 个 skill 全部存在
- **SKIP**: 每新增一个 skill 自检一次

---

## Phase 4 验证: 安全基座 + 哨兵

### P4.1 CONSTITUTION.md 存在
```bash
# 验证命令
test -f /etc/nixos/.agents/CONSTITUTION.md && \
grep -q "不可" /etc/nixos/.agents/CONSTITUTION.md
```
- **PASS**: 宪法文件存在且包含"不可"约束
- **FAIL (级别 2 — 严重)**: 缺少宪法约束，停止后续 Phase

### P4.2 activity.jsonl 可写入
```bash
# 验证命令
echo '{"ts":"verify","action":"test","status":"verify"}' >> ~/Downloads/.activity-test.jsonl 2>&1
test $? -eq 0 && rm -f ~/Downloads/.activity-test.jsonl
```
- **PASS**: 可追加写入
- **FAIL (级别 1)**: 日志路径权限问题

### P4.3 restic 仓库初始化
```bash
# 验证命令
sudo restic snapshots 2>/dev/null | grep -q "ID\|snapshots"
```
- **PASS**: restic 仓库存在且可列出快照
- **FAIL (级别 1)**: restic 未初始化

### P4.4 restic 备份可执行
```bash
# 验证命令
sudo restic backup --tag test-verify ~/Downloads/test-verify 2>&1 | grep -q "snapshot.*saved"
```
- **PASS**: 新快照创建成功
- **FAIL (级别 1)**: restic 仓库权限或路径问题

### P4.5 哨兵日志可写入
```bash
# 验证命令
sudo -u ai-sentinel test -w /var/lib/ai-sentinel/sentinel.jsonl 2>/dev/null || \
sudo touch /var/lib/ai-sentinel/sentinel.jsonl && sudo chown ai-sentinel:ai-sentinel /var/lib/ai-sentinel/sentinel.jsonl
```
- **PASS**: sentinel 可写入自己的日志
- **FAIL (级别 1)**: 日志路径权限不足

### P4.6 哨兵不能写 agent 文件
```bash
# 验证命令
sudo -u ai-sentinel touch /home/ai-agent/test 2>&1 | grep -q "denied\|Permission"
```
- **PASS**: sentinel 无法写入 agent home
- **FAIL (级别 2 — 严重)**: 权限隔离失败

### P4.7 agent 不能写 sentinel 日志
```bash
# 验证命令
sudo -u ai-agent touch /var/lib/ai-sentinel/test 2>&1 | grep -q "denied\|Permission"
```
- **PASS**: agent 无法写入 sentinel home
- **FAIL (级别 2 — 严重)**: 审计完整性破坏

### P4.8 nixos-rebuild switch 仅 Reiky-REI 可执行
```bash
# 验证命令
sudo -u ai-agent nixos-rebuild switch --flake /etc/nixos 2>&1 | grep -q "not allowed\|not in the sudoers\|refused"
```
- **PASS**: ai-agent 无法执行 switch
- **FAIL (级别 2 — 严重)**: sudo 白名单错误

---

## Phase 5 验证: 自进化 + 经验管道

### P5.1 复盘模板存在
```bash
# 验证命令
```
- **PASS**: 模板可用
- **FAIL (级别 1)**: 模板缺失

### P5.2 git 仓库干净
```bash
# 验证命令 (SKIP — 允许有未提交变更)
git -C /etc/nixos status --porcelain | wc -l
```
- **PASS**: 无未提交变更（理想状态）
- **SKIP**: 有变更时不算失败，但建议提交

### P5.3 复盘自动生成功能可用
```bash
# 验证命令 (SKIP — 需要实际 rebuild 后运行)
test -f /etc/nixos/.agents/knowledge/retros/*.md 2>/dev/null
```
- **PASS**: 至少有一篇复盘
- **SKIP**: 无复盘时不阻断

### P5.4 gno 索引可用
```bash
# 验证命令 (SKIP — 如果 gno 尚未集成)
gno search "nixos" 2>/dev/null | grep -q "result"
```
- **PASS**: gno 可搜索知识库
- **SKIP**: gno 暂未集成

### P5.5 community-pulse 可抓取数据
```bash
# 验证命令
curl -s --connect-timeout 10 -x http://127.0.0.1:7897 \
  "https://api.github.com/repos/NixOS/nixpkgs/issues?labels=security&per_page=1" \
  | jq '. == [] or .[0].title' > /dev/null
```
- **PASS**: GitHub API 可访问且返回有效 JSON
- **FAIL (级别 1)**: 网络或代理问题

### P5.6 自进化边界检查
```bash
# 验证命令 (SKIP — 手动检查)
grep -q "CONSTITUTION.md" /etc/nixos/home/Reiky-REI/ai/skills/usage-analyst.nix 2>/dev/null
```
- **PASS**: usage-analyst 引用了宪法约束
- **SKIP**: skill 尚未实现

---

## Phase 6 验证: 学习陪伴 + 发布

### P6.1 学习目录结构
```bash
# 验证命令
test -d ~/.config/ai-companion/learn/subjects && \
```
- **PASS**: 目录和模板就位
- **FAIL (级别 1)**: 目录未创建

### P6.2 学习材料可被索引
```bash
# 验证命令 (SKIP — 需要学习材料)
find ~/.config/ai-companion/learn/ -name "*.md" | wc -l
```
- **PASS**: 至少有一篇学习材料
- **SKIP**: 框架留空时不阻断

### P6.3 publisher 发布目标可访问
```bash
# 验证命令 (SKIP — 需要配置发布目标)
git -C /etc/nixos remote get-url origin > /dev/null 2>&1
```
- **PASS**: 发布目标已配置
- **SKIP**: 不需要发布功能时忽略

---

## 持续验证: 每次 AI 操作后自检

### C.1 操作在 allowed-tools 范围内
```bash
# 验证命令 (AI 在每次操作后自检)
grep "$(date -I)" ~/Downloads/.activity-test.jsonl 2>/dev/null | jq -r .action
```
- **PASS**: 所有操作类型在对应 skill 的 allowed-tools 中

### C.2 未访问 deny 列表路径
```bash
# 验证命令 (哨兵周期检查)
sudo auditctl -l 2>/dev/null | grep -q "ai-agent"
```
- **PASS**: auditd 规则存在且未触发拒绝

### C.3 无配置漂移
```bash
# 验证命令 (每次 build 前运行)
nixos-rebuild build --flake /etc/nixos 2>&1 | grep -v "warning"
```
- **PASS**: 构建成功零错误

### C.4 CONSTITUTION.md 未被修改
```bash
# 验证命令
sha256sum /etc/nixos/.agents/CONSTITUTION.md | diff - <(echo "expected-hash") 2>/dev/null || echo "check manually"
```
- **PASS**: hash 未变（首次运行时记录期望 hash）

### C.5 步骤完成标记 (git tag)
```bash
# 验证命令
git tag -l "step-*" | tail -5
```
- **PASS**: 最近完成的步骤有对应的 step-N-done tag
- **SKIP**: 首次构建，无 tag 时不阻断

---

## 验证脚本实现

```bash
#!/usr/bin/env bash
# /etc/nixos/.agent/blueprint/verify.sh
# 用法: verify.sh <phase> | all | list
set -euo pipefail

PHASE="${1:-list}"

PASS=0
FAIL_SOFT=0
FAIL_HARD=0
SKIP=0

verify() {
  local id="$1" phase="$2" desc="$3" cmd="$4" level="${5:-1}"
  
  if [ "$phase" != "$PHASE" ] && [ "$PHASE" != "all" ]; then
    return 0
  fi

  printf "[%s] %-50s " "$id" "$desc"
  
  if eval "$cmd" 2>/dev/null; then
    echo "✅ PASS"
    PASS=$((PASS + 1))
  elif [ "$level" = "skip" ]; then
    echo "⏭️ SKIP"
    SKIP=$((SKIP + 1))
  elif [ "$level" = "2" ]; then
    echo "🔴 FAIL (严重)"
    FAIL_HARD=$((FAIL_HARD + 1))
  else
    echo "⚠️ FAIL"
    FAIL_SOFT=$((FAIL_SOFT + 1))
  fi
}

case "$PHASE" in
  phase1|all)
    echo "=== Phase 1: 基础设施 ==="
    verify P1.1 phase1 "flake evaluation" \
      'nix eval .#nixosConfigurations.NixMEOW.config.system.build.toplevel.drvPath > /dev/null 2>&1'
    verify P1.2 phase1 "ollama models" \
      'ollama list 2>/dev/null | grep -q "qwen3:4b"'
    verify P1.4 phase1 "AI users exist" \
      'id ai-agent > /dev/null 2>&1 && id ai-sentinel > /dev/null 2>&1'
    verify P1.6 phase1 "ai-agent no sudo" \
      'sudo -u ai-agent sudo -n true 2>&1 | grep -q "not allowed\|sudoers"' 2
    verify P1.8 phase1 "nixos-rebuild build" \
      'sudo nixos-rebuild build --flake /etc/nixos#NixMEOW 2>&1 | tail -5 | grep -q "successfully built"' 2
    ;;
  phase2|all)
    echo "=== Phase 2: Agent 运行时 ==="
    verify P2.1 phase2 "openclaw running" \
      'systemctl --user is-active openclaw-gateway 2>/dev/null || systemctl is-active openclaw 2>/dev/null'
    verify P2.5 phase2 "iptables network enforcement" \
      'sudo -u ai-agent curl -s --connect-timeout 3 https://baidu.com > /dev/null 2>&1; test $? -ne 0' 2
    ;;
  phase3|all)
    echo "=== Phase 3: Skills ==="
    verify P3.1 phase3 "SKILL.md generated" \
      'test -f ~/.config/opencode/skills/file-organizer/SKILL.md'
    verify P3.3 phase3 "organize-tool available" \
      'which organize > /dev/null 2>&1 || nix-shell -p python3 --run "organize --version" > /dev/null 2>&1'
    ;;
  phase4|all)
    echo "=== Phase 4: Security ==="
    verify P4.1 phase4 "CONSTITUTION.md exists" \
      'test -f /etc/nixos/.agents/CONSTITUTION.md' 2
    verify P4.7 phase4 "agent cannot write sentinel" \
      'sudo -u ai-agent touch /var/lib/ai-sentinel/test 2>&1 | grep -q "denied\|Permission"' 2
    verify P4.8 phase4 "agent cannot switch" \
      'sudo -u ai-agent nixos-rebuild switch --flake /etc/nixos 2>&1 | grep -q "not allowed\|sudoers\|refused"' 2
    ;;
  phase5|all)
    echo "=== Phase 5: Self-Evolution ==="
    verify P5.1 phase5 "recap template exists" \
    ;;
  phase6|all)
    echo "=== Phase 6: Learning ==="
    verify P6.1 phase6 "learn dirs exist" \
      'test -d ~/.config/ai-companion/learn/subjects'
    ;;
  list)
    echo "Available phases: phase1 phase2 phase3 phase4 phase5 phase6 all"
    exit 0
    ;;
  *)
    echo "Unknown phase: $PHASE. Use 'list' to see available phases."
    exit 1
    ;;
esac

# Summary
if [ "$PHASE" != "list" ]; then
  echo ""
  echo "=== 验证结果 ==="
  echo "✅ PASS: $PASS  ⏭️ SKIP: $SKIP  ⚠️ FAIL: $FAIL_SOFT  🔴 SEVERE: $FAIL_HARD"
  
  if [ "$FAIL_HARD" -gt 0 ]; then
    echo "🔴 存在严重失败项。STOP — 需要人类审查后才能继续。"
    exit 2
  elif [ "$FAIL_SOFT" -gt 0 ]; then
    echo "⚠️ 存在可修复的失败项。修复后重新运行验证。"
    exit 1
  else
    echo "✅ 本 Phase 验证全部通过。可以进入下一阶段。"
    exit 0
  fi
fi
```
