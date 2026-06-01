---
title: "{申请标题}"
requester: "{项目名}/{AI类型}"   # 如 "Documents/office/claude" 或 "WorkSpace/408/opencode"
date: "{YYYY-MM-DD}"
request_id: "{YYYY-MM-DD-简写}"
priority: "{low/medium/high/critical}"
status: "pending"               # pending → approved → done / rejected
---

## 申请内容

{清晰描述需要系统做什么}

## 为什么需要

{业务场景或依赖说明}

## 具体方案

{建议的具体改动喵~ 文件路径、配置项等}

```nix
# 示例：建议添加的配置代码片段
environment.systemPackages = with pkgs; [
  python312
];
```

## 预期影响

- {会影响什么模块}
- {会间接影响什么功能}
- {风险说明}

## 验证方式

{如何验证改动能正常工作}

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| {YYYY-MM-DD} | 提交 | `pending` → 等待审批 |
| | 审批 | `approved` / `rejected` + 理由 |
| | 执行(build) | ✅/❌ + 构建结果 |
| | 复盘 | `retros/{日期}-{主题}.md` |
| | 归档 | `archive/` |

## 关联复盘
<!-- 执行后填写 -->
- `{复盘文件路径}`
