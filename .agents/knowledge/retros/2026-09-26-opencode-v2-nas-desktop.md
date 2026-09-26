---
id: opencode-v2-nas-desktop-fix
date: 2026-09-26
module: opencode/storage/desktop
tags: [opencode, v2, plugin, nas, smb, noctalia, wallpaper, windows-mount, agenix]
severity: medium
status: resolved
related: [dialogue/2026-09-22-001-windows-to-nixos-opencode-v2-fix-and-capability-merge.md, known-issues.md]
---

# OpenCode v2 转正 + NAS/Noctalia 桌面修复 (2026-09-26)

承接 Windows 端交接文档
(`dialogue/2026-09-22-001-windows-to-nixos-opencode-v2-fix-and-capability-merge.md`),
处理三件事 + 推进双系统共享喵~ 结论: **插件骨架/配置全转 V2 已做完, NAS 改 SMB+按 MAC 发现,
Noctalia 壁纸回本地; 双系统 WSL 侧收尾与知识树统一留待办** 喵~

## 一、OpenCode 插件系统 (头号问题)

### 根因
- HM 软链 `~/.config/opencode/plugins/edit-backup.js` 指向 nix store, 里面还是 **V1** 写法;
  **V2 不执行 V1 插件实现** (移动文件/改配置名都不够)。
- 日志实证:
  `failed to load plugin ... Plugin must export a default definition with an id and an effect or setup function. (SchemaError(Missing key at ["default"]))`

### 修复
- `.opencode/plugins/edit-backup.js` 迁移到 V2:
  `export default { id, setup(ctx) }` + `ctx.tool.hook("execute.before", event)`, 事件取 `event.tool` / `event.input`。
  依据 `https://opencode.ai/v2/docs/build/plugins/migrate-v1` (官方文档)。
- 两份配置转 V2 形态 (用 `opencode debug config` **实测**每个字段被接受):
  `providers` (+ `settings`), `permissions[]`, `agents.<id>.system`, `mcp.servers`, `skills`, `plugins`, `update`。
- `opencode-gc` 重写为**声明式 python** (HM 部署), 指向 v2 实际在用的 `opencode.db`
  (旧 bash 版清的是 v1 的 `opencode-stable.db`, v2 库永远清不到)。
- `.agents/config/generate-opencode.sh` 同步改: 写 `agents.plan.system` (原 `agent.plan.prompt`),
  并修正失效路径 `hosts/MEOW` -> `hosts/NixMEOW`。
- `.opencode/package.json` 去掉无用的 `@opencode-ai/plugin` 依赖 (插件零 import)。

### 关键发现 (踩坑)
- V2 **接受但不加载** `instructions` 条目 (官方原话 "accepts this field but does not load its entries");
  指令链实际靠 `AGENTS.md`。`instructions` 保留仅为记录意图。
- `https://opencode.ai/config.json` 的 schema 仍是 **V1 形态** (`plugin`/`provider`/`permission`/`agent`),
  但 v2.0.10 二进制两者都认 (内部归一化); 判断以 `opencode debug config` 输出为准。
- 归一化映射: `provider.options` -> `providers.settings`; `permission.bash.*` -> `permissions[]`(action=shell);
  `agent.<id>.prompt` -> `agents.<id>.system`; `mcp.<name>` -> `mcp.servers.<name>`; `autoupdate` -> `update`。

## 二、Noctalia 启动慢

### 根因
- `~/.config/noctalia/settings.json` 的 `wallpaper.directory = /home/Reiky-REI/nas/Pictures`;
  NAS 离线时 `ls ~/nas/` **实测阻塞 30.7 秒** (rclone VFS full + `no route to host` 反复重试, D 态连 `timeout` 都杀不掉),
  Noctalia 启动扫壁纸列表/还原壁纸就卡在这里。
- `~/.cache/noctalia/wallpapers.json` 记录的当前壁纸也在 NAS。

### 修复
- 壁纸目录改本地 `/home/Reiky-REI/Pictures/Wallpapers/static`; cache 改指本地副本。
- NAS 挂载改"快速失败 + 发现不到就跳过"(见三), 不再让 UI 等它。

## 三、NAS + 壁纸

### 根因
1. **NAS IP 漂移**: 旧配置写死 `192.168.124.8`, 实际已漂到 `192.168.124.9`
   (极空间 Z4Pro, 主机名 `Z4Pro-5XES`, MAC `1c:83:41:e4:3c:d4`); 且 NAS 不广播 mDNS。
2. 协议是 WebDAV (known-issues 明说"WebDAV 写入不可靠, 只适合读")。
3. `modules/storage/nas-mount.nix` 里的 `nas-migrate.service` 使用被 AGENTS.md 铁律**明令禁止**的
   `rsync --remove-source-files` + `rm -rf` —— 正是 2026-08-31 丢失 7.2G 的元凶代码, **一直没删**。
4. `~/Pictures` / `~/Documents` 是事故残留的空 root 目录。

