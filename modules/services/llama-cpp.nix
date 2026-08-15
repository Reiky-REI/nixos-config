{pkgs, ...}: {
  # 本地 LLM 服务(llama.cpp server,CUDA 加速)。
  # 相比 ollama-cuda,llama.cpp 的 CUDA 依赖小得多(不需要 libcublas/nvcc 全家桶),
  # 适合这台 100G 磁盘的机器。模型是 GGUF 格式,按需下载:
  #   - Qwen3-8B 主聊天模型(AstrBot 侧配 OpenAI 兼容 provider)
  #   - embedding 与 VL 后续按需加
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override {cudaSupport = true;};
    # 模型路径:先留空,服务起来后手动放 GGUF 再填(见 README)
    model = "/var/lib/llama-cpp/models/qwen3-8b-q4_k_m.gguf";
    host = "127.0.0.1";
    port = 8080;
    # OpenAI 兼容 API 常用参数
    extraFlags = [
      "--n-cpu"
      "0" # 全部用 GPU 层
      "--ctx-size"
      "8192"
    ];
    openFirewall = false;
  };
}
