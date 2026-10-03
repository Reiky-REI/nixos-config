import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool engineActive: mainInstance?.engineActive ?? false
  readonly property bool proxyOn: mainInstance?.proxyOn ?? false
  readonly property string mode: mainInstance?.mode ?? "?"
  readonly property string node: mainInstance?.node ?? "-"

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "none"

  readonly property color onColor: iconColorKey === "none" ? Color.mPrimary : Color.resolveColorKey(iconColorKey)
  readonly property color offColor: Qt.alpha(Color.mOnSurfaceVariant, 0.5)
  readonly property color stateColor: !engineActive ? offColor : (proxyOn ? onColor : offColor)

  readonly property real contentWidth: Style.capsuleHeight
  readonly property real contentHeight: Style.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight
  Layout.alignment: Qt.AlignVCenter

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor

    NIcon {
      anchors.centerIn: parent
      icon: root.proxyOn ? "shield-check" : "shield-off"
      color: root.stateColor
      pointSize: Style.fontSizeL
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("menu.panel"),
        "action": "panel",
        "icon": "world"
      },
      {
        "label": root.proxyOn ? pluginApi?.tr("menu.off") : pluginApi?.tr("menu.on"),
        "action": "toggle",
        "icon": "power"
      }
    ]

    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "panel") {
        Quickshell.execDetached(["xdg-open", "http://127.0.0.1:9097/ui/"]);
      } else if (action === "toggle") {
        mainInstance?.toggleMode();
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      } else {
        mainInstance?.toggleMode();
      }
    }

    onEntered: {
      var tip = root.engineActive
        ? (pluginApi?.tr("tooltip.mode") + ": " + root.mode + (root.node !== "-" ? "\n" + pluginApi?.tr("tooltip.node") + ": " + root.node : ""))
        : pluginApi?.tr("tooltip.down");
      TooltipService.show(root, tip, BarService.getTooltipDirection());
    }
    onExited: TooltipService.hide()
  }
}
