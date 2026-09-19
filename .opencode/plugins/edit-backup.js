// 改文件前自动快照 — 放开文件权限的安全网。
//
// 触发: tool.execute.before (edit / write / patch)
// 行为: 若目标文件已存在, 先把旧内容复制到
//       ~/.local/state/opencode-edit-backups/<YYYY-MM-DD>/<原绝对路径>
// 保留: 30 天, 每次进程生命周期内只清理一次
//
// 目的: 让 opencode 获得全目录读写权限时, 任何被覆盖/删除的文件都有
//       一份可直接找回的副本 (配合 git 形成双重保险)。

import {copyFile, mkdir, readdir, rm, stat} from "node:fs/promises";
import {homedir} from "node:os";
import {dirname, join, resolve, sep} from "node:path";

const BACKUP_ROOT = join(homedir(), ".local/state/opencode-edit-backups");
const RETENTION_DAYS = 30;
const FILE_TOOLS = new Set(["edit", "write", "patch", "multiedit"]);

const dayStamp = () => new Date().toISOString().slice(0, 10);

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

export const EditBackupPlugin = async () => {
  let pruned = false;
  return {
    "tool.execute.before": async (input, output) => {
      if (!FILE_TOOLS.has(input?.tool)) return;
      const args = output?.args ?? {};
      const target = args.filePath ?? args.path ?? args.file;
      if (typeof target !== "string" || target.length === 0) return;

      const abs = resolve(target);
      const st = await stat(abs).catch(() => null);
      if (!st?.isFile()) return; // 新文件无需备份

      if (!pruned) {
        pruned = true;
        void prune();
      }

      const dest = join(BACKUP_ROOT, dayStamp(), abs.slice(1).split(sep).join("/"));
      await mkdir(dirname(dest), {recursive: true});
      await copyFile(abs, dest);
    },
  };
};
