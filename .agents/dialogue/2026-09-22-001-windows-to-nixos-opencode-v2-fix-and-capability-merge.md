---
title: NixMEOW 侧 OpenCode v2 迁移收尾交接
date: 2026-09-22
from: Windows 端 opencode session (ses_f3bf7a465ffdlo35h1Ndp9yztj)
to: 下一个 session（负责去 NixOS 侧核实并修复）
status: 待执行
tags: [opencode, v2, nixos, migration, plugin, handoff]
---

# NixMEOW 侧 OpenCode v2 迁移收尾 — 交接文档

> 这份文档的由来喵：2026-09-22 我们在 Windows 端把 NixOS(NixMEOW) 上的
> LSP / skills / MCP 配置同步了过来喵,过程中发现那边系统 CLI 已经是
> **opencode v2.0.10**喵,但配置和插件还是 **V1 形态**喵,怀疑有东西已经静默失效喵~
> 这份文档记录**已核实的证据**和**待修清单**喵,给下一个 session 直接照着做喵~

---

## 1. TL;DR

| 项 | 结论 |
|---|---|
| NixOS 系统 CLI 版本 | **v2.0.10**（`pkgs.opencode-v2`，Reiky-nixpkgs 私源）— 已确认 |
| root 高级权限通道 | 仍 pin **v1**（`pkgs-unstable.opencode` 1.18.13）— 有意为之，别动 |
| edit-backup 插件 | **V1 写法，V2 下不会运行** — 本次迁移的**头号问题** |
| `~/.config/opencode/opencode.jsonc` | V1 形态（`permission`/`agent`/`skills.enabled`/`mcp`），靠 V2 的兼容归一化兜着，**建议转正** |
| opencode-gc 定时器 | 还在清 **v1** 的 `opencode-stable.db`，v2 数据在 `opencode.db` — **确认漏清** |
| kb / obsidian-vault MCP | 是否在 v2 下连上，**未验证**（需要到机器上跑 `opencode mcp list`） |

**另外**：那边从 2026-09-20 01:50 之后就没再跑过 opencode（人都在 Windows 这边），
所以"插件失效"目前是**文档级结论 + 间接证据**，需要到机器上实测坐实（见 §6）喵~

> 🎯 **本文档分两部分**喵~
> **第一部分（§2–§9）**＝ **止血**：把 NixOS 侧 opencode v2 的迁移收尾喵~
> **第二部分（§11）**＝ **方向**：用户已明确的下一步需求 —— **双系统能力合并，让 Windows 侧用上 NixOS** 喵~
> 两部分都要做；第一部分的活是第二部分的地基喵,**别在坏地基上盖楼**喵~

---

## 2. 怎么访问 NixOS 分区（先看这节，能省一小时）

NixOS 装在 **磁盘 1（WDC PC SN520，119GB）第 2 分区**，ext4，主机名 `NixMEOW`喵~
Windows 读不了 ext4喵,必须借 WSL2 挂载喵,而且**需要管理员权限**喵~

### 2.1 标准流程

```powershell
# ① 先起一个常驻进程，让 WSL2 虚拟机别闲着（否则挂载会随 VM 关闭而消失）
#    用后台任务跑：wsl -d archlinux -- sleep 3600

# ② 提权挂载（会弹 UAC，点"是"）
Start-Process cmd -ArgumentList '/c','wsl --mount \\.\PHYSICALDRIVE1 --partition 2 > "C:\Users\reiky\AppData\Local\Temp\opencode\mount.log" 2>&1' -Verb RunAs -Wait

# ③ 验证
wsl -d archlinux -- ls /mnt/wsl/PHYSICALDRIVE1p2/home/
```

挂载后路径映射喵：

| NixOS 内 | 从 WSL 访问 |
|---|---|
| `/` | `/mnt/wsl/PHYSICALDRIVE1p2` |
| `/home/Reiky-REI` | `/mnt/wsl/PHYSICALDRIVE1p2/home/Reiky-REI` |
| `/etc/nixos`（配置仓库） | `/mnt/wsl/PHYSICALDRIVE1p2/etc/nixos` |
| `/nix/store` | `/mnt/wsl/PHYSICALDRIVE1p2/nix/store` |

### 2.2 收尾（一定要做）

```powershell
# 提权执行，避免一直占着裸盘
wsl --unmount \\.\PHYSICALDRIVE1
wsl --terminate archlinux     # 顺手结束常驻 sleep
```

### 2.3 本次踩过的坑（照着避）

