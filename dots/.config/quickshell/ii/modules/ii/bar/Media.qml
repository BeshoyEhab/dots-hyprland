import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    property bool hovered: false

    Layout.fillHeight: true
    implicitWidth: mediaRowLayout.x < 0 ? 0 : mediaRowLayout.implicitWidth + mediaRowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight
    clip: true

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    Timer {
        id: closePopupTimer
        interval: 300
        onTriggered: {
            if (!root.hovered && !mediaControlsHovered) {
                GlobalStates.mediaControlsOpen = false
            }
        }
    }

    property bool mediaControlsHovered: false

    MouseArea {
        id: hoverMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            }
        }
        onEntered: {
            root.hovered = true
            closePopupTimer.stop()
            if (Config.options.bar.media.hoverToShow && activePlayer?.trackTitle != null) {
                GlobalStates.mediaControlsOpen = true
            }
        }
        onExited: {
            root.hovered = false
            if (Config.options.bar.media.hoverToShow) {
                closePopupTimer.restart()
            }
        }
    }

    RowLayout { // Real content
        id: mediaRowLayout
        x: (Config.options.bar.media.hoverToShow && !hovered && activePlayer?.trackTitle != null) ? -width : 0
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: mediaRowLayout.spacing
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Appearance.colors.colOnLayer1
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }
    }
}
