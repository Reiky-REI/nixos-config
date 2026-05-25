# 复盘: 2026-05-25 opencode instructions 自动管理

## 目标
1. 按照 AGENTS.md 纪律 #1: `instructions` 始终包含 AGENTS.md + INDEX.md + conventions.md
2. 为每个 opencode config 自动添加这 3 个提示词文件
3. 建立 Nix 侧单一数据源 + 一键 regenerate 机制

## 关键提交
- (待提交) feat: Nix 管理 opencode instructions — lib/opencode-config.nix + generate 脚本 + justfile

## 方案选择
- **管理方式**: Nix 函数只管理 `instructions` 字段，其他字段保留手工编辑
- **JSON 工具**: python3（NixOS 自带，json 模块成熟）
- **入口**: justfile 的 `generate-opencode` recipe

## 新建文件
| 文件 | 作用 |
|------|------|
| `lib/opencode-config.nix` | Nix 数据源 — `rootInstructions` / `hostInstructions` |
| `.agents/config/generate-opencode.sh` | 修补脚本 — `nix eval` + python3 |
| `justfile` | `just generate-opencode` 入口 |

## 修改文件
| 文件 | 改动 |
|------|------|
| `flake.nix` | 添加 `opencodeConfig` 作为 flake output |
| `hosts/MEOW/opencode.json` | 新增 `instructions`（`../../.agents/...`） |
| `opencode.json` | 内容不变（已有正确的 instructions） |

## 遇到的坑

### 坑 1: flake output 里 import 的文件必须被 git tracked
- **现象**: `nix eval .#opencodeConfig.rootInstructions` 报错 `path does not exist`
- **根因**: flake 构建使用 git staging 中的源文件，未 `git add` 的新文件不在其中
- **解决**: 先 `git add lib/opencode-config.nix` 再 eval
- **下次注意**: 在 flake 中 import 新文件时，需先 stage 再 eval/build

## 本次沉淀
- [x] 回收到 known-issues.md → flake eval 前需先 git add 新文件
- [x] 使用 `just generate-opencode` 一键同步
