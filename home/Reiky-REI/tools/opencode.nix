{pkgs, ...}: {
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
