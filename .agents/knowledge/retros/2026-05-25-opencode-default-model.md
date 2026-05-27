# 复盘: opencode 默认模型改为 deepseek-v4-flash + Nix 管理化

## 改动
- `opencode.json`: `model` → `deepseek/deepseek-v4-flash`，provider 新增 `deepseek-v4-flash` 模型条目；添加 `default_agent: "plan"` 和 `agent.plan.prompt: "先查看.agents文件夹内容"`
- `lib/opencode-config.nix`: 新增 `rootModel`, `rootDefaultAgent`, `rootAgentPlanPrompt` 导出
- `.agents/config/generate-opencode.sh`: 读取上述三个字段并写入 opencode.json

## 效果
- `just generate-opencode` 同步 `instructions` + `model` + `default_agent` + plan prompt，Nix 侧统一入口
- 启动即进入 plan 模式，自动加载提示词