1. **`wsl --mount` 报 `WSL_E_ELEVATION_NEEDED_TO_MOUNT_DISK`** → 就是没提权，按 2.1 ② 做喵~
2. **挂载后 Windows 里看不到盘符**，并提示 `automount.root 不是 /` → 正常喵，
   直接进 WSL 用 `/mnt/wsl/PHYSICALDRIVE1p2` 访问就行，不用改 `/etc/wsl.conf`喵~
3. **报 `WSL_E_DISK_ALREADY_MOUNTED` 但路径是空的** → 挂载状态卡死喵，
   执行 `wsl --shutdown`，再重跑 2.1 ①②喵~
   （注意 `wsl --shutdown` 会顺带停掉 docker-desktop 等其他发行版）
4. **挂载会随 WSL 虚拟机空闲关闭而消失** → 所以要先起 `sleep` 常驻喵~
5. **PowerShell 里别写 `2>/dev/null`** 喵,PowerShell 会把 `2>` 当成自己的重定向，
   报 `Could not find a path 'C:\dev\null'`喵,把命令写进 `.sh` 文件再跑喵~
6. **别在 `wsl -- bash -c '...'` 内联命令里用 `$VAR`** 喵,实测变量会被吃掉变成空喵,
   一律**写脚本文件**再执行喵~
7. **脚本要先去 CR**：用写文件工具落地后先 `sed -i "s/\r$//" xxx.sh` 再 `bash xxx.sh`喵~

### 2.4 推荐姿势

把要执行的逻辑写进 `C:\Users\reiky\AppData\Local\Temp\opencode\<name>.sh`，
然后一条命令跑完：

```powershell
wsl -d archlinux -- bash -c 'sed -i "s/\r$//" /mnt/c/Users/reiky/AppData/Local/Temp/opencode/scan.sh; bash /mnt/c/Users/reiky/AppData/Local/Temp/opencode/scan.sh'
```

---

## 3. 已核实的事实（带证据）

### 3.1 版本与打包

- `/nix/store/as27xcv5ndny499gajr2bw8nbq5qnwyx-opencode-2.0.10/bin/opencode`（198MB 单文件）
- `/nix/store/n5h9jhy4ivh30s38y0xp4bhgh8k7ysfk-opencode-1.18.13`（v1，给 root 通道）
- `modules/development/opencode/default.nix`：`environment.systemPackages = [pkgs.opencode-v2];`
- `modules/services/opencode-root.nix`：新增 `package` 选项，**默认 pin `pkgs-unstable.opencode`（v1）**
  - 原因：v2 `serve` 强制密码鉴权（401），`mcp-agents-bridge` 走的是 v1 无鉴权契约
  - 见 `retros/2026-09-20-opencode-v2-adoption.md`

> ⚠️ root 通道 pin v1 是**有意设计**，别顺手升级喵~

### 3.2 配置形态还是 V1

`~/.config/opencode/opencode.jsonc`（普通文件，**不是 HM 软链**，可直接编辑）：

```jsonc
{
  "instructions": [".agents/AGENTS.md", ...],   // V2 不再解析，等同无效
  "skills": { "enabled": [...] },               // V2 的 skills 是数组，这个形状无效
  "lsp": { ... },                               // 形状 V2 依旧可用
  "permission": { "external_directory": ..., "bash": {...} },  // V2 用 permissions 数组
  "mcp": { "obsidian-vault": {...}, "kb": {...} },             // V2 用 mcp.servers
  "default_agent": "plan",
  "agent": { "plan": { "prompt": "..." } }      // V2 用 agents.<id>.system
}
```

`/etc/nixos/opencode.json`（仓库根，cwd 在 `/etc/nixos` 时会被加载）同样是 V1 形态，
另外还有 V2 已不存在的字段：`"autoupdate": false`、`"shell": "bash"`、`permission.doom_loop`。

> V2 迁移文档原话喵：**"V1 config files 是兼容的（会被归一化），唯一有意的破坏性变更是 server API 和 plugin API"**喵~
> 所以配置大概率**还能跑**喵,但属于躺在地雷上喵,建议一并转正喵~

### 3.3 插件是 V1 写法 → V2 不执行（本次头号问题）

`/etc/nixos/.opencode/plugins/edit-backup.js`（2076 字节）：

```js
export const EditBackupPlugin = async () => ({
  "tool.execute.before": async (input, output) => { ... },
});
```

