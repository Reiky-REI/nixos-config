{
  pkgs,
  lib,
  ...
}: let
  # 队列消费者 (唯一真相: .agents/config/agent-resume-runner.sh)
  runner = pkgs.writeShellScript "agent-resume-runner" (builtins.readFile ../../../.agents/config/agent-resume-runner.sh);
in {
  # 无人值守续命队列: path 秒触发 + timer 兜底, 任务本身由 runner 用 user systemd-run 跑,
  # 因此 AI 会话/服务重启不会中断已入队的任务喵~
  #
  # 依赖: `loginctl enable-linger` 让 user manager 不依赖登录会话 (系统级设置, 见 hosts/)。
  systemd.user.services.agent-resume = {
    Unit = {
      Description = "NixMEOW agent resume queue runner (无人值守续命队列)";
      # 队列里通常只有 0-1 个任务, 不因连续触发而停摆
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${runner}";
      # 每个任务由 transient unit 的 RuntimeMaxSec 单独限时; runner 可串行消费多个任务。
      TimeoutStartSec = "infinity";
    };
  };

  systemd.user.paths.agent-resume = {
    Unit = {
      Description = "Trigger resume runner whenever the queue has tasks";
      StartLimitIntervalSec = 60;
      StartLimitBurst = 30;
    };
    Path = {
      PathExistsGlob = "%h/.local/state/agent-resume/queue/*.task";
      Unit = "agent-resume.service";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.timers.agent-resume = {
    Unit.Description = "Fallback scan of the agent resume queue";
    Timer = {
      OnBootSec = "2min";
      OnUnitInactiveSec = "2min";
      AccuracySec = "10s";
      Persistent = true;
      Unit = "agent-resume.service";
    };
    Install.WantedBy = ["timers.target"];
  };
}
