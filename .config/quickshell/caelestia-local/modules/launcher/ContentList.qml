pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services
import qs.utils

Item {
    id: root

    required property var content
    required property ScreenState screenState
    required property var panels
    required property real maxHeight
    required property SearchBar search
    required property int padding
    required property int rounding

    readonly property bool showWallpapers: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}wallpaper `)
    readonly property bool showClipboard: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `)
    readonly property var picker: Pickers.forText(search.text) // The open picker (i.e. emoji), if any
    readonly property bool showPicker: picker !== null
    readonly property bool showMenu: !search.text.startsWith(GlobalConfig.launcher.actionPrefix)
    readonly property string hintText: showMenu ? qsTr("Search menu…") : qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)
    readonly property var currentList: showMenu ? menuList.item : showWallpapers ? wallpaperList.item : showClipboard ? clipboardList.item : showPicker ? pickerList.item : appList.item // Can be either ListView or GridView, so can't type properly
    property string animState: showMenu ? "menu" : showWallpapers ? "wallpapers" : showClipboard ? "clipboard" : showPicker ? "picker" : "apps"

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom

    clip: true
    state: animState

    states: [
        State {
            name: "menu"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, menuList.implicitHeight > 0 ? menuList.implicitHeight : empty.implicitHeight)
                menuList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "apps"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, appList.implicitHeight > 0 ? appList.implicitHeight : empty.implicitHeight)
                appList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "wallpapers"

            PropertyChanges {
                root.implicitWidth: Math.max(root.Tokens.sizes.launcher.itemWidth * 1.2, wallpaperList.implicitWidth)
                root.implicitHeight: root.Tokens.sizes.launcher.wallpaperHeight
                wallpaperList.active: true
            }
        },
        State {
            name: "clipboard"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, clipboardList.implicitHeight > 0 ? clipboardList.implicitHeight : empty.implicitHeight)
                clipboardList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        },
        State {
            name: "picker"

            PropertyChanges {
                root.implicitWidth: root.Tokens.sizes.launcher.itemWidth
                root.implicitHeight: Math.min(root.maxHeight, pickerList.implicitHeight > 0 ? pickerList.implicitHeight : empty.implicitHeight)
                pickerList.active: true
            }

            AnchorChanges {
                anchors.left: root.parent.left
                anchors.right: root.parent.right
            }
        }
    ]

    Behavior on animState {
        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                from: 1
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                from: 0
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: menuList

        active: false

        anchors.fill: parent

        sourceComponent: MenuList {
            objectName: "launcherMenuList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: appList

        active: false

        anchors.fill: parent

        sourceComponent: AppList {
            objectName: "launcherAppList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: wallpaperList

        asynchronous: true
        active: false

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: WallpaperList {
            objectName: "launcherWallpaperList"

            search: root.search
            screenState: root.screenState
            panels: root.panels
            content: root.content
        }
    }

    Loader {
        id: clipboardList

        active: false

        anchors.fill: parent

        sourceComponent: ClipboardList {
            objectName: "launcherClipboardList"

            search: root.search
            screenState: root.screenState
        }
    }

    Loader {
        id: pickerList

        active: false

        anchors.fill: parent

        sourceComponent: PickerList {
            objectName: "launcherPickerList"

            search: root.search
            screenState: root.screenState
            source: root.picker ?? root.lastPicker
        }
    }

    // Kept so the picker doesn't lose its source while fading out
    property var lastPicker

    onPickerChanged: {
        if (picker)
            lastPicker = picker;
    }

    Row {
        id: empty

        readonly property string emptyIcon: root.state === "wallpapers" ? "wallpaper_slideshow" : root.state === "menu" && MenuService.error !== "" ? "error" : root.state === "menu" ? "menu_open" : root.state === "clipboard" ? "content_paste" : root.state === "emoji" ? "sentiment_satisfied" : "manage_search"
        readonly property string emptyTitle: root.state === "wallpapers" ? qsTr("No wallpapers found") : root.state === "menu" && MenuService.error !== "" ? qsTr("The menu definition is broken") : root.state === "menu" ? qsTr("No matching entries") : root.state === "clipboard" ? qsTr("No clipboard history") : root.state === "emoji" ? qsTr("No emojis found") : qsTr("No results")
        readonly property string emptySubtitle: root.state === "menu" && MenuService.error !== "" ? MenuService.error : root.state === "wallpapers" && Wallpapers.list.length === 0 ? qsTr("Try putting some wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : root.state === "clipboard" ? qsTr("Copy something to populate clipboard history") : root.state === "emoji" ? qsTr("Try searching for an emoji") : qsTr("Try searching for something else")

        // The clipboard list draws its own empty state; everything else uses
        // this one.
        visible: opacity > 0 && root.state !== "clipboard"
        opacity: root.currentList?.count === 0 ? 1 : 0
        scale: root.currentList?.count === 0 ? 1 : 0.5

        spacing: Tokens.spacing.medium
        padding: Tokens.padding.large

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        MaterialIcon {
            text: empty.emptyIcon
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: empty.emptyTitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: empty.emptySubtitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on scale {
            Anim {}
        }
    }

    Behavior on implicitWidth {
        enabled: root.screenState.launcher

        Anim {}
    }

    Behavior on implicitHeight {
        enabled: root.screenState.launcher

        Anim {}
    }
}
