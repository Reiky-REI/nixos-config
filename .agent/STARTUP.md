# AI 工作启动清单

> 每个 AI 首次进入或继续工作时，**必须先完成此清单再动手**。  
> 跳过此清单 = 从零开始，重蹈前人覆辙。

---

## 每次会话开始前（必做——3 分钟内完成）

### 第 1 步：建立约束意识

```bash
cat /etc/nixos/.agents/CONSTITUTION.md 2>/dev/null || echo "宪法尚未创建——这是你的首要任务"
cat /etc/nixos/.agents/knowledge/boundaries.md
```
- [ ] 明确今天不能违反哪些原则
- [ ] 明确自己能做什么、绝对不能做什么

### 第 2 步：了解系统现状

```bash
cd /etc/nixos
git log --oneline -10
git tag -l "step-*" | tail -5
git branch --show-current
```
- [ ] 知道最近 10 次变更是什么
- [ ] 知道蓝图的构建进度（有哪些 step tag）
- [ ] 确认自己在正确的分支上

### 第 3 步：确认验证进度

```bash
bash /etc/nixos/.agent/blueprint/verify.sh list
bash /etc/nixos/.agent/blueprint/verify.sh phase1  # 改为当前阶段
```
- [ ] 知道哪个 Phase 通过了，哪个在待办
- [ ] 知道今天要从哪一步继续

### 第 4 步：吸取前人教训（最关键）

```bash
ls -lt /etc/nixos/.agents/knowledge/ | head -10
head -100 /etc/nixos/.agents/knowledge/INDEX.md | tail -60
```
- [ ] 读完最近 **至少 3 篇** 复盘
- [ ] 特别关注 🔴 踩过的坑和 ⚠️ 未解决问题
- [ ] 不要在已经修复过的问题上浪费时间

### 第 5 步：了解系统拓扑

```bash
cat /etc/nixos/.agents/knowledge/current-status.md
```
- [ ] 知道系统已有哪些功能，AI 不应重复
- [ ] 知道当前阶段优先级

### 第 6 步：检查待办

```bash
grep -r "TODO\|FIXME\|⚠️" /etc/nixos/.agents/knowledge/ --include="*.md" -l 2>/dev/null
```
- [ ] 知道了哪些问题等着解决

---

## 每次工作完成后（必做）

### 第 7 步：记录本次工作

```bash
# 写入知识记录，格式见 INDEX.md 中的《知识记录模板》
vim /etc/nixos/.agents/knowledge/步骤N-简短描述.md
```
- [ ] 写了「做了什么」「文件列表」「构建结果」
- [ ] 写了 🔴 踩过的坑（如果有）
- [ ] 写了 🟢 可复用经验（至少一条）
- [ ] 写了 ⚠️ 未解决问题（如果有）

### 第 8 步：提交 + 标记

```bash
cd /etc/nixos
git add .agents/knowledge/ .agents/knowledge/  # 记录和经验
git add -p  # 选择性地 stage 构建改动
git commit -m "nixos(<scope>): <描述>  Ref: step-<N>"
git tag "step-<N>-done" -m "Phase X Step N: 验证通过"
```
- [ ] git commit 消息符合 Conventional Commits 规范
- [ ] 打上了 `step-N-done` tag
- [ ] 如果是重要里程碑，push 了 tag

---

## 特别注意

| 如果... | 则... |
|---------|-------|
| CONSTITUTION.md 不存在 | **停止构建。先创建宪法。** |
| 找不到知识记录 | 你是第一个来构建的 AI——从头开始 |
| `INDEX.md` 中知识记录模板不可用 | 先读 BLUEPRINT.md 了解复盘格式 |
| verify.sh 完全没跑过 | 从 Phase 1 Step 1 开始 |
| 间隔了 30 天以上 | 先 `nix flake update` + 重跑当前 phase 的 verify.sh |
| git 工作区不干净 | 先 stash 或 commit，不要带着脏状态开始 |
