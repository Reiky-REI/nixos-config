{
  # ===== AI agent 注册表 =====
  # 三个客户端共用一份定义: opencode / claude / codex。
  #
  # 作用域规则 (2026-09-27 用户裁定):
  #   - hosts 默认 = 全部 host
  #   - users 必须显式列出, 没有默认
  #   - privileged = true 的 agent 还必须写非空 hosts.allow
  #
  # 实际生效范围是 (agent, user, host) 三者的交集:
  #   agent 的 users ∩ host 绑定的 users, 且 agent 在该 host 作用域内。
  #
  # 各客户端专属的排版/样板 (权限表、CLAUDE.md 章节等) 仍在对应适配层,
  # 这里只描述"有哪些 agent、归谁用、能上哪些机器、用什么模型和系统提示"。
  opencode-plan = {
    client = "opencode";
    id = "plan";
    default = true;
    model = "deepseek/deepseek-v4-flash";
    system = ''
      开工前互查:
      1. git status + git branch -a → 确认没有对方新建/残留的分支或未提交改动
      2. git log --oneline -10 → 对方最近提交了什么, 是否影响本次任务
      3. 扫 requests/pending/ → 有对方留下的待办申请, 先处理再开工
      4. 查看 retros/ 最新 3-5 条 → 对方最近在做什么, 避免冲突
      5. 查 known-issues.md → 避免已知踩坑
      改完后:
      6. 构建验证 (nixos-rebuild build / nix build)
      7. 写复盘到 .agents/knowledge/retros/<date>-<topic>.md
      8. 用 commit.sh 提交 + 推送分支
    '';
    users = ["reiky"];
    hosts = {all = true;};
  };

  claude-code = {
    client = "claude";
    users = ["reiky"];
    hosts = {all = true;};
  };

  codex-cli = {
    client = "codex";
    model = "deepseek-chat";
    providerName = "DeepSeek";
    baseUrl = "https://api.deepseek.com/v1";
    envKey = "DEEPSEEK_API_KEY_REIKY_REI";
    users = ["reiky"];
    hosts = {all = true;};
  };
}
