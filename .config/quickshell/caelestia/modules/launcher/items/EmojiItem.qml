pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import "../services"
import qs.components
import qs.services

// Ported from Caelestia PR #1298's items/EmojiItem.qml: one grid cell with
// the glyph large and its name under it, hover and current highlight shared.
Item {
    id: root

    required property var modelData
    required property ScreenState screenState

    StyledRect {
        id: rect

        anchors.fill: parent
        radius: Tokens.rounding.medium
        color: {
            if (mouse.containsMouse)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            if (GridView.isCurrentItem)
                return Qt.alpha(Colours.palette.m3onSurface, 0.08);
            return "transparent";
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                Emojis.copyEmoji(root.modelData);
                root.screenState.launcher = false;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall / 2

            // Glyph only, as requested; the name lives in the search.
            StyledText {
                Layout.fillWidth: true
                Layout.fillHeight: true

                text: root.modelData.emoji
                font: Tokens.font.body.builders.large.scale(1.5).build()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