- V2 迁移文档明说喵：**"V1 plugin implementations do not run in V2. 移动文件或改配置项名字都不够。"**
- V2 要求 `export default { id, setup(ctx) }`，钩子改成 `ctx.tool.hook("execute.before", ...)`
- HM 软链：`home/Reiky-REI/tools/opencode.nix` 里
  `home.file.".config/opencode/plugins/edit-backup.js".source = ../../../.opencode/plugins/edit-backup.js;`
  → 实际是指向 `/nix/store/...-home-manager-files/...`，**改完要 rebuild 才生效**
- `~/.config/opencode/package.json` 仍 pin `"@opencode-ai/plugin": "1.15.7"`（V1 包）

**间接证据**：`~/.local/state/opencode-edit-backups/` 下**只有 `2026-09-19/` 一个日期目录**，
且里面唯一文件是 `etc/nixos/flake.nix` —— 对照日志，那是 2026-09-19T16:38:57 那次
**手动 node 直接调用插件**的测试产物，不是 opencode 真实编辑产生的喵~
之后（含 v2 上线后）**没有任何新快照**喵~

**但**：那边最后一次跑 opencode 是 `2026-09-20T01:50:24`（run=a65ef825，只写了 3 行 config 发现日志），
之后就没再启动过喵,所以"没新快照"也**可能只是因为没人用**喵~
需要在机器上实测坐实（§6 步骤 3）喵~

### 3.4 opencode-gc 清理的是 v1 的库（确认）

`~/.local/share/opencode/` 下：

```
opencode-stable.db        94 MB   2026-09-21 00:45   ← v1 命名，gc 脚本清的就是它
opencode-stable.db-wal   100 MB
opencode.db              339 KB   2026-09-20 01:16   ← v2 实际在用这个
```

而 `~/.local/bin/opencode-gc` 里：`DB_PATH="${HOME}/.local/share/opencode/opencode-stable.db"`
→ **v2 的 `opencode.db` 永远不会被清理**喵,v1 的 94MB+100MB 也没被清（脚本保留 7 天）喵~
这正是 v2 采用复盘里记的第 2 条待办喵~

### 3.5 其他观察

- `~/.claude/skills` 是**真实目录**（21 项），和 `~/.agents/skills` 大量重名喵,
  V2 日志里刷了一屏 `WARN duplicate skill name`喵~ 优先级是 `.claude/skills` < `.agents/skills`喵,
  所以重名的最终用 `.agents` 的，无功能问题，只是吵喵~
- `/etc/nixos/AGENTS.md`（1560B，真实文件）存在喵,V2 在 cwd=`/etc/nixos` 时会自动加载它喵,
  它自己又是索引，指向 `.agents/AGENTS.md` 等 —— 所以**指令链其实没断**喵~
- `~/AGENTS.md` → `.agents/AGENTS.md` 软链存在喵,在 home 下工作时 V2 也能加载喵~
- `hosts/MEOW/opencode.json` 只有 `instructions` 一个字段，且按 2026-05-31 复盘，
  `hosts/` 下的配置本来就不会被加载喵,属死文件喵~

---

## 4. 待修清单（按优先级）

| # | 事项 | 严重度 | 需要 rebuild？ |
|---|---|---|---|
| 1 | `edit-backup.js` 迁移到 V2 插件 API | 🔴 高（安全网失效） | 是 |
| 2 | `~/.config/opencode/package.json` 依赖换 `@opencode/plugin` | 🔴 高（配合 #1） | 否 |
| 3 | `opencode-gc` 指向 `opencode.db`（或两个都清） | 🟠 中（磁盘 194MB 且持续涨） | 是 |
| 4 | `opencode.jsonc` 转 V2 形态（`permissions`/`agents`/`mcp.servers`/删 `skills.enabled`） | 🟠 中（现在靠兼容层） | 否（live 文件） |
| 5 | `/etc/nixos/opencode.json` 加 `"update": "disable"` | 🟠 中（nix store 只读，自动更新会徒劳） | 否（仓库文件） |
| 6 | 验证 kb / obsidian-vault MCP 在 v2 下是否连上 | 🟡 待确认 | 否 |
| 7 | 清理 duplicate skill 警告（可选） | 🟢 低 | 视方案 |

---

## 5. 修复方案（可直接照做）

### 5.1 【#1+#2】把 edit-backup 插件迁到 V2

改 `/etc/nixos/.opencode/plugins/edit-backup.js`，**核心改动只有两处**：

```js
// ❌ V1（现状）
export const EditBackupPlugin = async () => ({
  "tool.execute.before": async (input, output) => { /* output.args.filePath */ },
});

// ✅ V2
export default {
  id: "edit-backup",
  async setup(ctx) {
    await ctx.tool.hook("execute.before", async (event) => {
      // event.tool  = 工具名（"edit" / "write" / "patch" / "multiedit"）
      // event.input = 工具参数（原来的 output.args，取 .filePath / .path / .file）
    });
  },
};
```

