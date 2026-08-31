# ===== NAS WebDAV 挂载配置 =====
# 通过 rclone mount 挂载 NAS WebDAV 到 ~/nas
#
# NAS 信息:
#   地址: 192.168.124.8
#   WebDAV: https://192.168.124.8:5006/sata11-15585280324
#   协议: WebDAV (SMB 不可用)
#
# 迁移计划（释放 ~7.2G 本地空间）:
#   ~/WorkSpace/models (6.5G) -> ~/nas/models
#   ~/Pictures (455M)         -> ~/nas/Pictures
#   ~/Documents (282M)        -> ~/nas/Documents
{
  config,
  lib,
  pkgs,
  ...
}: let
  username = "Reiky-REI";
  nas_ip = "192.168.124.8";
  nas_webdav_port = 5006;
  nas_share = "sata11-15585280324";
  mount_point = "/home/${username}/nas";
  home = "/home/${username}";
in {
  # 安装 rclone
  environment.systemPackages = [pkgs.rclone];

  # rclone 配置文件
  environment.etc."rclone/rclone.conf".text = ''
    [nas-webdav]
    type = webdav
    url = https://${nas_ip}:${toString nas_webdav_port}/${nas_share}
    vendor = other
    user = 15585280324
    pass = g-hI69r5XVhwEzIbMMertH7TU1u5KADIbo5o
    tls_skip_verify = true
  '';

  # systemd 服务：开机自动挂载 NAS WebDAV
  systemd.services.nas-mount = {
    description = "Mount NAS WebDAV to ~/nas";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mount_point}";
      ExecStart = "${pkgs.rclone}/bin/rclone mount nas-webdav: ${mount_point} --config /etc/rclone/rclone.conf --no-check-certificate --vfs-cache-mode full --vfs-cache-max-size 5G --vfs-cache-max-age 24h --dir-cache-time 72h --attr-timeout 72h --no-modtime --allow-other --allow-non-empty --volname nas";
      ExecStop = "/run/current-system/sw/bin/fusermount -uz ${mount_point}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # 确保挂载点目录存在
  systemd.tmpfiles.rules = [
    "d ${mount_point} 0755 ${username} users -"
  ];

  # 挂载后自动迁移数据并创建符号链接
  # ⚠️ 首次迁移需要手动触发: systemctl start nas-migrate.service
  systemd.services.nas-migrate = {
    description = "Migrate data to NAS";
    after = ["nas-mount.service"];
    wants = ["nas-mount.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nas-migrate.sh" ''
        #!/bin/bash
        set -e

        echo "=== NAS 数据迁移 ==="

        # 等待挂载就绪
        for i in $(seq 1 30); do
          if [ -d "${mount_point}" ] && [ "$(ls -A ${mount_point} 2>/dev/null)" ]; then
            break
          fi
          echo "等待 NAS 挂载... ($i/30)"
          sleep 2
        done

        if [ ! -d "${mount_point}" ] || [ ! "$(ls -A ${mount_point} 2>/dev/null)" ]; then
          echo "NAS 未就绪，跳过迁移"
          exit 1
        fi

        # 迁移 models (6.5G)
        if [ -d "${home}/WorkSpace/models" ] && [ ! -L "${home}/WorkSpace/models" ]; then
          echo "迁移 models -> nas/models ..."
          mkdir -p ${mount_point}/models
          rsync -av --remove-source-files "${home}/WorkSpace/models/" "${mount_point}/models/" 2>/dev/null || true
          rm -rf "${home}/WorkSpace/models"
          ln -s "${mount_point}/models" "${home}/WorkSpace/models"
          echo "  ✓ models 迁移完成"
        fi

        # 迁移 Pictures (455M)
        if [ -d "${home}/Pictures" ] && [ ! -L "${home}/Pictures" ]; then
          echo "迁移 Pictures -> nas/Pictures ..."
          mkdir -p ${mount_point}/Pictures
          rsync -av --remove-source-files "${home}/Pictures/" "${mount_point}/Pictures/" 2>/dev/null || true
          rm -rf "${home}/Pictures"
          ln -s "${mount_point}/Pictures" "${home}/Pictures"
          echo "  ✓ Pictures 迁移完成"
        fi

        # 迁移 Documents (282M)
        if [ -d "${home}/Documents" ] && [ ! -L "${home}/Documents" ]; then
          echo "迁移 Documents -> nas/Documents ..."
          mkdir -p ${mount_point}/Documents
          rsync -av --remove-source-files "${home}/Documents/" "${mount_point}/Documents/" 2>/dev/null || true
          rm -rf "${home}/Documents"
          ln -s "${mount_point}/Documents" "${home}/Documents"
          echo "  ✓ Documents 迁移完成"
        fi

        echo "=== NAS 迁移完成 ==="
      '';
      User = username;
    };
  };
}
