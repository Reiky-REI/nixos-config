generate-opencode:
    .agents/config/generate-opencode.sh

generate-claude:
    .agents/config/generate-claude.sh

generate-all: generate-opencode generate-claude

# 格式化所有 nix 文件
fmt:
    alejandra .

# 预览格式化改动（不实际写文件）
check-fmt:
    alejandra --check .

# 静态分析
lint:
    statix check .

# 检查 README 引用的仓库路径是否仍存在 (防重命名/删除后文档漂移)
check-docs:
    .agents/config/check-docs.sh

# 完整验证：格式化检查 + 静态分析 + 文档路径检查 + flake 构建 + 系统验证
check: check-fmt lint check-docs
    nix flake check

# 验证配置（验证通过后记得写复盘）
rebuild:
    nixos-rebuild build --flake /etc/nixos#NixMEOW
    @echo '==> 验证通过。如需写复盘: .agents/knowledge/retros/$(date +%F)-<topic>.md'

# 切换系统 (经 rebuild.sh: 代 proxy/token/黑屏警告; 结束后自动做世代保留预览)
switch:
    sudo .agents/config/rebuild.sh switch
