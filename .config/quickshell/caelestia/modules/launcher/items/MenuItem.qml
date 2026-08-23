import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    readonly property bool isSeparator: root.modelData?.type === "separator"

    implicitHeight: root.isSeparator ? Math.round(Tokens.sizes.launcher.itemHeight * 0.4) : Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    opacity: root.modelData?.type === "item" && root.modelData?.disabled ? 0.45 : 1

    StateLayer {
        radius: Tokens.rounding.large
        enabled: !root.isSeparator && !(root.modelData?.type === "item" && root.modelData?.disabled)
        onClicked: root.list.enterRow(root.modelData)
    }

    StyledRect {
        visible: root.isSeparator
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 1
        color: Colours.palette.m3outline
        opacity: 0.5
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        // App rows use the real desktop icon; everything else uses NF glyphs.
        IconImage {
            id: appIcon

            visible: root.modelData?.type === "app"
            asynchronous: true
            source: root.modelData?.type === "app" ? Quickshell.iconPath(root.modelData?.entry?.icon ?? root.modelData?.icon, "image-missing") : ""
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: glyph

            visible: root.modelData?.type !== "app"
            text: root.modelData?.icon ?? ""
            color: {
                if (root.modelData?.checked)
                    return Colours.palette.m3primary;
                return Colours.palette.m3onSurfaceVariant;
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(Tokens.sizes.launcher.itemHeight * 0.42)

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: {
                if (root.modelData?.type === "app")
                    return appIcon.right;
                return glyph.right;
            }
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: trailing.visible ? trailing.left : parent.right
            anchors.rightMargin: trailing.visible ? Tokens.spacing.medium : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small

            StyledText {
                id: name

                text: root.modelData?.label ?? ""
                font: Tokens.font.body.medium
                color: root.modelData?.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface

                width: parent.width
                elide: Text.ElideRight
            }

            StyledText {
                id: desc

                text: root.modelData?.desc ?? ""
                visible: text.length > 0
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                width: parent.width
                elide: Text.ElideRight
            }
        }

        // Trailing indicator: check for checked items, chevron for submenus
        Text {
            id: trailing

            visible: root.modelData?.checked || root.modelData?.type === "submenu"
            text: root.modelData?.checked ? "󰄵" : "󰅂"
            color: Colours.palette.m3onSurfaceVariant
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(Tokens.sizes.launcher.itemHeight * 0.3)

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
