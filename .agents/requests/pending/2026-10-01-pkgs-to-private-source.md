---
title: "把主仓 pkgs/ 的 3 个本地包迁移到私源 Reiky-nixpkgs"
requester: "NixMEOW/opencode"
date: "2026-10-01"
request_id: "2026-10-01-pkgs-to-private-source"
priority: "medium"
status: "pending"
---

## 申请内容

按 2026-09-20 用户指令的「打包归属」约定（见 `.agents/knowledge/conventions.md`），把主仓
`/etc/nixos/pkgs/` 下的 3 个包迁移到个人私源 **Reiky-nixpkgs**，主仓只通过 overlay 消费，
然后删除主仓 `pkgs/` 目录。

现状（违规点）：
- `pkgs/tuxedo-drivers-patched/` — 键盘背光补丁内核模块（compat-check/kbdlight/no-cp-usr 补丁）
- `pkgs/netease-cdn-bypass/` — 网易云 CDN 防盗链绕过 API
- `pkgs/cursors/` — MikuCat 光标主题（目录里还有大写 `MikuCat/`，包名 `cursors` 过泛）

## 为什么需要

- conventions.md「打包归属」明确：nixpkgs 没有的包一律放私源 `Reiky-nixpkgs`，**禁止**塞主仓 `pkgs/`
- 主仓应只保留配置；私源集中管理自打包件，便于复用与独立版本演进
- 顺带修正命名：`cursors` → `mikucat-cursors`（小写 + 连字符，与约定一致）

## 具体方案

### 第一步：私源 Reiky-nixpkgs 新增 3 包

- `pkgs/mikucat-cursors/default.nix`：现 `pkgs/cursors/MikuCat/*` 原样搬入，
  安装到 `$out/share/icons/MikuCat/`（保持目录名，避免用户侧 icon 主题名变化）
- `pkgs/netease-cdn-bypass/default.nix`：原样搬入
- `pkgs/tuxedo-drivers-patched/default.nix`：原样搬入；**注意**它是按内核线
  `callPackage` 的包，消费方在 `linuxPackages.extend` 里调用。
  私源建议导出可复用形态（二选一）：
  1. `lib.<system>.tuxedoDriversPatched = kfinal: kprev: { tuxedo-drivers = ...; tuxedo-keyboard = ...; }`（推荐）
  2. 或提供固定内核线的 `legacyPackages.<system>.tuxedo-drivers-patched`
     （接受 kernel-715 pin 与主 nixpkgs 两条内核线各需适配的代价）
- 私源 README「收录的包」表格登记 3 行（包名/说明/为何本地打包）

### 第二步：主仓改消费并删除本地包

```nix
# lib/mk-host.nix L26-27 与 L178-179 (kernelPackages715 / nixpkgs overlay)
#   把 kfinal.callPackage ../pkgs/tuxedo-drivers-patched {}
#   换成私源导出的 helper (见上方第 1 种设计)

# lib/mk-host.nix L182
#   netease-cdn-bypass = final.callPackage ../pkgs/netease-cdn-bypass {};
#   改成使用私源 overlay 提供的 pkgs.netease-cdn-bypass

# home/reiky/default.nix L11
#   cp -r ${../../pkgs/cursors/MikuCat}/* $out/share/icons/MikuCat/
#   改成 ${pkgs.mikucat-cursors}/share/icons/MikuCat/... (按私源输出结构调整)
```

删除主仓 `pkgs/`：按铁律先生成删除清单（目录树 + 文件列表 + SHA256 + 描述），
存档到 `~/.local/state/delete-manifests/` 或仓库 `artifacts/`。

### 协作注意（2026-10-01 侦察已核实）

- 远程默认分支是 **`main`**（`origin/HEAD → origin/main`）；`master` 为历史遗留分支
- 工作克隆：`~/WorkSpace/Reiky-nixpkgs`（与 `origin/main` 完全同步、工作区干净）✅
- `~/Reiky-nixpkgs` 克隆只是久未 fetch（那 6 个 zen 提交早已在远程；fetch 后仅落后 2 个提交），可留作备份，不作为本单工作克隆
- 推送凭据已验证：`ssh -T git@github.com` 认证成功（`Hi Reiky-REI!`）→ 可直接 SSH 推送，无需额外提供凭据
- 私源推送与主仓合并在两步完成，避免跨仓半成品

## 预期影响

- NixMEOW / NixMEOW-WSL / NixMEOW-CTR 的闭包内容预期不变（同字节包，仅来源改变）
- `pkgs/` 目录从主仓消失，由 `Reiky-nixpkgs.overlays.default` 提供
- 需要一次 `nixos-rebuild switch` 使系统闭包切换到私源版本（可选，build 验证优先）

## 验证方式

- `nixos-rebuild build --flake /etc/nixos#NixMEOW`（以及 WSL/CTR toplevel eval）通过
- 私源 `nix flake check`/构建 3 包成功
- 迁移前后相关 store 路径对照（光标主题/netease 服务/tuxedo 驱动构建结果）
- `git ls-files pkgs/` 为空；`just check-docs` 通过

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-10-01 | 提交 | `pending` → 等待审批 |
| 2026-10-01 | 侦察 | 私源分支/克隆/凭据已核实（远程默认 `main`，SSH 可用）→ 具备执行条件 |
| | 审批 | `approved` / `rejected` + 理由 |
| | 执行(build) | ✅/❌ + 构建结果 |
| | 复盘 | `retros/{日期}-{主题}.md` |
| | 归档 | `archive/` |

## 关联复盘
<!-- 执行后填写 -->
- `{复盘文件路径}`
