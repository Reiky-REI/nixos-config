#!/bin/bash
# 归档说明 (2026-10-01):
#   来源: /etc/nixos/cleanup.sh (仓库根, 曾被 .gitignore 忽略)
#   背景: 早期手动磁盘清理脚本 (97% 磁盘占用事件), 交互式删除旧 generation / 清理缓存
#   状态: 已归档, 现由 skill: disk-cleanup 与 nix-collect-garbage 流程取代
# 系统磁盘清理脚本
# 当前磁盘使用率 97%，需要释放空间

set -e

echo "=========================================="
echo "  系统磁盘清理脚本"
echo "  当前磁盘使用情况:"
df -h /
echo "=========================================="

read -p "按 Enter 开始清理，Ctrl+C 取消..."

# ==========================================
# 1. 删除 3 天前的 Nix generations
# ==========================================
echo ""
echo ">>> 步骤 1: 删除 3 天前的 Nix generations..."

PROFILE="/nix/var/nix/profiles/system"

echo "  所有 generations:"
nix-env --list-generations --profile "$PROFILE"

# 获取当前最新 generation 的 ID
LATEST_ID=$(nix-env --list-generations --profile "$PROFILE" | tail -1 | awk '{print $1}')
echo ""
echo "  最新 generation: $LATEST_ID"
echo "  正在删除 3 天前的 generations..."

# 删除 3 天前的 generations（保留最新的）
for gen in $(nix-env --list-generations --profile "$PROFILE" | awk '{print $1}'); do
    if [ "$gen" -eq "$LATEST_ID" ]; then
        continue
    fi

    # 获取该 generation 的日期
    GEN_DATE=$(nix-env --list-generations --profile "$PROFILE" | grep "^ *$gen " | awk '{print $2}')
    GEN_EPOCH=$(date -d "$GEN_DATE" +%s 2>/dev/null || echo 0)
    CUTOFF_EPOCH=$(date -d '3 days ago' +%s)

    if [ "$GEN_EPOCH" -lt "$CUTOFF_EPOCH" ] && [ "$GEN_EPOCH" -gt 0 ]; then
        echo "  删除 generation $gen ($GEN_DATE)"
        sudo nix-env --delete-generation --profile "$PROFILE" "$gen" --yes 2>/dev/null || \
        echo "  警告: 无法删除 generation $gen，尝试其他方式..."
    fi
done

# ==========================================
# 2. 运行 Nix garbage collection
# ==========================================
echo ""
echo ">>> 步骤 2: 运行 Nix garbage collection..."

sudo nix-collect-garbage -d

echo "  Nix GC 完成"

# ==========================================
# 3. 清理系统临时文件
# ==========================================
echo ""
echo ">>> 步骤 3: 清理系统临时文件..."

echo "  清理 /tmp 中 3 天前的文件..."
sudo find /tmp -type f -atime +3 -delete 2>/dev/null || true
sudo find /tmp -type d -empty -delete 2>/dev/null || true

echo "  清理 /var/tmp..."
sudo find /var/tmp -type f -atime +3 -delete 2>/dev/null || true

# ==========================================
# 4. 清理日志文件
# ==========================================
echo ""
echo ">>> 步骤 4: 清理系统日志..."

echo "  限制 systemd journal 为 100M..."
sudo journalctl --vacuum-size=100M

echo "  清理 7 天前的压缩日志..."
sudo find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null || true
sudo find /var/log -type f -name "*.old" -mtime +7 -delete 2>/dev/null || true
sudo find /var/log -type f -name "*.[0-9]" -mtime +7 -delete 2>/dev/null || true

# ==========================================
# 5. 清理用户缓存（可选）
# ==========================================
echo ""
echo ">>> 步骤 5: 清理用户缓存..."

echo "  清理 Chrome 缓存..."
rm -rf ~/.cache/google-chrome/Default/Cache/* 2>/dev/null || true
rm -rf ~/.cache/google-chrome/Default/Code\ Cache/* 2>/dev/null || true

echo "  清理 pip 缓存..."
pip cache purge 2>/dev/null || true

echo "  清理 pnpm 缓存..."
pnpm store prune 2>/dev/null || true

echo "  清理 node-gyp 缓存..."
rm -rf ~/.cache/node-gyp/* 2>/dev/null || true

# ==========================================
# 6. 显示清理后的磁盘使用情况
# ==========================================
echo ""
echo "=========================================="
echo "  清理完成！"
echo "  当前磁盘使用情况:"
df -h /
echo "=========================================="

echo ""
echo "如果空间仍然不足，可以考虑:"
echo "1. 检查大文件: sudo du -sh /* | sort -rh | head -20"
echo "2. 检查 Nix store: sudo nix-store --gc --print-roots"
echo "3. 检查 Docker 镜像: docker system prune -a"
echo "4. 检查虚拟机镜像: sudo find /var/lib/libvirt -name '*.qcow2' -exec ls -lh {} \;"
