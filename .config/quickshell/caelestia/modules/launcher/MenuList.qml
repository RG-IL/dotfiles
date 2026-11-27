pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    function enterRow(row: var): void {
        // A disabled row (software already installed, a half-typed reminder)
        // is listed to be read, not picked: leave the launcher as it is.
        if (row.type === "item" && row.disabled)
            return;
        // Wallpaper & Theme hand off to the native >wallpaper / >scheme flows;
        // Set Reminder opens the interactive >remind input.
        if (row.type === "submenu" && (row.id === "style.background" || row.id === "style.theme")) {
            const prefix = GlobalConfig.launcher.actionPrefix;
            root.search.text = row.id === "style.background" ? `${prefix}wallpaper ` : `${prefix}scheme `;
            return;
        }
        if (row.id === "trigger.reminder.set") {
            root.search.text = "@remind ";
            return;
        }
        // Clipboard & Emoji hand off to the >clipboard / >emoji views.
        if (row.type === "internal" && (row.internal === "clipboard" || row.internal === "emoji")) {
            root.search.text = `${GlobalConfig.launcher.actionPrefix}${row.internal} `;
            return;
        }
        // Entering a section or the keybindings view drops the active search.
        const staysOpen = row.type === "submenu" || (row.type === "internal" && row.internal === "keybindings");
        if (staysOpen)
            root.search.clear();
        MenuService.enter(row);
        // The keybindings view lives inside the launcher; everything else
        // either navigates (submenu) or hands off to an app/overlay.
        if (!staysOpen)
            root.screenState.launcher = false;
    }

    model: ScriptModel {
        id: menuModel

        values: {
            // Reference reactive state so the binding re-evaluates after
            // async loads (tree parse, cond batch, bindings) and navigation.
            const deps = `${MenuService.loaded}|${MenuService.route}|${MenuService.mode}|${Object.keys(MenuService.conds).length}|${MenuService.bindings.length}`;
            return MenuService.rowsFor(root.search.text);
        }
        onValuesChanged: root.settle()
    }

    // Keyboard selection that steps over separator rows and dimmed disabled
    // rows: neither can take the cursor.
    function moveSelection(dir: int): void {
        const vals = menuModel.values ?? [];
        let i = root.currentIndex + dir;
        while (i >= 0 && i < vals.length && !root.pickable(vals[i]))
            i += dir;
        if (i >= 0 && i < vals.length)
            root.currentIndex = i;
    }

    // Omarchy's settleCursor: a view that opens onto a disabled row parks the
    // highlight on the first row that can take it, so the first Enter still
    // does something.
    function settle(): void {
        const vals = menuModel.values ?? [];
        for (let i = 0; i < vals.length; i++) {
            if (root.pickable(vals[i])) {
                root.currentIndex = i;
                return;
            }
        }
    }

    function pickable(row: var): bool {
        return row !== undefined && row !== null && row.type !== "separator" && !(row.type === "item" && row.disabled);
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    delegate: MenuItem {
        list: root
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    Connections {
        function onViewChanged(): void {
            root.currentIndex = 0;
            root.positionViewAtBeginning();
        }

        target: MenuService
    }
}
