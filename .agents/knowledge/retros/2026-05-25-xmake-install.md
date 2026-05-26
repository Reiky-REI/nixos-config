# 复盘: xmake 安装 — 408 C 语言练习环境

## 目标
为 408 学习（数据结构/算法）配置一个类似 cargo 的 C 项目构建工具。

## 操作
| 操作 | 文件 | 说明 |
|------|------|------|
| 添加 xmake | `home/Reiky-REI/dev/default.nix` | `xmake` 加入 `home.packages` |

## 验证
- `nixos-rebuild switch` ✅ 通过
- `xmake --version` → xmake v3.0.4 ✅
- 配置 `xmake create -l c practice && cd practice && xmake run` 已验证可用

## 后续
- 练 408 时: `xmake create -l c <project-name> && cd <project-name> && vim src/main.c && xmake run`
- 如需第三方 C 库（uthash 等），xmake 内置 `add_requires` 支持
