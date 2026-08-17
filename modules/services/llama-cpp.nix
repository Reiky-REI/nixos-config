{ config, lib, pkgs, username, ... }: let
  cfg = config.services.llama-cpp;
  llamaPkg = pkgs.llama-cpp.override { cudaSupport = true; };
  modelsDir = "/home/${username}/WorkSpace/models/llama-cpp";
in {
  # nixpkgs 26.05 把官方 llama-cpp 模块列为默认模块之一,但其设计
  # (DynamicUser + ProtectHome + 单实例) 无法满足 home 模型 + 双端口,
  # 这里用 disabledModules 替换为下方自定义双实例服务。
  disabledModules = [ "services/misc/llama-cpp.nix" ];

  options.services.llama-cpp = {
    enable = lib.mkEnableOption "local llama.cpp servers (chat + embedding)";
  };

  config = lib.mkIf cfg.enable {
    # ── 本地 LLM 服务:llama.cpp server 双实例(CUDA 加速)──
    # 模型 GGUF 放 $HOME/WorkSpace/models/llama-cpp/:
    #   - Qwen3-8B-Q4_K_M.gguf          聊天主模型,8080,OpenAI 兼容
    #   - Qwen3-Embedding-0.6B-Q8_0.gguf embedding,8081,--embeddings
    # User=Reiky-REI 直接读 home 模型。

    systemd.services.llama-cpp-chat = {
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
            --ctx-size 8192 \
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
            --ctx-size 8192 \
            --gpu-layers 999
        '';
        Restart = "on-failure";
        RestartSec = "10s";
        PrivateDevices = false;
      };
    };
  };
}
