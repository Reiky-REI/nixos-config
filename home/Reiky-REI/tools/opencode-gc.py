#!/usr/bin/env python3
# opencode-gc — 清理旧的 opencode 会话数据, 控制数据库体积 (加速启动)。
#
# 2026-09-26 重写: 原 bash 版清的是 v1 的 opencode-stable.db, 而 v2 数据落在
# opencode.db (表结构也不同: 会话在 session_v2, 消息在 session_message),
# 导致 v2 库永远不被清理。本版:
#   - 只清 v2 的 opencode.db (缺省保留最近 7 天)
#   - 自动探测表结构 (v2 的 session_v2/session_message + 兼容残留的 v1 表)
#   - 事务内删除, 再 VACUUM/ANALYZE
#   - busy_timeout: opencode 正在运行时也不会硬失败 (拿不到锁就跳过)
import os
import sqlite3
import sys
import time

RETENTION_DAYS = 7
DATA_DIR = os.path.join(os.path.expanduser("~"), ".local", "share", "opencode")
DB_PATH = os.path.join(DATA_DIR, "opencode.db")  # v2 实际使用的库 (v1 是 opencode-stable.db, 不动)


def log(msg: str) -> None:
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}", flush=True)


def human(n: int) -> str:
    for unit in ("B", "K", "M", "G"):
        if n < 1024:
            return f"{n:.1f}{unit}"
        n /= 1024
    return f"{n:.1f}T"


def tables(con: sqlite3.Connection) -> set:
    return {r[0] for r in con.execute("select name from sqlite_master where type='table'")}


def main() -> int:
    if not os.path.isfile(DB_PATH):
        log(f"数据库不存在, 跳过: {DB_PATH}")
        return 0

    cutoff = int((time.time() - RETENTION_DAYS * 86400) * 1000)  # 毫秒时间戳
    size_before = os.path.getsize(DB_PATH)
    log(f"开始清理 {DB_PATH} ({human(size_before)}), 保留最近 {RETENTION_DAYS} 天")

    try:
        con = sqlite3.connect(DB_PATH, timeout=10)
    except sqlite3.Error as e:
        log(f"无法打开数据库 (跳过): {e}")
        return 0

    try:
        con.execute("pragma busy_timeout=8000")
        T = tables(con)

        with con:  # 单事务
            removed = 0
            # ── v2 结构 ──
            if "session_v2" in T:
                sub = "select id from session_v2 where time_updated < ?"
                for t in ("session_message", "session_inbox", "session_pending", "todo"):
                    if t in T:
                        cur = con.execute(f"delete from {t} where session_id in ({sub})", (cutoff,))
                        removed += cur.rowcount or 0
                cur = con.execute("delete from session_v2 where time_updated < ?", (cutoff,))
                removed += cur.rowcount or 0
                log(f"  v2: session_v2 及相关行删除 {removed} 行")
            # ── 兼容残留的 v1 表 (若仍在同一库) ──
            if "session" in T:
                sub = "select id from session where time_updated < ?"
                for t in ("part", "message", "todo"):
                    if t in T:
                        con.execute(f"delete from {t} where session_id in ({sub})", (cutoff,))
                con.execute("delete from session where time_updated < ?", (cutoff,))
                log("  v1 残留表已清理")

        # VACUUM/ANALYZE 必须在事务外
        con.execute("vacuum")
        con.execute("analyze")
    except sqlite3.Error as e:
        log(f"清理出错 (数据库可能被占用, 已保留原状): {e}")
        return 1
    finally:
        con.close()

    size_after = os.path.getsize(DB_PATH)
    log(f"清理完成: {human(size_before)} -> {human(size_after)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