> **别写 `import { Plugin } from "@opencode/plugin"`** 喵！
> Windows 端实测（opencode v2.0.6）：本地插件加载器**解析不到这个裸包名**，
> 日志报 `Cannot find package '@opencode/plugin' imported from ...edit-backup.js`，
> 即使把它装进 `~/.config/opencode/node_modules` 也一样喵~
> 而 `Plugin.define({id, setup})` 的返回值实测就是普通对象 `{id, setup}`（无 brand / symbol），
> 所以**直接 `export default {id, setup}` 100% 等价且零依赖**喵~

另外 `~/.config/opencode/package.json` 建议改成：

```json
{
  "dependencies": {
    "@opencode-ai/plugin": "1.15.7",
    "@opencode/plugin": "^2.0.12"
  }
}
```

（`/etc/nixos/.opencode/package.json` 同步改，它是仓库侧的那份）

**完整可用的 V2 版本**（Windows 端已实测通过，可直接抄）：

```js
import { copyFile, mkdir, readdir, rm, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve, sep } from "node:path";

const BACKUP_ROOT = join(homedir(), ".local", "state", "opencode-edit-backups");
const RETENTION_DAYS = 30;
const FILE_TOOLS = new Set(["edit", "write", "patch", "multiedit"]);

const dayStamp = () => new Date().toISOString().slice(0, 10);

const toBackupRelPath = (abs) =>
  abs.replace(/^[A-Za-z]:/, "").split(sep).filter(Boolean).join("/");

async function prune() {
  try {
    const cutoff = Date.now() - RETENTION_DAYS * 86400000;
    for (const entry of await readdir(BACKUP_ROOT)) {
      const p = join(BACKUP_ROOT, entry);
      const st = await stat(p).catch(() => null);
      if (st?.isDirectory() && st.mtimeMs < cutoff) {
        await rm(p, { recursive: true, force: true });
      }
    }
  } catch {}
}

export default {
  id: "edit-backup",
  async setup(ctx) {
    let pruned = false;
    await ctx.tool.hook("execute.before", async (event) => {
      if (!FILE_TOOLS.has(event?.tool)) return;
      const args = event?.input ?? {};
      const target = args.filePath ?? args.path ?? args.file;
      if (typeof target !== "string" || target.length === 0) return;

      const abs = resolve(target);
      const st = await stat(abs).catch(() => null);
      if (!st?.isFile()) return;

      if (!pruned) { pruned = true; void prune(); }

      const dest = join(BACKUP_ROOT, dayStamp(), toBackupRelPath(abs));
      await mkdir(dirname(dest), { recursive: true });
      await copyFile(abs, dest);
    });
  },
};
```

Windows 端的成品在：`C:\Users\reiky\.config\opencode\plugins\edit-backup.js`

### 5.2 【#3】修 opencode-gc

`~/.local/bin/opencode-gc`：

```bash
# 现状
DB_PATH="${HOME}/.local/share/opencode/opencode-stable.db"
# 建议（v2 实际在用这个；v1 的库确认没用了再删）
DB_PATH="${HOME}/.local/share/opencode/opencode.db"
```

顺带确认 `opencode-stable.db(.wal)` 那 194MB 是不是 v1 遗留、能不能删喵~
（v1 还跑在 root 通道上，但 root 通道的 HOME 也是这个家目录喵,**删之前先确认 bridge 不用**）

### 5.3 【#4】opencode.jsonc 转 V2

`~/.config/opencode/opencode.jsonc`（live 文件，不用 rebuild）：

```jsonc
{
  "$schema": "https://opencode.ai/config.json",

  // skills 不用声明 —— V2 自动发现 ~/.agents/skills 和 ~/.claude/skills
  // （原来的 skills.enabled 是对象形状，V2 无效，删掉）

  "lsp": { /* 原样保留，形状 V2 仍可用 */ },

  "permissions": [
    { "action": "external_directory", "resource": "*", "effect": "allow" },
    { "action": "shell", "resource": "git push *", "effect": "allow" },
    { "action": "shell", "resource": "git push --force*", "effect": "deny" },
    { "action": "shell", "resource": "rm -rf /*", "effect": "deny" }
  ],

  "mcp": {
    "servers": {
      "obsidian-vault": {
        "type": "local",
        "command": ["/home/Reiky-REI/WorkSpace/tools/obsidian-mcp-server/result/bin/obsidian-mcp-server"],
        "environment": { "VAULT_PATH": "/home/Reiky-REI/WorkSpace/notes" }
      },
      "kb": {
        "type": "local",
        "command": [
          "/etc/profiles/per-user/Reiky-REI/bin/python3",
          "/etc/nixos/.agents/tools/kb-mcp/server.py"
        ]
      }
    }
  },

  "default_agent": "plan",
  "agents": {
    "plan": { "system": "……原 prompt 内容……" }
  }
}
```

