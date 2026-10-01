#!/usr/bin/env python3
# 归档说明 (2026-10-01):
#   来源: /etc/nixos/decode_objects.py (仓库根, 曾被 .gitignore 忽略)
#   背景: 2026-08-29 沙箱写 git 对象受限时的一次性解码脚本, 把 /tmp/git-objects 下的
#         base64 对象写回 .git/objects; 相关复盘 retros/2026-09-01-git-corrupt-history-repair.md
#   状态: 已归档, 仅作历史参考; 现在可用系统级 systemd-run 正常执行 git, 不应再用本脚本
import os, base64, zlib

base_b64 = "/tmp/git-objects"
target = "/etc/nixos/.git/objects"

for fname in os.listdir(base_b64):
    if not fname.endswith(".b64"):
        continue
    parts = fname[:-3].split("_", 1)
    prefix = parts[0]
    obj_hash = parts[1]
    
    src = os.path.join(base_b64, fname)
    dst_dir = os.path.join(target, prefix)
    dst = os.path.join(dst_dir, obj_hash)
    
    os.makedirs(dst_dir, exist_ok=True)
    
    with open(src, "r") as f:
        data = base64.b64decode(f.read())
    
    with open(dst, "wb") as f:
        f.write(data)
    
    print(f"Written {prefix}/{obj_hash} ({len(data)} bytes)")

print("Done!")
