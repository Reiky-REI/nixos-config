# 复盘: 2026-05-26 构建性能优化

## 背景
Users 报告构建系统慢。联合分析：两份诊断覆盖不同层面
- 其他 Claude: `nix flake check` 全量 eval 两次导致 just check 慢 2:30
- 我: 资源瓶颈导致 nixos-rebuild build 慢/失败

## 改动

| 类型 | 文件 | 说明 |
|------|------|------|
| doc | `.agents/knowledge/known-issues.md` | 新增 eval 性能 + 构建性能两个章节，合并双 AI 诊断 |
| config | `modules/common/default.nix` | `max-jobs = 8`、`min-free=5G`/`max-free=10G`、GC 改为 daily/≥3d |
| cleanup | `.agents/config/rebuild.sh` | 去掉冗余 `--option substituters` 和 `--option access-tokens`（已在 nix.settings 和 env 中定义） |

## 紧急止血（手动操作）

| 操作 | 结果 |
|------|------|
| `nix-collect-garbage --delete-older-than 3d` | 清除 1162 paths，释放 ~9.9 GB |
| 删 system generations 72-90（留最新 5 个） | — |
| `nix-collect-garbage`（第二次清理 dangling） | 清除 3669 paths，释放 ~5.2 GB |
| 删 stale result symlink | — |
| **合计释放** | **~15 GB** |

## 磁盘恢复

```
GC 前: 88G/100G (93%), 仅剩 6.9G
GC 后: 71G/100G (76%), 剩余 24G ✅
```

## 验证
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅ 成功

## 注意事项
- niri 保持 unstable（用户决定等下半年）
- `just check` 中的 `nix flake check` 预期 2-3 分钟，只在提交前跑
- 日常验证用 `just rebuild`（增量 7-8s）

## 下次备用
- GC 保留 "最近 5 次" 而不是之前无限制
- 磁盘水位自动管理：`min-free=5G` 触发 GC，`max-free=10G` 停止