映射速查喵：

| V1 | V2 |
|---|---|
| `permission.bash.<cmd>` | `permissions[]` 数组，`action: "shell"` |
| `permission.external_directory` | `permissions[]`，`action: "external_directory"` |
| `permission.doom_loop` | V2 无此动作，删 |
| `mcp.<name>` | `mcp.servers.<name>` |
| `agent.<id>.prompt` | `agents.<id>.system` |
| `skills.enabled: [...]` | 删（自动发现）；要额外目录才用 `skills: ["路径"]` |
| `instructions: [...]` | V2 不解析，删；靠 AGENTS.md 兜底 |
| `autoupdate: false` | `update: "disable"` |
| `"shell": "bash"` | 建议写全路径 `/run/current-system/sw/bin/bash` |

### 5.4 【#5】`/etc/nixos/opencode.json` 补 `update`

在仓库根配置里把 `"autoupdate": false` 换成（或补上）：

```jsonc
"update": "disable"
```

原因喵：v2 二进制在 `/nix/store` 里是只读的，自动更新根本写不进去喵,
默认值 `notify` 会一直提示"有新版本"，而 NixOS 的版本更新应该走 nix 喵~

### 5.5 【#6】验证 MCP

```bash
opencode mcp list
```

期望看到 `kb` 和 `obsidian-vault` 都 `connected`喵~
如果 v2 不接受旧的 `mcp.<name>` 形状，这里会显示缺失/未连接 → 按 §5.3 改成 `mcp.servers` 喵~

---

## 6. 验收步骤（到 NixOS 机器上跑）

```bash
# 1) 版本
opencode --version              # 期望 v2.0.10

# 2) 服务与 MCP
opencode service status
opencode mcp list               # kb / obsidian-vault 是否 connected

# 3) 插件是否真的加载（关键）
#    先看日志里有没有插件加载记录
grep -iE "edit-backup|loading plugin|failed to load plugin" \
  ~/.local/share/opencode/log/opencode.log | tail -20

#    然后真改一个文件（走 edit 工具），看快照有没有落盘
ls -la ~/.local/state/opencode-edit-backups/$(date +%F)/

# 4) 技能是否被发现
ls ~/.agents/skills/            # V2 自动发现这里
#    开一个会话看 /skills 或可用技能列表

# 5) gc 是否指对了库
grep DB_PATH ~/.local/bin/opencode-gc
ls -la ~/.local/share/opencode/opencode*.db*
```

**判定标准**：第 3 步改完文件后，`~/.local/state/opencode-edit-backups/<今天>/<原路径>` 出现新文件 = 插件修好了。

---

## 7. 参考：Windows 端已迁移好的成品

这次在 Windows 端（opencode v2.0.6）已经把同一套东西跑通了喵,可以直接对照抄喵~

| 文件 | 作用 |
|---|---|
| `C:\Users\reiky\.config\opencode\opencode.jsonc` | V2 形态配置（7 个 LSP + permissions + agents.plan） |
| `C:\Users\reiky\.config\opencode\plugins\edit-backup.js` | **V2 版插件（已实测生效）** |
| `C:\Users\reiky\.config\opencode\AGENTS.md` | 全局指令（V2 只认这个路径 / 或项目 AGENTS.md） |
| `C:\Users\reiky\.agents\skills\*` | 从 NixOS 搬来的 9 个 skills（已做 Windows 依赖适配） |
| `C:\Users\reiky\.agents\rules\*` | 条件规则 |

顺带记一下 Windows 端踩到的 V2 坑，NixOS 侧大概率也会遇到喵：

1. **本地插件不能 `import "@opencode/plugin"`**（解析不到裸包名）→ 用 `export default {id, setup}`喵~
2. **`PermissionDenied`**：HM/nix 软链过来的文件在 Windows 侧读不到，改用 `tar -h` 解引用或直接读源文件喵~
3. **TypeScript 别用 7.x**：`typescript-language-server` 找不到 TS7 的 `tsserver.js`（TS7 是原生版），要装 `typescript@5`喵~
4. **`tsserver.path` 必须用平台分隔符**：该服务器用 `path.sep` 解析，正斜杠会被判为无效路径喵~

