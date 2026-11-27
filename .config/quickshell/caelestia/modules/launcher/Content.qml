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
    // Exposed for the drawers layer: Panels reads the clipboard selection
    // through it to drive the preview panel beside the launcher.
    readonly property alias list: list

    // Picker grids walk their own layout (cells and rows); every other
    // list uses the shared mover.
    function move(direction: string): void {
        if (list.showPicker) {
            list.currentList?.move(direction);
            return;
        }
        if (direction === "up")
            moveListSelection(-1);
        else if (direction === "down")
            moveListSelection(1);
    }

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
            l.moveSelection(delta);
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

        // Omarchy's menu keeps the submenu's title in its header; the launcher
        // has no header, so the route rides in the search bar as a pill. The
        // empty query is the menu's root, where the pill hides.
        crumbText: list.showMenu && MenuService.route !== "" ? MenuService.breadcrumb() : ""
        onCrumbClicked: MenuService.back()

        onAccepted: {
            if (list.showPicker) {
                list.currentList?.activate(false);
                return;
            }

            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showMenu) {
                    list.currentList.enterRow(currentItem.modelData);
                } else if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (list.showClipboard) {
                    // Plain Enter pastes into the window below (handled in
                    // Keys.onPressed, which sees the modifiers); reaching
                    // here means Shift+Enter: copy only.
                    Clipboard.copyToClipboard(currentItem.modelData);
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

        Keys.onUpPressed: root.move("up")
        Keys.onDownPressed: root.move("down")

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            // Backspacing out of the native wallpaper/scheme flows returns to
            // the menu at the route it was opened from.
            if (event.key === Qt.Key_Backspace && !event.modifiers) {
                const pfx = GlobalConfig.launcher.actionPrefix;
                if (text === `${pfx}wallpaper ` || text === `${pfx}scheme ` || text === `${pfx}clipboard ` || text === `${pfx}emoji ` || text === `${pfx}kaomoji ` || text === `${pfx}symbol `) {
                    clear();
                    event.accepted = true;
                    return;
                }
            }

            // Omarchy's menu keys: Backspace and Left climb back out of a
            // submenu once the query is empty; at the root Backspace is left
            // alone so it cannot eat the launcher open. Right at the end of
            // the query walks into (or runs) the row under the cursor.
            if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && !event.modifiers && list.showMenu && text === "") {
                if (MenuService.back())
                    event.accepted = true;
                else if (event.key === Qt.Key_Left)
                    root.screenState.launcher = false;
                return;
            }

            if (event.key === Qt.Key_Right && !event.modifiers && list.showMenu && text !== "" && cursorPosition === text.length) {
                const currentItem = list.currentList?.currentItem;
                if (currentItem)
                    list.currentList.enterRow(currentItem.modelData);
                event.accepted = true;
                return;
            }

            // Omacale's clipboard keys, in the PR's launcher: Enter pastes
            // into the window below, Shift+Enter copies, Alt+Enter opens,
            // Delete removes, Shift+Delete asks before wiping, PageUp/Down
            // page through.
            if (list.showClipboard) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    const currentItem = list.currentList?.currentItem;
                    if (currentItem) {
                        if (event.modifiers & Qt.AltModifier)
                            Clipboard.openItem(currentItem.modelData);
                        else if (event.modifiers & Qt.ShiftModifier)
                            Clipboard.copyToClipboard(currentItem.modelData);
                        else
                            Clipboard.pasteIntoWindow(currentItem.modelData);
                        root.screenState.launcher = false;
                    }
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Delete && !event.modifiers) {
                    const currentItem = list.currentList?.currentItem;
                    if (currentItem) {
                        list.currentList.deletedItemIndex = list.currentList.currentIndex;
                        Clipboard.deleteItem(currentItem.modelData);
                    }
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                    list.currentList.showClearConfirmation = true;
                    event.accepted = true;
                    return;
                }
                if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && list.currentList) {
                    const clipList = list.currentList;
                    clipList.currentIndex = Math.max(0, Math.min(clipList.count - 1, clipList.currentIndex + (event.key === Qt.Key_PageDown ? 5 : -5)));
                    event.accepted = true;
                    return;
                }
            }

            // Left/Right walk the picker grid cell by cell (only stolen from
            // the text cursor while a picker is open).
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                if (list.showPicker) {
                    root.move(event.key === Qt.Key_Left ? "left" : "right");
                    event.accepted = true;
                    return;
                }
            }

            // Alt+Enter copies and pastes a picker item; Tab/Shift+Tab switch
            // picker categories. The clipboard Tab block above stays scoped
            // to the clipboard view.
            if (list.showPicker && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.AltModifier)) {
                list.currentList?.activate(true);
                event.accepted = true;
                return;
            }
            if (list.showPicker && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                const back = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier);
                list.currentList?.switchCategory(back ? -1 : 1);
                event.accepted = true;
                return;
            }

            // Tab cycles the category bar in the clipboard view; everywhere
            // else it moves the list selection.
            if (list.showClipboard && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                const delta = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1;
                list.currentList?.cycleTab(delta);
                event.accepted = true;
                return;
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    root.move("down");
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    root.move("up");
                    event.accepted = true;
                } else if (list.showPicker && event.key === Qt.Key_H) {
                    root.move("left");
                    event.accepted = true;
                } else if (list.showPicker && event.key === Qt.Key_L) {
                    root.move("right");
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

        Component.onCompleted: {
            forceActiveFocus();
            // An IPC/keybind asked for a clipboard or emoji view before the
            // content existed.
            if (MenuService.pendingPrefix !== "") {
                search.text = `${GlobalConfig.launcher.actionPrefix}${MenuService.pendingPrefix} `;
                MenuService.pendingPrefix = "";
            }
        }

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

        Connections {
            function onPendingPrefixChanged(): void {
                if (MenuService.pendingPrefix !== "") {
                    search.text = `${GlobalConfig.launcher.actionPrefix}${MenuService.pendingPrefix} `;
                    search.forceActiveFocus();
                    MenuService.pendingPrefix = "";
                }
            }

            target: MenuService
        }
    }
}
