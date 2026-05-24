# Nix → SKILL.md 声明式生成模板

# 注意: 本文件为未经验证的模板。
# 目标: 从 Nix module 生成符合 agentskills.io 标准的 SKILL.md

{ config, pkgs, lib, ... }:
let
  # ============================================================
  # Skill 内容定义 (Markdown + YAML frontmatter)
  # ============================================================
  skillContent = ''
    ---
    name: my-skill-name
    description: 一句话描述这个技能做什么，Agent 何时触发
    allowed-tools: [read, write, bash(organize, mv, ln), edit]
    context: auto
    ---

    # 技能名称

    ## 适用场景
    描述在什么情况下应该使用这个技能。

    ## 安全约束
    - 绝对不访问: ~/.ssh/, ~/.gnupg/, ~/Documents/private/
    - 操作前先 dry-run
    - 操作后更新目录的 .ai-rules.toml 中的 experience 字段

    ## 步骤
    1. 读当前目录的 .ai-rules.toml
    2. 按配置规则分类文件
    3. dry-run 验证: `organize sim`
    4. 执行: `organize run`
    5. 更新 .ai-rules.toml 的 [ai.experience]
    6. 记录: 追加到 activity.jsonl
    7. 通知: `notify-send "整理了 N 个文件"`
  '';
in {
  # ============================================================
  # 生成 SKILL.md (路径因 agent 而异)
  # ============================================================
  home.file.".config/opencode/skills/my-skill-name/SKILL.md" = {
    text = skillContent;
  };
  # 如果同时支持多个 agent:
  # home.file.".claude/skills/my-skill-name/SKILL.md".text = skillContent;
  # home.file.".agents/skills/my-skill-name/SKILL.md".text = skillContent;
}