---

## 8. 相关文件清单（NixOS 侧）

```
/etc/nixos/
├── opencode.json                                  # 仓库根配置（V1 形态，cwd 在此会加载）
├── AGENTS.md                                      # 项目指令入口（V2 会加载）
├── lib/opencode-config.nix                        # rootInstructions/hostInstructions 等（v1 生成用）
├── lib/claude-config.nix
├── hosts/MEOW/opencode.json                       # 只被 v1 用，死文件
├── .opencode/
│   ├── package.json                               # @opencode-ai/plugin 1.15.5
│   └── plugins/edit-backup.js                     # ★ 要迁移的 V1 插件
├── home/Reiky-REI/tools/opencode.nix              # ★ HM 软链 + opencode-gc 定时器定义
├── modules/development/opencode/default.nix       # 系统 CLI = pkgs.opencode-v2
└── modules/services/opencode-root.nix             # root 通道 pin v1（别动）

~/.config/opencode/
├── opencode.jsonc                                 # ★ live 配置（V1 形态）
├── package.json                                   # @opencode-ai/plugin 1.15.7
└── plugins/edit-backup.js -> /nix/store/...       # HM 软链

~/.local/
├── bin/opencode-gc                                # ★ 清的是 v1 的 db
├── share/opencode/opencode.db                     # ← v2 数据
├── share/opencode/opencode-stable.db              # ← v1 数据（94MB+100MB wal）
├── share/opencode/log/opencode.log                # v2 日志
└── state/opencode-edit-backups/                   # 插件快照（只有 2026-09-19 一个手动测试产物）
```

---

## 9. 执行时务必遵守的既有约定

这些是 NixMEOW 仓库自己的规矩，**别违反**喵：

1. **`nixos-rebuild switch` 有 NVIDIA PRIME 黑屏风险**喵,AI **不得主动 switch**喵,
   只跑 `sudo .agents/config/rebuild.sh build`（或 `nixos-rebuild build --flake /etc/nixos#NixMEOW`），
   然后交给用户手动 switch / reboot 喵~ 见 `skills/nixos-manager`、`skills/rebuild`喵~
2. **绝不直接在 main 上改**喵,开 feature branch喵~
3. **改完写复盘**到 `.agents/knowledge/retros/<date>-<topic>.md`，和代码一起提交喵~
4. 提交用 `.agents/config/commit.sh -m "..."`（bot 身份）喵~
5. 输出自然语言用"喵~ "代替标点喵~
6. `~/.config/opencode/package.json` 的改动需要跑一次 `npm install --package-lock-only --ignore-scripts` 更新 lock（历史上是这么做的）喵~

---

## 10. 建议的下一步顺序

1. 挂载分区（§2.1），**先只读核实** §6 的 1-2 步，坐实"插件已失效"喵~
2. 按 §5.1 改插件 + §5.2 改 gc 脚本（这两个要 rebuild）喵~
3. 按 §5.3 / §5.4 改两份配置（不需要 rebuild）喵~
4. `git status` 确认改动范围 → 开 feature branch → 提交 → 写复盘喵~
5. 跑 `build` 验证，把 switch/reboot 交给用户喵~
6. 回到 §6 做完整验收喵~
7. 顺手把这份文档的新发现回写到 NixOS 的 `.agents/dialogue/` 里喵~

---

# 第二部分 · 下一步方向

## 11. 需求：双系统能力合并（在 Windows 侧使用 NixOS）

> 本部分**只记录需求与已知事实**，方案未选型、未实施喵~
> 先做完第一部分（§2–§9）的 opencode v2 修复，再开新 session 来决策和落地喵~

### 11.1 需求

用户 2026-09-22 原话喵：

> 「我们实际上下一步的需求是实现**双系统的能力的合并**喵,我希望**在 Windows 分区使用我的 nixos**」喵~

补充确认（同日）喵：用户希望能在 Windows 里**直接打开 NixOS 的窗口/终端**
（WSL 的常规能力，已确认可行：`wsl -d NixOS` 开终端、`wsl -s NixOS` 设默认、GUI 走 WSLg），
也就是**不用重启**就能用 NixOS 的环境干活喵~

要合的能力，按优先级喵：

1. **在 Windows 里能开 NixOS 的终端/窗口**（含 GUI）
2. **nix 环境能用** —— `~/.agents/config/nix-env.sh <skill>` → `nix develop .#<skill>`，
   即 skills 的 `deps.nix` 要能跑起来