### 修复
- 重写 `modules/storage/nas-mount.nix`:
  - **SMB/CIFS** 挂载 `//<ip>/ReikyZconnect` 到 `~/nas` (uid/gid 映射, vers=3.0)。
  - **按 MAC 发现**: 先查 ARP 邻居表, 未命中则并行 ping 扫本网段再查表; 找不到就跳过 (nofail)。
  - 凭据走 agenix `nas-smb-credentials` (原为空占位, 已填充 `username=/password=`)。
- **删除 `nas-migrate.service`** (消除复炸风险)。
- 壁纸 `119923025_p0.png` 从 NAS **复制**回本地 (只复制不删源, 遵铁律)。
- `~/Pictures`/`~/Documents` 空 root 目录: 删除清单留证 (`~/.local/state/delete-manifests/`) 后重建为用户可写。

### 损失确认
- NAS 上 `ReikyZconnect/Pictures` 只剩 `119923025_p0.png` 一个文件;
  其余壁纸 (Wallpapers 397M + icons 59M + 头像 204K) 确系 2026-08-31 事故永久丢失。
- 壁纸不在 git 历史中 (`git rev-list --all --objects` 命中 0), 本地不可恢复。

## 四、Windows 家目录挂载 (用户新需求)

- `/dev/nvme1n1p3` (label Windows, UUID `B67E33C97E3380E3`, ntfs3) **只读**挂 `/mnt/windows`,
  `systemd.tmpfiles` 建软链 `~/win -> /mnt/windows/Users/reiky`。
- `automount` + `nofail` + idle-timeout: Windows 不存在/脏位时不阻塞启动;
  只读是为规避 hiberfil/快速启动的写入损坏 + `modules/common` 已记录的 nvme1 关机 I/O 超时问题。
- 直接收益: 可读 Windows 的 `opencode.db` (19 会话/1489 消息的历史)、`.agents`、`.ssh`。

## 五、双系统共享 + 知识库 (部分完成)

- `~/.agents` 建私有远端并推送: `https://github.com/Reiky-REI/agents-knowledge`
  (新增 `.gitignore`: 排除可重建的 kb-mcp 向量索引与密钥)。
- 说明: `/etc/nixos/.agents` (随 nixos-config 仓库走, cwd 在 /etc/nixos 时 kb-mcp 命中的"项目级根")
  与 `~/.agents` (用户级根, 独立 git 仓, 含 memory/rules/skills/flake) 是 kb-mcp **多根设计**下的
  两套根, **并非重复 bug**; 本次补的是用户级根缺失的远端。
- WSL host 收尾 (nix 代理/access-tokens 声明式化) 与 Linux 侧能力对齐 **未完成** (待办)。

## 六、壁纸体系收口: 移除 awww/swww

- 现象: 设好壁纸仍黑屏 —— 因为 **Noctalia 自带的 `noctalia-background` 是 niri Top layer**,
  盖住了 awww 的 Background layer; 旧状态里 Noctalia 记的是 NAS 路径 → 黑。
- 决定: 以 **Noctalia 自带壁纸渲染** 为唯一壁纸渲染器, 移除 awww/swww (冗余且互相遮挡)。
- 改动:
  - `desktop/wallpaper/swww.nix` → `wallpaper.nix` (去掉 `home.packages=[awww]`)
  - `swww-rofi.sh` → `wallpaper-rofi.sh`: 静态图改走 `noctalia-shell ipc call wallpaper set <path> <screen>`
  - `niri/sections/high.kdl`: 删掉 `spawn-at-startup awww-daemon`
  - `niri/sections/base.kdl`: `Mod+Shift+W` 指向改名后的脚本
  - `README.md`: 新增"壁纸管理"小节说明
- 立即恢复: `noctalia-shell ipc call wallpaper set ~/Pictures/Wallpapers/static/119923025_p0.png <screen>` 已生效。
- 遗留: 视频壁纸 mpvpaper 同样受 Noctalia 顶层背景限制, 后续应迁到 Noctalia `video-wallpaper` 插件。

## 待办
1. **switch/reboot 后验收** (AI 不主动 switch): 日志无 `failed to load plugin` +
   改文件后 `~/.local/state/opencode-edit-backups/<今天>/` 出快照。
2. 统一 `/etc/nixos/.agents` 与 `~/.agents` 两份知识树。
3. WSL host (`hosts/NixMEOW-WSL`) 的 nix 代理/access-tokens 声明式化 + 能力标签对齐。
4. Windows 侧 `C:\Users\reiky\.agents` 改为 clone `agents-knowledge`, Windows 适配作为一次 commit 并入。
5. (可选) 清理 v1 遗留库 `opencode-stable.db` (94M+100M+75M 损坏副本)。
6. 用户在 Windows 上还有壁纸的话, 可通过 `~/win/Pictures` 取回。

## 教训
- 交接文档方向对, 但**插件 API 只认 V2、config 还能 V1**; 一切以官方 v2 文档 + `opencode debug config` 实测为准。
- 写死 IP 的配置在动态网络上必崩; 用**身份 (MAC/名字)** 而非地址。
- **事故复盘写了 ≠ 隐患消除**: `nas-migrate` 的危险代码一直躺在配置里, 这次才真正删掉。
