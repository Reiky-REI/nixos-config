{pkgs, ...}: {
  # 全局 edit 前自动快照插件 (与仓库 .opencode/plugins 同源, 内容见该文件)
  home.file.".config/opencode/plugins/edit-backup.js".source = ../../../.opencode/plugins/edit-backup.js;

  # opencode 数据库清理定时器
  systemd.user.services.opencode-gc = {
    Unit = {
      Description = "opencode 数据库清理";
      After = "network.target";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chmod +x $HOME/.local/bin/opencode-gc && $HOME/.local/bin/opencode-gc'";
    };
  };

  systemd.user.timers.opencode-gc = {
    Unit = {
      Description = "opencode 数据库清理定时器";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };
}