3. **知识层共享** —— `~/.agents`（skills / rules / knowledge / retros / MEMORY / dialogue）
   两边是同一套，而不是各有一份
4. **MCP 能跑** —— kb 语义检索（需 embedding/reranker 端点）、obsidian-vault

**规划原则（用户明确，2026-09-22）喵：尽可能用 NixOS，WSL 里也一样喵~**

不要花力气去建设 `archlinux` / `Ubuntu` 这些发行版喵,
WSL 侧的目标形态就是 **NixOS-WSL**，让两边是同一个系统喵~

**关键认知：NixOS 是声明式的，环境可以直接「复现」** 喵~
不需要搬运 `/nix/store`、也不需要同步整个家目录 ——
**只要拿到配置文件（flake），就能重建出同样的环境**喵~
而 `/etc/nixos` **已经在 GitHub 上**（`git@github.com:Reiky-REI/nixos-config.git`）喵,
所以路线 A 的落地本质上是三步喵：

1. 装 NixOS-WSL（得到一个干净的 NixOS 发行版）
2. `git clone` 那份 nixos-config
3. 加一个 `NixMEOW-WSL` host（复用现有 `modules/`）→ `nixos-rebuild switch --flake .#NixMEOW-WSL`

→ 工具链、shell 配置、skills 的 `deps.nix` 环境、MCP 等等，**全部按声明复现**喵~

⚠️ **唯一的缺口**：`~/.agents`（知识层：skills / knowledge / retros / MEMORY / dialogue）
**不在 nixos-config 仓库里**，它是自己独立的本地 git 仓库、且**没有远端**喵~
所以"知识层"这一块没法靠 nixos-rebuild 复现，**必须先给它建远端**（§11.3 决策点 #1）喵~

### 11.2 已知内容（2026-09-22 核实）

**Windows / WSL 环境**

- WSL 版本 **2.7.13**（NixOS-WSL 要求 ≥ 2.4.4 ✓）
- WSL2 内核 `6.18.33.2-microsoft-standard-WSL2`，**自带 btrfs 模块**（`modprobe btrfs` 实测成功）
- 已有发行版：`archlinux`（**裸的**，无 nix / git / jq / home-manager）、`Ubuntu`、`docker-desktop`
- `.wslconfig` 现状：16 核 / 10G 内存 / 32G swap / `sparseVhd` / `dnsTunneling` / `autoProxy` /
  `hostAddressLoopback=true` / `localhostForwarding=false`

**仓库与远端**

- `/etc/nixos` **已有 GitHub 远端**：`git@github.com:Reiky-REI/nixos-config.git`（分支 main）
- ❗ `~/.agents` **没有远端**（本地仓库，`user = Reiky-REI@local`）
  → 想两边共享知识层，**必须先给它建一个远端**（建议 GitHub 私有库）
- `~/WorkSpace` 下的自建仓库（DeepSec / Reiky-nixpkgs / dsh-* 等）**全部没有 origin**，纯本地
- ⚠️ `/etc/nixos/.git/config` 里写死了 `http.proxy = http://127.0.0.1:7897`，
  Windows 侧没有这个代理，clone 时要 `-c http.proxy=` 覆盖

**磁盘**

- **Disk 0（953.9 GB）和 Disk 1（119.2 GB）都没有未分配空间**
- C 盘剩 138.4 GB；NixOS 分区 100G / 已用 74G / 剩 22G
- NixOS 根分区是 **ext4**（不是 btrfs）；`/nix/store` 已占 **38G**
- → 要建共享分区**必须先缩小现有分区**（缩 C: 最现实）

**共享分区文件系统选项**（关键在"Windows 侧能否原生访问"）

| 方案 | Windows 原生 | Linux | 备注 |
|---|---|---|---|
| **NTFS** | ✅ | 内核 `ntfs3` 读写 | 最省事，适合纯数据 |
| **btrfs + WinBtrfs 驱动** | ⚠️ 需第三方驱动 | ✅ 原生 | 见下方要点 |
| exFAT | ✅ | ✅ | 无权限位 / 无软链，只能放媒体 |
| ext4 | ❌ 无可靠驱动 | ✅ 原生 | 排除（Ext2Fsd 已废弃） |

btrfs 方案要点（驱动 **WinBtrfs** `maharmstone/btrfs`，**v1.10 / 2026-09-01**，7.8k star，活跃维护）喵：

- ✅ 支持：读写、RAID0/1/10/5/6、子卷与快照、**符号链接**、硬链接、ACL、稀疏文件、reflink、
  zlib/lzo/zstd 压缩、send/receive、balance、scrub、TRIM
