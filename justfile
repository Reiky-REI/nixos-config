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

# 完整验证：格式化检查 + 静态分析 + flake 构建 + 系统验证
check: check-fmt lint
    nix flake check

# 验证配置（验证通过后记得写复盘）
rebuild:
    nixos-rebuild build --flake /etc/nixos#NixMEOW
    @echo '==> 验证通过。如需写复盘: .agents/knowledge/retros/$(date +%F)-<topic>.md'

# 下载 APK 并安装到 Waydroid
install-apk name url:
    curl -L -o /tmp/{{name}}.apk {{url}}
    waydroid app install /tmp/{{name}}.apk
