import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property bool surfaceVisible: false
  property real lineProgress: 0

  readonly property int entranceDuration: 480
  readonly property int holdDuration: 3000
  readonly property int exitDuration: 420

  function showWelcome() {
    holdTimer.stop()
    entranceAnimation.stop()
    exitAnimation.stop()

    surfaceVisible = true
    card.opacity = 0
    card.scale = 0.94
    lift.y = Style.space(14)
    lineProgress = 0

    Qt.callLater(function() {
      if (root.surfaceVisible) entranceAnimation.restart()
    })
  }

  function hideWelcome() {
    if (!surfaceVisible) return
    holdTimer.stop()
    entranceAnimation.stop()
    exitAnimation.restart()
  }

  IpcHandler {
    target: "welcome"

    function show(): string {
      root.showWelcome()
      return "ok"
    }

    function close(): string {
      root.hideWelcome()
      return "ok"
    }

    function ping(): string {
      return "ok"
    }

    function state(): string {
      return root.surfaceVisible ? "open" : "closed"
    }
  }

  Timer {
    id: holdTimer
    interval: root.holdDuration
    repeat: false
    onTriggered: root.hideWelcome()
  }

  ParallelAnimation {
    id: entranceAnimation

    NumberAnimation {
      target: card
      property: "opacity"
      to: 1
      duration: root.entranceDuration
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: card
      property: "scale"
      to: 1
      duration: root.entranceDuration
      easing.type: Easing.OutBack
      easing.overshoot: 0.8
    }
    NumberAnimation {
      target: lift
      property: "y"
      to: 0
      duration: root.entranceDuration
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "lineProgress"
      to: 1
      duration: root.entranceDuration
      easing.type: Easing.OutCubic
    }

    onFinished: holdTimer.restart()
  }

  ParallelAnimation {
    id: exitAnimation

    NumberAnimation {
      target: card
      property: "opacity"
      to: 0
      duration: root.exitDuration
      easing.type: Easing.InCubic
    }
    NumberAnimation {
      target: card
      property: "scale"
      to: 0.94
      duration: root.exitDuration
      easing.type: Easing.InCubic
    }
    NumberAnimation {
      target: lift
      property: "y"
      to: Style.space(14)
      duration: root.exitDuration
      easing.type: Easing.InCubic
    }
    NumberAnimation {
      target: root
      property: "lineProgress"
      to: 0
      duration: root.exitDuration
      easing.type: Easing.InCubic
    }

    onFinished: root.surfaceVisible = false
  }

  PanelWindow {
    id: panel

    visible: root.surfaceVisible
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "xadni-welcome"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    BorderSurface {
      id: card

      width: Math.max(Style.space(370), message.implicitWidth + Style.space(72))
      height: Style.space(90)
      anchors.centerIn: parent
      transformOrigin: Item.Center
      transform: Translate { id: lift }
      color: Util.alpha(Color.background, 0.94)
      borderSpec: Border.surfaceSpec("popups", "border", Color.accent, Math.max(1, Style.space(1)))
      radius: Style.cornerRadius
      layer.enabled: root.surfaceVisible
      layer.smooth: true

      Text {
        id: message

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Style.space(5)
        text: "Welcome back, Commander."
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.weight: Font.Medium
        font.letterSpacing: Style.space(0.45)
        renderType: Text.NativeRendering
      }

      Rectangle {
        width: Math.round(Style.space(52) * root.lineProgress)
        height: Math.max(1, Style.space(1))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: message.bottom
        anchors.topMargin: Style.space(12)
        color: Color.accent
        opacity: 0.82
      }
    }
  }
}