- ✅ 支持 **WSL 元数据透传**（`/etc/wsl.conf` 的 `[automount] options = "metadata"`）
  和 **Windows SID ↔ Linux uid/gid 映射**
- ❌ 不支持：配额(quota)、碎片整理(defrag)、完整事务日志
- ⚠️ Secure Boot 下可能加载不了，需在注册表
  `HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy` 加 DWORD `UpgradedSystem=1`，或关掉 Secure Boot
- ⚠️ Win11 累计开机超 **250 小时**后可能被驱动白名单拦，
  需 `CiTool.exe --remove-policy "{8F9CB695-5D48-48D6-A329-7202B44607E3}"` 再重启
- ⚠️ 卷**不出现在磁盘管理**（假块设备）；文件名必须 UTF-8；
  **POSIX 权限位不忠实映射**（git 仓库要 `core.fileMode=false`）
- ⚠️ 维护者免责声明：自担风险，务必备份

**已知的三条路线**（仅记录，未选型）

- **A. NixOS-WSL** —— `wsl --install --from-file nixos.wsl` 装一个完整 NixOS 发行版，
  再在 flake 里加 `nixosConfigurations.NixMEOW-WSL` 复用 `modules/`。
  `wsl -d NixMEOW-WSL` 就能在 Windows 里开 NixOS 终端，GUI 走 WSLg。
  最贴合本次需求，但要维护第二个 host。
- **B. 现有 WSL 发行版里装 nix** —— 只复用 home-manager 部分，用不了 nixos 模块。
- **C. 只合并知识层** —— `/etc/nixos` clone + `~/.agents` 建远端做 git 同步，完全不碰 nix。
  零风险，可立刻做。

### 11.3 待用户决策（下次接手先问这四个）

1. `~/.agents` 谁是"主"、要不要建 GitHub 远端
2. 要不要划共享分区（需先缩 C:）、用 **NTFS** 还是 **btrfs + WinBtrfs**
3. kb-mcp 的模型端点跟哪边跑（双系统不能同时跑）
4. root 通道（`services.opencode-root`）要不要一起合（建议暂不动）

### 11.4 下次接手的动作

1. **先把第一部分（§2–§9）修完** —— 别在坏地基上盖楼
2. 拿 §11.3 的四个问题去问用户
3. 决策完再动手，**别一上来就装 NixOS-WSL**
4. 走路线 A 时单独开 session + 开 feature branch

---

## 12. 新 session 上手信息（2026-09-22 准备）

**推荐工作目录：`C:\Users\reiky\.agents`**

- 交接文档就在 `.agents/dialogue/` 下，一进去就能看到
- 该目录已有项目级 `AGENTS.md`，启动 session 会自动加载，**等于自带提示词**
- 也是方案 C（知识层合并）将来的核心目录

**关键实测：现有两个 WSL 发行版都不适合当主力**

| 发行版 | git | python3 | nix | node |
|---|---|---|---|---|
| `archlinux` | ❌ | ❌ | ❌ | ❌ |
| `Ubuntu` | ✅ | ✅ | ❌ | ❌ |

→ 按规划原则（§11.1）**主线是装 NixOS-WSL 当主力**，别去建设这两个发行版喵~
但**在 NixOS-WSL 装好之前**，临时干活（挂载 + 文件操作 + git）可以用
`wsl -d Ubuntu -- ...` 顶上喵~
（挂载本身用哪个发行版都行，`/mnt/wsl` 是各发行版共享的 tmpfs）喵~

**`.agents` 的 git 状态（Windows 侧）**

- 已 `git init`，分支 `main`，已做首次提交
- **尚未配置远端**
- ⚠️ 与 NixOS 侧 `~/.agents`（本地仓库，有自己的历史）**历史不相关**，合并二选一：
  - **a) 以 NixOS 为主（推荐）**：NixOS 侧建 GitHub 私有库 → 推送 →
    Windows 侧备份后重新 clone → 再把 Windows 的适配（skills 依赖段落等）作为一次 commit 推回
  - b) 直接合并：`git remote add origin <repo>` + `git pull --allow-unrelated-histories`
    （容易乱，不推荐）
- ⚠️ Windows 侧 `skills/` 是**适配版**、NixOS 侧是 **nix 版**，内容不同，合并时需人工处理，
  **别直接覆盖**

**一句话起手式**

> 读 `.agents/dialogue/HANDOFF-2026-09-22-nixos-opencode-v2.md`，
> 按它的 §2 挂载分区、§6 核实、§5 修复；修完再问 §11.3 的四个决策点。
