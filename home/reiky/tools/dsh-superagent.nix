# dsh-superagent — DeepSeek Harness 官方 Super-agent 研究原型
# (https://github.com/deepseek-ai/dsh-superagent-prototype, npm dsh-superagent-prototype)
#
# 形态: 独立 profile `superagent` (~/.dsh/profiles/superagent, 端口 3082),
# 与 dsh-fence 托管的 web profile (3080) 完全隔离 —— 原型会改进程级 PATH 和 git 配置,
# 官方文档明确要求不要和自己干活的 profile 混跑。
#
# 为什么用 user service 而不是像 dsh-fence 那样加 ProtectHome=read-only:
# 该原型以 danger-full-access 执行 Executor 会话, 需要写 ~/.config/gh-agent、
# ~/src 下的 worktree、~/.cache 等位置; 套上 dsh-fence 的围栏会直接把它跑废。
# 本机已 `loginctl enable-linger`, 所以 user manager 开机即起, 不依赖登录会话。
#
# profile 本体不在 nix 里声明: 它是研究原型, 升级节奏快, 用
# `dsh plugin --profile superagent add dsh-superagent-prototype@<ver>` 原地升级;
# 机器相关配置(端口/stateDir)写在 profile 的 cordis.patch.yml。
{pkgs, ...}: {
  systemd.user.services.dsh-superagent = {
    Unit = {
      Description = "dsh-superagent (DeepSeek Harness Super-agent prototype, http://127.0.0.1:3082)";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.dsh}/bin/dsh --profile superagent --no-open";
      WorkingDirectory = "%h";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = ["default.target"];
  };
}
