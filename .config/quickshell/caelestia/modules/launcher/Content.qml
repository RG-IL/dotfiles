pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin

    // MenuList has a custom move(); stock lists (apps, wallpapers) only
    // understand the standard index changers.
    function moveListSelection(delta: int): void {
        const l = list.currentList;
        if (!l)
            return;
        // Only MenuList has the custom mover; everything else uses the
        // standard index changers.
        if (l.objectName === "launcherMenuList")
            l.move(delta);
        else if (delta < 0)
            l.decrementCurrentIndex();
        else
            l.incrementCurrentIndex();
    }

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: list.hintText

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showMenu) {
                    list.currentList.enterRow(currentItem.modelData);
                } else if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: root.moveListSelection(-1)
        Keys.onDownPressed: root.moveListSelection(1)

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            // Backspacing out of the native wallpaper/scheme flows returns to
            // the menu at the route it was opened from.
            if (event.key === Qt.Key_Backspace && !event.modifiers) {
                const pfx = GlobalConfig.launcher.actionPrefix;
                if (text === `${pfx}wallpaper ` || text === `${pfx}scheme `) {
                    clear();
                    event.accepted = true;
                    return;
                }
            }

            if (event.key === Qt.Key_Backspace && !event.modifiers && list.showMenu && text === "") {
                if (MenuService.back())
                    event.accepted = true;
                else
                    root.screenState.launcher = false;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    root.moveListSelection(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    root.moveListSelection(-1);
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                root.moveListSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                root.moveListSelection(-1);
                event.accepted = true;
            }
        }

        Component.onCompleted: forceActiveFocus()

            Connections {
                function onLauncherChanged(): void {
                    if (!root.screenState.launcher) {
                        MenuService.scheduleRootReset();
                    } else {
                        // Reopened before the deferred reset fired: flush the
                        // stale state now so every open starts at the root.
                        MenuService.flushRootReset();
                        // Conditions may have changed while closed (toggles
                        // from the panel or keybinds); refresh checkmarks.
                        MenuService.evalConds();
                    }
                }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
