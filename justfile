generate-opencode:
    .agents/config/generate-opencode.sh

# 下载 APK 并安装到 Waydroid
install-apk name url:
    curl -L -o /tmp/{{name}}.apk {{url}}
    waydroid app install /tmp/{{name}}.apk
