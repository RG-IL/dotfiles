pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import "items"
import "services"
import qs.components
import qs.components.controls
import qs.services

// Ported from Caelestia PR #1298's EmojiList.qml: a category bar over a grid
// of glyph cells, with grid-aware keyboard navigation. Left/Right at the
// search field's edges hand back to the caller for the last/first cell.
Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    property string activeCategory: "all"

    readonly property int columns: 8
    readonly property int cellSize: Math.floor((Tokens.sizes.launcher.itemWidth - Tokens.padding.medium * 2) / columns)
    readonly property alias currentItem: grid.currentItem
    readonly property alias count: grid.count
    property int currentIndex: 0

    function incrementCurrentIndex(): void {
        const newIndex = currentIndex + columns;
        if (newIndex < grid.count) {
            currentIndex = newIndex;
        } else if (currentIndex < grid.count - 1) {
            currentIndex = grid.count - 1;
        }
    }

    function decrementCurrentIndex(): void {
        const newIndex = currentIndex - columns;
        if (newIndex >= 0) {
            currentIndex = newIndex;
        } else if (currentIndex > 0) {
            currentIndex = 0;
        }
    }

    function moveLeft(): void {
        if (currentIndex > 0) {
            currentIndex = currentIndex - 1;
        }
    }

    function moveRight(): void {
        if (currentIndex < grid.count - 1) {
            currentIndex = currentIndex + 1;
        }
    }

    function updateGrid(): void {
        const pattern = new RegExp("^" + GlobalConfig.launcher.actionPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + "emoji\\s*", "i");
        const query = root.search.text.replace(pattern, "").trim();
        // The service maps the Recent tab through the recents list; the rest
        // filter on the entry's category.
        let emojis = Emojis.filterByCategory(root.activeCategory);
        if (query) {
            const lowerQuery = query.toLowerCase();
            emojis = emojis.filter(emoji => emoji.name.toLowerCase().includes(lowerQuery) || emoji.keywords.some(kw => kw.toLowerCase().includes(lowerQuery)));
        }
        grid.model = emojis;
        currentIndex = 0;
    }

    // Tab / Shift+Tab move through the category bar.
    function cycleTab(delta: int): void {
        const cats = Emojis.categories;
        const i = cats.findIndex(c => c.id === root.activeCategory);
        root.activeCategory = cats[(i + delta + cats.length) % cats.length].id;
        root.updateGrid();
    }

    implicitWidth: Tokens.sizes.launcher.itemWidth
    implicitHeight: categoryBar.height + grid.height + Tokens.padding.large

    onCurrentIndexChanged: {
        if (grid.currentIndex !== currentIndex) {
            grid.currentIndex = currentIndex;
        }
    }

    Component.onCompleted: {
        updateGrid();
    }

    RowLayout {
        id: categoryBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.small

        Repeater {
            model: Emojis.categories

            IconButton {
                required property var modelData
                required property int index

                icon: modelData.icon
                type: root.activeCategory === modelData.id ? IconButton.Filled : IconButton.Tonal
                onClicked: {
                    root.activeCategory = modelData.id;
                    root.updateGrid();
                }
            }
        }
    }

    GridView {
        id: grid

        anchors.top: categoryBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.topMargin: Tokens.padding.large

        height: Math.min(Math.max(contentHeight, root.cellSize * 3), 400)
        clip: true

        cellWidth: root.cellSize
        cellHeight: root.cellSize

        verticalLayoutDirection: GridView.TopToBottom

        highlight: Rectangle {
            color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
            radius: Tokens.rounding.medium
        }
        highlightFollowsCurrentItem: true

        model: ScriptModel {
            id: model

            onValuesChanged: {
                grid.currentIndex = 0;
                root.currentIndex = 0;
            }
        }

        delegate: emojiItem

        Keys.onLeftPressed: function(event) {
            if (currentIndex % root.columns === 0) {
                event.accepted = false;
            } else {
                root.moveLeft();
            }
        }

        Keys.onRightPressed: function(event) {
            if (currentIndex % root.columns === root.columns - 1) {
                event.accepted = false;
            } else {
                root.moveRight();
            }
        }

        Keys.onUpPressed: function(event) {
            if (currentIndex < root.columns) {
                event.accepted = false;
            } else {
                currentIndex -= root.columns;
            }
        }

        Keys.onDownPressed: function(event) {
            if (currentIndex >= count - root.columns) {
                event.accepted = false;
            } else {
                currentIndex += root.columns;
            }
        }

        Component {
            id: emojiItem

            EmojiItem {
                width: grid.cellWidth - Tokens.spacing.small
                height: grid.cellHeight - Tokens.spacing.small
                screenState: root.screenState
            }
        }
    }

    Connections {
        function onEmojisLoaded(): void {
            root.updateGrid();
        }

        target: Emojis
    }

    Connections {
        function onTextChanged(): void {
            root.updateGrid();
        }

        target: root.search
    }
}
