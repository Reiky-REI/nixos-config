import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  property string mode: "?"
  property string node: "-"
  property bool engineActive: false

  readonly property bool proxyOn: mode === "rule" || mode === "global"

  property int refreshInterval: pluginApi?.pluginSettings?.refreshInterval
    ?? pluginApi?.manifest?.metadata?.defaultSettings?.refreshInterval ?? 3000

  readonly property string apiBase: "http://127.0.0.1:9097"
  readonly property string apiAuth: "Bearer set-your-secret"

  function refresh() {
    if (!pollProc.running)
      pollProc.running = true;
  }

  function setMode(m) {
    root.mode = m; // 乐观更新, 轮询会纠正
    setProc.command = [
      "curl", "-s", "-o", "/dev/null", "-m", "5",
      "-X", "PATCH",
      "-H", "Authorization: " + apiAuth,
      "-H", "Content-Type: application/json",
      "-d", "{\"mode\":\"" + m + "\"}",
      apiBase + "/configs"
    ];
    setProc.running = true;
  }

  function toggleMode() {
    setMode(proxyOn ? "direct" : "rule");
  }

  Process {
    id: pollProc
    running: false
    command: ["sh", "-c",
      "curl -s -m 3 -H 'Authorization: " + apiAuth + "' '" + apiBase + "/configs'; echo '@@'; curl -s -m 3 -H 'Authorization: " + apiAuth + "' '" + apiBase + "/proxies/%E8%8A%82%E7%82%B9%E9%80%89%E6%8B%A9'"
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = this.text.split("@@");
        var cfgTxt = (parts[0] || "").trim();
        var prxTxt = (parts.length > 1 ? parts[1] : "").trim();
        var valid = false;
        try {
          var c = JSON.parse(cfgTxt);
          if (c && c.mode) {
            root.mode = c.mode;
            valid = true;
          }
        } catch (e) {
          valid = false;
        }
        root.engineActive = valid;
        if (!valid)
          root.mode = "?";
        try {
          var p = JSON.parse(prxTxt);
          root.node = p.now || "-";
        } catch (e) {
          root.node = "-";
        }
      }
    }
  }

  Process {
    id: setProc
    running: false
    onExited: root.refresh()
  }

  Timer {
    interval: Math.max(1500, root.refreshInterval)
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
