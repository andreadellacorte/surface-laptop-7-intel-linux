// Face-unlock toast styled exactly like an Omarchy notification card: it imports
// Omarchy's own Commons (Style, Color, Border) and Ui (BorderSurface), so it follows
// the current theme. It is a fresh overlay surface, so it also stacks above the
// polkit dialog (Omarchy's own notification layer sits below it).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

ShellRoot {
  id: root
  readonly property string title: Quickshell.env("FACE_TITLE") || "Face recognised"
  readonly property string body: Quickshell.env("FACE_BODY") || ""
  readonly property string image: Quickshell.env("FACE_IMAGE") || ""
  readonly property bool ok: (Quickshell.env("FACE_OK") || "1") === "1"
  readonly property int ms: parseInt(Quickshell.env("FACE_MS") || "4500")

  PanelWindow {
    id: win
    anchors { top: true; right: true }
    margins { top: Style.gapsOut; right: Style.gapsOut }
    implicitWidth: Style.space(380)
    implicitHeight: card.height
    color: "transparent"
    exclusionMode: ExclusionMode.Normal          // sit below the bar, like the deck
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "surface-faceauth-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
      id: card
      width: parent.width
      height: layout.height + 2 * Style.space(10) + plate.borderTop + plate.borderBottom
      opacity: 0
      Component.onCompleted: opacity = 1
      Behavior on opacity { NumberAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }

      readonly property color bodyColor: Qt.darker(Commons.Color.notifications.text, 1.15)

      BorderSurface {
        id: plate
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Commons.Color.notifications.background
        borderSpec: Border.surfaceSpec("notifications", "border",
                      root.ok ? Commons.Color.notifications.border : Commons.Color.urgent,
                      Math.max(1, Style.space(2)))
      }

      Row {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top
                  leftMargin: plate.contentLeftInset + Style.space(12)
                  rightMargin: plate.contentRightInset + Style.space(12)
                  topMargin: plate.contentTopInset + Style.space(10) }
        spacing: Style.space(12)

        Item {                                   // the IR snapshot, as a "photo" thumb
          id: thumb
          readonly property real slot: Style.space(56)
          width: root.image ? slot : 0
          height: width
          visible: root.image !== ""
          Image {
            id: picture
            anchors.fill: parent
            source: root.image ? "file://" + root.image : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: thumb.slot * Screen.devicePixelRatio
            sourceSize.height: thumb.slot * Screen.devicePixelRatio
            cache: false
            layer.enabled: Style.cornerRadius > 0
            layer.effect: MultiEffect { maskEnabled: true; maskSource: mask }
          }
          Rectangle { id: mask; anchors.fill: parent; visible: false; layer.enabled: true
                      radius: Style.cornerRadius; color: "black" }
        }

        Column {
          width: layout.width - (thumb.visible ? thumb.width + layout.spacing : 0)
          spacing: Style.space(3)
          anchors.verticalCenter: thumb.visible ? thumb.verticalCenter : undefined
          Text {
            width: parent.width
            text: root.title
            color: root.ok ? Commons.Color.notifications.text : Commons.Color.urgent
            font.family: "Liberation Sans"
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            visible: root.body !== ""
            text: root.body
            color: card.bodyColor
            font.family: "Liberation Sans"
            font.pixelSize: Style.font.title
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  Timer { interval: root.ms; running: true; onTriggered: card.opacity = 0 }
  Timer { interval: root.ms + Style.duration(150) + 50; running: true; onTriggered: Qt.quit() }
}
