{pkgs, ...}: let
  # opencode v2 数据库清理脚本 (声明式部署, 见 opencode-gc.py)
  opencodeGc = pkgs.writeScript "opencode-gc" (builtins.readFile ./opencode-gc.py);
in {
  # 全局 edit 前自动快照插件 (与仓库 .opencode/plugins 同源, 内容见该文件)
  home.file.".config/opencode/plugins/edit-backup.js".source = ../../../.opencode/plugins/edit-backup.js;

  # opencode 数据库清理脚本 (替换历史遗留的手工真实文件, 故 force)
  home.file.".local/bin/opencode-gc" = {
    source = opencodeGc;
    executable = true;
    force = true;
  };

  # opencode 数据库清理定时器
  systemd.user.services.opencode-gc = {
    Unit = {
      Description = "opencode 数据库清理";
      After = "network.target";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${opencodeGc}";
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
