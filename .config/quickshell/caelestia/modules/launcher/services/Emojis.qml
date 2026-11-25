pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services

// Ported from Caelestia PR #1298's services/Emojis.qml. The data file lives
// beside the menu definition (the repo's assets directory is a symlink into
// the installed package), and the recently-used list is a JSON side-file
// because LauncherConfig is compiled into the shell package here.
Singleton {
    id: root

    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia`
    readonly property string dataPath: `${Quickshell.env("HOME")}/.config/caelestia/emoji.json`
    readonly property string recentsPath: `${stateDir}/emoji-recents.json`

    property var emojis: []
    property var categories: [
        {
            id: "all",
            name: "All Emojis",
            icon: "grid_view"
        },
        {
            id: "recent",
            name: "Recently Used",
            icon: "history"
        },
        {
            id: "people",
            name: "Smileys & People",
            icon: "sentiment_satisfied"
        },
        {
            id: "animals",
            name: "Animals & Nature",
            icon: "pets"
        },
        {
            id: "nature",
            name: "Nature",
            icon: "nature"
        },
        {
            id: "food",
            name: "Food & Drink",
            icon: "restaurant"
        },
        {
            id: "activity",
            name: "Activity",
            icon: "sports_soccer"
        },
        {
            id: "travel",
            name: "Travel & Places",
            icon: "flight"
        },
        {
            id: "objects",
            name: "Objects",
            icon: "lightbulb"
        },
        {
            id: "symbols",
            name: "Symbols",
            icon: "tag"
        },
        {
            id: "flags",
            name: "Flags",
            icon: "flag"
        }
    ]
    property var recentEmojis: []

    signal emojisLoaded

    function loadRecentEmojis(): void {
        try {
            const parsed = JSON.parse(recentsFile.text());
            root.recentEmojis = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.recentEmojis = [];
        }
    }

    function saveRecentEmojis(): void {
        recentsFile.setText(JSON.stringify(root.recentEmojis) + "\n");
    }

    function filterByCategory(category: string): var {
        if (category === "all") {
            return root.emojis;
        }
        if (category === "recent") {
            return root.recentEmojis.map(emoji => {
                return root.emojis.find(e => e.emoji === emoji);
            }).filter(e => e !== undefined);
        }
        return root.emojis.filter(e => e.category === category);
    }

    function search(query: string): var {
        if (!query)
            return root.emojis;

        const lowerQuery = query.toLowerCase();
        return root.emojis.filter(emoji => {
            if (emoji.emoji.includes(query))
                return true;
            if (emoji.name.toLowerCase().includes(lowerQuery))
                return true;
            if (emoji.keywords && emoji.keywords.some(k => k.toLowerCase().includes(lowerQuery)))
                return true;
            return false;
        });
    }

    function copyEmoji(emoji: var): void {
        Quickshell.execDetached(["sh", "-c", `echo -n '${emoji.emoji}' | wl-copy`]);

        // Insert into the focused window, as Omarchy's picker does: wait for
        // the launcher to close and focus to return, then shift+Insert pastes
        // the clipboard.
        Quickshell.execDetached(["sh", "-c", "sleep 0.5; ydotool key 42:1 110:1 110:0 42:0"]);

        // Add to recent emojis
        const index = root.recentEmojis.indexOf(emoji.emoji);
        if (index > -1) {
            // quickshell's JS engine has no Array.toSpliced.
            root.recentEmojis = root.recentEmojis.filter((_, i) => i !== index);
        }
        root.recentEmojis = [emoji.emoji, ...root.recentEmojis];
        if (root.recentEmojis.length > 20) {
            root.recentEmojis = root.recentEmojis.slice(0, 20);
        }
        saveRecentEmojis();

        Toaster.toast(Tr.tr("Copied to clipboard"), `${emoji.emoji} ${emoji.name}`, "sentiment_satisfied");
    }

    Component.onCompleted: {
        loadRecentEmojis();
    }

    FileView {
        id: recentsFile

        path: root.recentsPath
        watchChanges: false

        onLoadFailed: {
            // First run: no recents yet, nothing to load.
        }
    }

    FileView {
        id: emojiFile

        path: root.dataPath

        onLoaded: {
            try {
                root.emojis = JSON.parse(text());
                root.emojisLoaded();
            } catch (e) {
                console.error("Failed to parse emoji.json:", e);
            }
        }
    }
}
