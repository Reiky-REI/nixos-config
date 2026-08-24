{ config, lib, pkgs, username, ... }: let
  cfg = config.services.llama-cpp;
  llamaPkg = pkgs.llama-cpp.override { cudaSupport = true; };
  modelsDir = "/home/${username}/WorkSpace/models/llama-cpp";
in {
  # nixpkgs 26.05 把官方 llama-cpp 模块列为默认模块之一,但其设计
  # (DynamicUser + ProtectHome + 单实例) 无法满足 home 模型 + 多端口,
  # 这里用 disabledModules 替换为下方自定义多实例服务。
  disabledModules = [ "services/misc/llama-cpp.nix" ];

  options.services.llama-cpp = {
    enable = lib.mkEnableOption "local llama.cpp servers (chat + embedding + reranker)";
    # Qwen3-8B 聊天实例默认永久关闭(2026-08-24 用户裁定: 能力被云端模型替代且太蠢),
    # 保留开关以便未来换更强模型一键恢复。
    chat.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Qwen3-8B chat server on :8080";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── 本地 LLM 服务:llama.cpp server 多实例(CUDA 加速)──
    # 模型 GGUF 放 $HOME/WorkSpace/models/llama-cpp/:
    #   - Qwen3-8B-Q4_K_M.gguf                 聊天主模型,  8080, OpenAI 兼容 (默认关: chat.enable)
    #   - Qwen3-Embedding-0.6B-Q8_0.gguf       embedding,   8081,--embeddings
    #   - reranker/Qwen3-Reranker-0.6B.Q8_0.gguf rerank,    8082,--rerank
    # User=Reiky-REI 直接读 home 模型。
    # 显存注意: RTX 4070 Max-Q 只有 8G, 8B 全 GPU + 8192 ctx 会 OOM,
    #   故 chat 用 4096 ctx; embedding/rerank 0.6B 走 CPU(--gpu-layers 0)不占显存。

    systemd.services.llama-cpp-chat = lib.mkIf cfg.chat.enable {
      description = "llama.cpp chat server (Qwen3-8B, OpenAI-compatible :8080)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ "/run/current-system/sw" ];
      serviceConfig = {
        User = username;
        Group = "users";
        Type = "idle";
        KillSignal = "SIGINT";
        WorkingDirectory = modelsDir;
        ExecStart = ''
          ${llamaPkg}/bin/llama-server \
            --host 127.0.0.1 --port 8080 \
            -m ${modelsDir}/Qwen3-8B-Q4_K_M.gguf \
            --ctx-size 4096 \
            --gpu-layers 999 \
            --jinja
        '';
        Restart = "on-failure";
        RestartSec = "10s";
        PrivateDevices = false;
      };
    };

    systemd.services.llama-cpp-embedding = {
      description = "llama.cpp embedding server (Qwen3-Embedding-0.6B, :8081)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ "/run/current-system/sw" ];
      serviceConfig = {
        User = username;
        Group = "users";
        Type = "idle";
        KillSignal = "SIGINT";
        WorkingDirectory = modelsDir;
        ExecStart = ''
          ${llamaPkg}/bin/llama-server \
            --host 127.0.0.1 --port 8081 \
            -m ${modelsDir}/Qwen3-Embedding-0.6B-Q8_0.gguf \
            --embeddings \
            --pooling last \
            --ctx-size 4096 \
            --batch-size 1024 \
            --ubatch-size 1024 \
            --gpu-layers 0
        '';
        Restart = "on-failure";
        RestartSec = "10s";
        PrivateDevices = false;
      };
    };

    # ── 重排序服务:Qwen3-Reranker-0.6B (:8082, --rerank) ──
    # 模型必须用带 reranker 专用张量的工作版 GGUF(官方 convert_hf_to_gguf 转,
    # 本仓库用 Voodisss/Qwen3-Reranker-0.6B-GGUF-llama_cpp 的 Q8_0)。
    # 注意: mradermacher 等社区转换缺 cls.output.weight/pooling=RANK 元数据,
    # 会打出 e^-13 级垃圾分(见 llama.cpp#16407), 已弃用备份为 .broken-mradermacher.gguf。
    # rerank 与 embedding 是互斥模式, 故独立进程 8082; 0.6B 走 CPU 不占显存。
    systemd.services.llama-cpp-reranker = {
      description = "llama.cpp reranker server (Qwen3-Reranker-0.6B, :8082)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ "/run/current-system/sw" ];
      serviceConfig = {
        User = username;
        Group = "users";
        Type = "idle";
        KillSignal = "SIGINT";
        WorkingDirectory = modelsDir;
        ExecStart = ''
          ${llamaPkg}/bin/llama-server \
            --host 127.0.0.1 --port 8082 \
            -m ${modelsDir}/reranker/Qwen3-Reranker-0.6B.Q8_0.gguf \
            --alias qwen3-reranker \
            --rerank \
            --embedding \
            --pooling rank \
            --ctx-size 4096 \
            --batch-size 2048 \
            --ubatch-size 2048 \
            --gpu-layers 0
        '';
        Restart = "on-failure";
        RestartSec = "10s";
        PrivateDevices = false;
      };
    };
  };
}
