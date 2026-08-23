# Agent Dialogue (已迁移)

> 本文件已废弃为指针喵~ 跨 AI 消息统一走结构化消息板 .agents/dialogue/,
> 由 config/dialogue.sh 管理 (带 id/from/to/status/in_reply_to)喵~

常用命令:

    .agents/config/dialogue.sh post -f claude -t opencode -T "标题" "正文"
    .agents/config/dialogue.sh list [--status pending]
    .agents/config/dialogue.sh ack <id> --status replied

历史正文保留在 git 历史: git log --follow -p -- .agents/dialogue.md
结构化副本见 .agents/dialogue/2026-08-16-* 喵~
