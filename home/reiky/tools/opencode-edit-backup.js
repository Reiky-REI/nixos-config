// 改文件前自动快照 — 全局 OpenCode V2 安全网。
//
// 触发: ctx.tool.hook("execute.before")  (edit / write / patch / multiedit)
// 行为: 若目标文件已存在, 先把旧内容复制到
//       ~/.local/state/opencode-edit-backups/<YYYY-MM-DD>/<原绝对路径>
// 保留: 30 天, 每次进程生命周期内只清理一次
//
// 目的: 让 opencode 获得全目录读写权限时, 任何被覆盖/删除的文件都有
//       一份可直接找回的副本 (配合 git 形成双重保险)。
//
// ⚠️ 这是 OpenCode **V2** 插件 API 写法 (2026-09-22 从 V1 迁移):
//   - 不 import "@opencode/plugin": opencode 的本地插件加载器解析不到配置目录
//     里的裸包名; 而 Plugin.define(...) 的产物就是普通 { id, setup } 对象,
//     所以 `export default { id, setup }` 等价且零依赖。
//   - V1 的 "tool.execute.before" 钩子名在 V2 二进制里**根本不存在**
//     (实测: 该字符串出现 0 次), 不迁移 = 插件完全不生效。
//   参考: https://opencode.ai/v2/docs/build/plugins/migrate-v1

import {copyFile, mkdir, readdir, rm, stat} from "node:fs/promises";
import {homedir} from "node:os";
import {dirname, join, resolve, sep} from "node:path";

const BACKUP_ROOT = join(homedir(), ".local", "state", "opencode-edit-backups");
const RETENTION_DAYS = 30;
const FILE_TOOLS = new Set(["edit", "write", "patch", "multiedit"]);

const dayStamp = () => new Date().toISOString().slice(0, 10);

// "C:\\Users\\me\\a.txt" -> "Users/me/a.txt"; "/home/me/a.txt" -> "home/me/a.txt"
const toBackupRelPath = (abs) =>
  abs.replace(/^[A-Za-z]:/, "").split(sep).filter(Boolean).join("/");

function targetPathsFor(event) {
  const input = event?.input ?? {};
  const targets = new Set();

  const direct = input.filePath ?? input.path ?? input.file;
  if (typeof direct === "string" && direct.length > 0) targets.add(direct);

  if (event?.tool === "patch" && typeof input.patchText === "string") {
    for (const match of input.patchText.matchAll(/^\*\*\* (?:Update|Delete) File:\s*(.+?)\s*$/gm)) {
      targets.add(match[1]);
    }
  }

  if (event?.tool === "multiedit" && Array.isArray(input.edits)) {
    for (const edit of input.edits) {
      const path = edit?.filePath ?? edit?.path ?? edit?.file;
      if (typeof path === "string" && path.length > 0) targets.add(path);
    }
  }

  return [...targets];
}

async function prune() {
  try {
    const cutoff = Date.now() - RETENTION_DAYS * 86400000;
    for (const entry of await readdir(BACKUP_ROOT)) {
      const p = join(BACKUP_ROOT, entry);
      const st = await stat(p).catch(() => null);
      if (st?.isDirectory() && st.mtimeMs < cutoff) {
        await rm(p, {recursive: true, force: true});
      }
    }
  } catch {
    // 备份目录还不存在等情况, 忽略
  }
}

export default {
  id: "edit-backup",
  async setup(ctx) {
    let pruned = false;

    await ctx.tool.hook("execute.before", async (event) => {
      if (!FILE_TOOLS.has(event?.tool)) return;

      const targets = targetPathsFor(event);
      if (targets.length === 0) return;

      if (!pruned) {
        pruned = true;
        void prune();
      }

      for (const target of targets) {
        const abs = resolve(target);
        const st = await stat(abs).catch(() => null);
        if (!st?.isFile()) continue; // 新文件无需备份

        const dest = join(BACKUP_ROOT, dayStamp(), toBackupRelPath(abs));
        await mkdir(dirname(dest), {recursive: true});
        await copyFile(abs, dest);
      }
    });
  },
};
