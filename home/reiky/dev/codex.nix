{
  pkgs,
  lib,
  agentConfig,
  ...
}: let
  codexCfg = agentConfig.codex;

  # Codex CLI 读取并「自行改写」$CODEX_HOME/config.toml(默认 ~/.codex/config.toml):
  # 它会往里追加 [projects] / [notice] / [mcp_servers] 等运行态。因此不能用
  # home.file 软链托管 —— 只读的 store 目标会被 Codex 的原子写替换掉, 造成漂移。
  # 改用包装脚本, 以 `-c` 在运行时注入 provider(值来自 agents.nix 注册表),
  # 既声明式, 又不与 Codex 自管的 config.toml 冲突。
  # 注意: Codex >= 0.133 只接受 wire_api = "responses"(旧的 "chat" 会直接报错)。
  codex =
    if codexCfg == null
    then pkgs.codex
    else pkgs.writeShellScriptBin "codex" ''
      exec ${pkgs.codex}/bin/codex \
        -c 'model_provider="deepseek"' \
        -c 'model="${codexCfg.model}"' \
        -c 'model_providers.deepseek.name="${codexCfg.providerName}"' \
        -c 'model_providers.deepseek.base_url="${codexCfg.baseUrl}"' \
        -c 'model_providers.deepseek.env_key="${codexCfg.envKey}"' \
        -c 'model_providers.deepseek.wire_api="responses"' \
        -c 'project_doc_fallback_filenames=["AGENTS.md", ".agents/AGENTS.md"]' \
        -c 'project_doc_max_bytes=65536' \
        "$@"
    '';
in {
  home.packages = [codex];

  # 全局指令: 让 Codex 在任意仓库都遵循 NixMEOW 的工作纪律
  home.file.".codex/AGENTS.md".text = ''
    # Codex 全局指令 (NixMEOW)

    ## 开工必读
    在修改 NixMEOW 配置仓库 (/etc/nixos) 时, 开工前必须先按顺序阅读:
    1. .agents/AGENTS.md — 总纪律、协作规则、Git 工作流
    2. .agents/knowledge/INDEX.md — 知识索引
    3. .agents/knowledge/conventions.md — 编码约定
    4. .agents/knowledge/known-issues.md — 已知问题避坑
    5. .agents/knowledge/architecture.md — 仓库架构
    6. 扫 .agents/knowledge/retros/ 近期复盘

    ## 喵~ 规则
    输出自然语言时, 以"喵~ "替代句号, 以"喵,"替代逗号, 与仓库其他 AI 保持一致。

    ## Git 工作流
    - 始终在 feature branch 上工作, 禁止直接在 main 修改
    - 开工前 git status + git branch 确认工作区干净
    - 修改 Nix 配置后必须 nixos-rebuild build 验证
    - 非平凡变更完成后写复盘到 .agents/knowledge/retros/
    - 提交用 bot 身份, 提交后自己合并回 main 并删分支
    - 不要主动执行 nixos-rebuild switch (NVIDIA PRIME 崩溃风险), 用 build 验证后提示用户手动处理

    ## 系统变更申请
    处理 requests/pending/ 下的申请时: 读申请 → 执行 → 写复盘 → 归档到 requests/archive/
  '';
}
