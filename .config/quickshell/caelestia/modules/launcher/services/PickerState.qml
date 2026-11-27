pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Local stand-in for Caelestia.State's PersistentState (not available in the
// installed caelestia-shell 2.5.0): persists the pickers' recently used items
// in a small JSON file under XDG_STATE_HOME.
Singleton {
    id: root

    readonly property string path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia/picker-recents.json`

    property bool loaded: false
    property list<string> recentEmojis: []
    property list<string> recentKaomoji: []
    property list<string> recentSymbols: []

    onRecentEmojisChanged: save()
    onRecentKaomojiChanged: save()
    onRecentSymbolsChanged: save()

    function save(): void {
        if (!root.loaded)
            return;
        storage.setText(JSON.stringify({
                    recentEmojis: root.recentEmojis,
                    recentKaomoji: root.recentKaomoji,
                    recentSymbols: root.recentSymbols
                }) + "\n");
    }

    FileView {
        id: storage

        path: root.path
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.recentEmojis = Array.isArray(data.recentEmojis) ? data.recentEmojis : [];
                root.recentKaomoji = Array.isArray(data.recentKaomoji) ? data.recentKaomoji : [];
                root.recentSymbols = Array.isArray(data.recentSymbols) ? data.recentSymbols : [];
            } catch (e) {
                console.warn("PickerState: failed to parse recents:", e);
            }
            root.loaded = true;
        }

        onLoadFailed: err => {
            // First run: no recents yet; the file is written on the first
            // "recent" update.
        }
    }
}
