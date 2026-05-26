# 复盘: 2026-05-26 OpenCode 工作流对齐 Claude Code

## 目标
1. 吸收 Claude 的优化（配置中心、hooks、开工流程），调整 OpenCode 工作流
2. plan prompt 升级为完整开工清单
3. 扩展 skills 配置
4. 对齐两 AI 协作约定

## 关键提交
- `175e09e` — feat/opencode-workflow-align

## 改动的文件
| 文件 | 改动 |
|------|------|
| `lib/opencode-config.nix` | plan prompt 从简单提示 → 完整开工检查列表 |
| `opencode.json` | skills 扩展: nixos-manager + rebuild + secrets + networking |
| `.agents/AGENTS.md` | 新增「OpenCode 对齐方式」章节 |
| `.agents/config/generate-opencode.sh` | 修正标量值传递 bug（双引号嵌套） |
| `.opencode/agents/.gitkeep` | 新建目录，为 subagent 扩展预留 |

## 遇到的 bug 和修复

### bug: generate-opencode.sh 标量值双引号嵌套
- **现象**: `model` 和 `default_agent` 被双重引号包裹 `"\"plan\""`
- **根因**: nix eval --json 输出已含 JSON 引号，Python 字符串插值 `'$model'` 又加一层
- **修复**: 改用 sys.argv 传参 + json.loads() 反序列化
- **教训**: JSON 标量通过 bash 变量嵌入 Python 时要注意引用层级

## 本次沉淀
- [x] generate-opencode.sh 的传参方式需要避免 shell 引号嵌套
- [x] Claude 的 `.claude/settings.json` 和 generate-claude.sh 是 parallel 机制，生成脚本应保持结构一致
