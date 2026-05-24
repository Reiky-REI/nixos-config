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
    - 软链接保留 30 天

    ## 步骤
    1. 识别需要处理的文件: `ls -lt ~/Downloads/ | head -20`
    2. 按规则分类:
       - *.pdf, *.docx → ~/documents/
       - *.jpg, *.png → ~/screenshot/archive/
    3. dry-run 验证: `organize sim`
    4. 执行: `organize run` + `ai-relocate`
    5. 记录: 追加到 activity.jsonl
    6. 通知: `notify-send "整理了 N 个文件"`
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
