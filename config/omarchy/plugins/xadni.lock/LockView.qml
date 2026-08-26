import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: "ENTER PASSWORD"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 62
  readonly property int outlineThickness: 2
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  readonly property real uiScale: Math.max(0.72, Math.min(1.12, Math.min(width / 1920, height / 1080)))
  readonly property int brandFontSize: Math.max(8, Math.round(11 * uiScale))
  readonly property color shadeColor: "#07110e"
  readonly property color surfaceColor: "#0c1512"
  readonly property color brandColor: "#d6d5bc"
  readonly property color accentColor: "#8cd3cb"
  readonly property color mutedColor: "#81b8a8"
  readonly property string brandText: [
    " ▄███████   ▄███████   ▄███████   ▄█   █▄       ▄█        ▄███▄   ▄███████   ▄█   █▄",
    "███   ███  ███   ███  ███   ███  ███   ███     ███         ███   ███   ███  ███   ███",
    "███   ███  ███   ███  ███   █▀   ███   ███     ███         ███   ███   █▀   ███   ███",
    "███▄▄▄███  ███▄▄▄██▀  ███        ███▄▄▄███     ███         ███   ███        ███▄▄▄███",
    "███▀▀▀███  ███▀▀▀▀    ███        ███▀▀▀███     ███         ███   ███        ███▀▀▀███",
    "███   ███  █████████  ███   █▄   ███   ███     ███         ███   ███   █▄   ███   ███",
    "███   ███  ███   ███  ███   ███  ███   ███     ███   █▄    ███   ███   ███  ███   ███",
    "███   █▀   ███   ███  ███████▀   ███   █▀      ███████▀   ▀███▀  ███████▀   ███   █▀",
    "           ███   █▀"
  ].join("\n")
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 0.72
      blurMax: 96
      blurMultiplier: 1.15
      contrast: -0.06
    }

    Rectangle {
      anchors.fill: parent
      color: root.shadeColor
      opacity: 0.46
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    Text {
      id: brandMark
      width: Math.min(root.width - 64, implicitWidth)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: brandRule.top
      anchors.bottomMargin: Math.round(18 * root.uiScale)
      text: root.brandText
      color: root.brandColor
      opacity: 0.94
      font.family: Style.font.family
      font.pixelSize: root.brandFontSize
      horizontalAlignment: Text.AlignHCenter
      renderType: Text.NativeRendering
      wrapMode: Text.NoWrap
    }

    Rectangle {
      id: brandRule
      width: Math.round(72 * root.uiScale)
      height: Math.max(1, Math.round(root.uiScale))
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: inputField.top
      anchors.bottomMargin: Math.round(32 * root.uiScale)
      color: root.accentColor
      opacity: 0.72
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: inputField.bottom
      anchors.topMargin: Math.round(18 * root.uiScale)
      text: root.fingerprintConfigured ? "PASSWORD  ·  FINGERPRINT READY" : "PASSWORD  ·  ENTER TO UNLOCK"
      color: root.mutedColor
      opacity: 0.76
      font.family: Style.font.family
      font.pixelSize: Math.max(9, Math.round(Style.font.caption * root.uiScale))
      font.letterSpacing: Math.round(1.4 * root.uiScale)
      horizontalAlignment: Text.AlignHCenter
    }

    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.centerIn: parent
      color: root.surfaceColor
      borderSpec: root.inputBorderSpec
      radius: Style.cornerRadius
      clip: true

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: root.brandColor
        selectionColor: Color.lock.selection
        selectedTextColor: root.brandColor
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: root.accentColor
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? root.brandColor : (root.failureMessage.length > 0 ? Color.lock.textError : root.mutedColor)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: root.accentColor
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }
}
