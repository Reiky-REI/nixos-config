generate-opencode:
    .agents/config/generate-opencode.sh

generate-claude:
    .agents/config/generate-claude.sh

generate-all: generate-opencode generate-claude

# 验证配置（验证通过后记得写复盘）
rebuild:
    nixos-rebuild build --flake /etc/nixos#NixMEOW
    @echo '==> 验证通过。如需写复盘: .agents/knowledge/retros/$(date +%F)-<topic>.md'

# 下载 APK 并安装到 Waydroid
install-apk name url:
    curl -L -o /tmp/{{name}}.apk {{url}}
    waydroid app install /tmp/{{name}}.apk
