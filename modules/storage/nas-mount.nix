# ===== NAS 挂载 (SMB/CIFS + 按 MAC 发现) =====
# 背景 (2026-09-26):
#   - NAS 是 极空间 Z4Pro ("Z4Pro-5XES"), IP **每周变一次** (旧配置写死 192.168.124.8 已失效),
#     且不广播 mDNS → 改按 **MAC** 在本地网段扫描发现。
#   - 协议由 WebDAV 改为 **SMB/CIFS** (2026-08-31 7.2G 数据丢失事故根因就是 WebDAV 写入静默失败,
#     known-issues 明说"WebDAV 写入不可靠, 优先 SMB/NFS")。
#   - 凭据走 agenix 密钥 `nas-smb-credentials` (mkHost 在 agenix-secrets feature 下注入, 内容:
#     username=/password=)。
#   - ⛔ 已删除旧 `nas-migrate.service`: 它使用被 AGENTS.md 铁律禁止的
#     `rsync --remove-source-files` + `rm -rf` 迁移本地数据, 是 7.2G 事故的元凶代码。
{
  config,
  lib,
  pkgs,
  ...
}: let
  username = "Reiky-REI";
  user = config.users.users.${username};
  group = config.users.groups.${user.group};
  nasMac = "1c:83:41:e4:3c:d4"; # 极空间 Z4Pro 网卡 MAC (发现用)
  share = "ReikyZconnect"; # 个人空间: 含 models / Pictures / documents
  mountPoint = "/home/${username}/nas";
  credPath = config.age.secrets.nas-smb-credentials.path;

  # 按 MAC 在当前网段找 NAS, 输出 IP (stdout); 找不到返回非 0。
  # 顺序: 先查 ARP 邻居表 (命中快) → 再并行 ping 扫本网段 → 再查表。
  discover = pkgs.writeShellScript "nas-discover" ''
    set -u
    MAC="${nasMac}"
    IP=""
    AWK=${pkgs.gawk}/bin/awk
    IPCMD=${pkgs.iproute2}/bin/ip
    PING=${pkgs.iputils}/bin/ping

    lookup() {
      local dev="$1"
      # 不依赖字段位置: ip neigh 的格式随是否带 "dev" 而变 (IP [dev X] lladdr MAC STATE),
      # 直接扫描整行找 MAC, 命中则打印行首的 IP。
      "$IPCMD" -4 neigh show dev "$dev" 2>/dev/null \
        | "$AWK" -v m="$MAC" '{ for (i = 1; i <= NF; i++) if (tolower($i) == tolower(m)) { print $1; exit } }'
    }

    for dev in $("$IPCMD" -o link show up | "$AWK" -F': ' '{print $2}'); do
      [ "$dev" = "lo" ] && continue
      IP=$(lookup "$dev")
      [ -n "$IP" ] && { echo "$IP"; exit 0; }

      NET=$("$IPCMD" -4 -o addr show dev "$dev" scope global 2>/dev/null | "$AWK" '{print $4}' | head -1)
      [ -z "$NET" ] && continue
      BASE=$(echo "$NET" | cut -d/ -f1 | cut -d. -f1-3)
      for i in $(seq 1 254); do "$PING" -c1 -W1 "$BASE.$i" >/dev/null 2>&1 & done
      wait

      IP=$(lookup "$dev")
      [ -n "$IP" ] && { echo "$IP"; exit 0; }
    done
    exit 1
  '';
in {
  config = lib.mkIf (config.meow.enabled ? "nas-smb") {
    environment.systemPackages = [pkgs.cifs-utils];

    # 挂载点目录 (用户可写, 便于手动操作)
    systemd.tmpfiles.rules = [
      "d ${mountPoint} 0755 ${username} ${user.group} -"
    ];

    systemd.services.nas-mount = {
      description = "Discover (by MAC) and mount NAS ${share} via SMB/CIFS";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # NAS 不在线/不在本网段时优雅跳过, 绝不阻塞启动
        TimeoutStartSec = "90s";
      };
      script = ''
        set -u
        IP="$(${discover})" || IP=""
        if [ -z "$IP" ]; then
          echo "NAS (MAC ${nasMac}) 未在本地网段发现, 跳过挂载 (nofail)"
          exit 0
        fi
        echo "NAS 发现于 $IP"

        ${lib.getBin pkgs.coreutils}/bin/mkdir -p ${mountPoint}
        if ${lib.getBin pkgs.util-linux}/bin/mountpoint -q ${mountPoint}; then
          ${lib.getBin pkgs.util-linux}/bin/umount -l ${mountPoint} || true
        fi

        if ${lib.getBin pkgs.cifs-utils}/bin/mount.cifs "//$IP/${share}" ${mountPoint} \
          -o "credentials=${credPath},uid=${toString user.uid},gid=${toString group.gid},iocharset=utf8,vers=3.0,_netdev"; then
          echo "已挂载 //$IP/${share} -> ${mountPoint}"
        else
          echo "CIFS 挂载失败 (凭据/共享名?), 跳过 (nofail)"
          exit 0
        fi
      '';
    };
  };
}
