pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

Singleton {
    id: root

    readonly property string menuDir: `${Quickshell.env("HOME")}/.config/caelestia/menu`
    readonly property string binDir: `${menuDir}/bin`

    property var tree: null
    property bool loaded: false

    // Current navigation state
    property string route: ""
    property string mode: "menu" // "menu" | "keybindings"

    // Condition string -> bool
    property var conds: ({})

    // Keybinding rows for the searchable keybindings view
    property var bindings: []
    property var emojis: []

    signal viewChanged

    // Deferred return-to-root after the launcher closes. Lives here because
    // the launcher UI unloads on hide, killing timers parented inside it.
    property Timer _rootResetTimer: Timer {
        interval: 500
        onTriggered: root.doRootReset()
    }

    // Re-runs when/checked/disabled conditions shortly after an action fires,
    // so toggles flip their own checkmark without closing the launcher.
    property Timer _condRefreshTimer: Timer {
        interval: 300
        onTriggered: root.evalConds()
    }

    function scheduleCondRefresh(): void {
        _condRefreshTimer.restart();
    }

    function scheduleRootReset(): void {
        _rootResetTimer.restart();
    }

    function flushRootReset(): void {
        if (_rootResetTimer.running) {
            _rootResetTimer.stop();
            doRootReset();
        }
    }

    function doRootReset(): void {
        root.route = "";
        root.mode = "menu";
        root.viewChanged();
    }
    signal overlayRequested(string name)

    function parseJsonc(text: string): var {
        const stripped = text.replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "").replace(/,(\s*[}\]])/g, "$1");
        return JSON.parse(stripped);
    }

    function rootChildren(): var {
        if (!root.tree)
            return [];
        return Object.entries(root.tree).map(([id, n]) => Object.assign({
                    id
                }, n));
    }

    function nodeAt(path: string): var {
        const fid = path.split("/").join(".");
        return {
            children: root.childrenOf(fid),
            self: fid === "" || !root.tree[fid] ? null : Object.assign({
                    id: fid
                }, root.tree[fid])
        };
    }

    function childrenOf(id): var {
        if (id === "")
            return root.rootChildren().filter(n => !n.id.includes("."));
        const prefix = `${id}.`;
        return root.rootChildren().filter(n => n.id.startsWith(prefix) && !n.id.slice(prefix.length).includes("."));
    }

    function condPasses(cond): bool {
        return !cond || root.conds[cond] === true;
    }

    function isChecked(node: var): bool {
        return !!node.checked && root.conds[node.checked] === true;
    }

    function isDisabled(node: var): bool {
        return !!node.disabled && root.conds[node.disabled] === true;
    }

    function breadcrumb(): string {
        if (root.route === "")
            return "";
        const parts = [];
        const segs = root.route.split(".");
        for (let i = 0; i < segs.length; i++) {
            const fid = segs.slice(0, i + 1).join(".");
            const n = root.tree[fid];
            if (!n)
                break;
            parts.push(n.label ?? fid);
        }
        return parts.join(" › ");
    }

    // Expand a node into displayable row(s); null when hidden by conditions.
    // Providers render as submenu rows unless expandProvider is set (routed-to or deep search).
    function rowsForNode(node: var, query: string, expandProvider = false): var {
        if (!root.condPasses(node.when))
            return [];

        const q = query.trim().toLowerCase();

        if (node.provider && !expandProvider && q === "") {
            const label = node.label ?? "";
            const hay = `${label} ${node.alias ?? ""} ${node.desc ?? ""}`.toLowerCase();
            if (!(q === "" || hay.includes(q) || q.split("").every(ch => hay.includes(ch))))
                return [];
            return [{
                        type: "submenu",
                        label: label,
                        desc: node.desc ?? "",
                        icon: node.icon ?? "",
                        id: node.id
                    }];
        }

        if (node.provider) {
            switch (node.provider) {
            case "apps": {
                const apps = Apps.search(q).slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
                return apps.map(e => ({
                            type: "app",
                            entry: e,
                            icon: e.icon,
                            label: e.name ?? "",
                            desc: e.comment ?? e.genericName ?? ""
                        }));
            }
            case "schemes": {
                Schemes.reload();
                const schemes = Schemes.query(q).slice().sort((a, b) => String(a.name + a.flavour).localeCompare(String(b.name + b.flavour)));
                return schemes.map(s => ({
                            type: "scheme",
                            label: s.flavour,
                            desc: s.name,
                            schemeName: s.name,
                            flavour: s.flavour
                        }));
            }
            case "wallpapers": {
                return Wallpapers.list.filter(w => q === "" || w.name.toLowerCase().includes(q)).map(w => ({
                            type: "wallpaper",
                            label: w.name,
                            path: w.path
                        }));
            }
            }
            return [];
        }

        const hay = `${node.label ?? ""} ${node.alias ?? ""} ${node.desc ?? ""}`.toLowerCase();
        const matched = q === "" || hay.includes(q) || q.split("").every(ch => hay.includes(ch));

        if (node.internal) {
            if (!matched)
                return [];
            return [{
                        type: "internal",
                        label: node.label ?? "",
                        desc: node.desc ?? "",
                        icon: node.icon ?? "",
                        internal: node.internal
                    }];
        }

        const kids = root.childrenOf(node.id);

        if (kids.length > 0) {
            const childRows = [];
            let hasChildren = false;
            for (const c of kids) {
                const sub = root.rowsForNodeDeep(c, q);
                childRows.push(...sub.rows);
                if (sub.matched)
                    hasChildren = true;
            }

            if (!matched && !hasChildren)
                return [];
            if (q === "")
                return [{
                            type: "submenu",
                            label: node.label ?? "",
                            desc: node.desc ?? "",
                            icon: node.icon ?? "",
                            id: node.id
                        }];
            return childRows;
        }

        if (!matched)
            return [];

        return [{
                    type: "item",
                    label: node.label ?? "",
                    desc: node.desc ?? "",
                    icon: node.icon ?? "",
                    action: node.action ?? "",
                    checked: root.isChecked(node),
                    toggle: !!node.toggle,
                    disabled: root.isDisabled(node),
                    id: node.id
                }];
    }

    // Like rowsForNode but never emits a parent row itself, only descendants.
    function rowsForNodeDeep(node: var, query: string): var {
        const self = root.rowsForNode(node, query, true);
        const kids = root.childrenOf(node.id);
        const isContainer = kids.length > 0 && query.trim() !== "";
        if (!isContainer)
            return {
                rows: self,
                matched: self.length > 0
            };

        const rows = [];
        let any = false;
        for (const c of kids) {
            const sub = root.rowsForNodeDeep(c, query);
            rows.push(...sub.rows);
            if (sub.matched)
                any = true;
        }
        return {
            rows,
            matched: any
        };
    }

    function leafToken(id: string): string {
        return (String(id).split(".").pop() ?? "").replace(/[._-]+/g, " ");
    }

    function nameText(node: var): string {
        return [node.label ?? "", leafToken(node.id), (node.aliases ?? []).join(" ")].join(" ").toLowerCase();
    }

    function baseScore(node: var, needle: string): real {
        const label = (node.label ?? "").toLowerCase();
        if (label === needle)
            return String(node.id).split(".").length > 1 ? 0 : 2;
        if (label.startsWith(needle))
            return 10;
        if (label.includes(needle))
            return 30;
        if (root.nameText(node).includes(needle))
            return 40;
        return 60;
    }

    function parentPathFor(id: string): string {
        const segs = String(id).split(".");
        if (segs.length < 2)
            return "";
        const parts = [];
        for (let i = 0; i < segs.length - 1; i++) {
            const fid = segs.slice(0, i + 1).join(".");
            const n = root.tree[fid];
            if (!n)
                break;
            parts.push(n.label ?? segs[i]);
        }
        return parts.join(" › ");
    }

    function rowsFor(query: string): var {
        if (root.mode === "keybindings") {
            const q = query.trim().toLowerCase();
            return root.bindings.filter(b => q === "" || b.display.toLowerCase().includes(q)).map(b => ({
                        type: "binding",
                        label: b.display,
                        icon: "󰌌",
                        dispatcher: b.dispatcher,
                        arg: b.arg
                    }));
        }

        if (root.mode === "emoji") {
            const q = query.trim().toLowerCase();
            return root.emojis.filter(e => q === "" || e.name.toLowerCase().includes(q)).slice(0, 200).map(e => ({
                        type: "emoji",
                        label: e.name,
                        icon: e.char,
                        char: e.char
                    }));
        }

        const needle = query.trim().toLowerCase();

        // Navigation: current level in natural menu order.
        if (needle === "") {
            const node = root.nodeAt(root.route);
            if (node?.self?.provider && !(node.children?.length))
                return root.rowsForNode(node.self, "", true);
            const rows = [];
            for (const c of (node?.children ?? []))
                rows.push(...root.rowsForNode(c, ""));
            return rows;
        }

        // Interactive reminder composer: "@remind <minutes> [message]" renders
        // as a normal row so Enter runs it through the regular action path.
        const rm = query.trim().match(/^@remind(?:\s+(\d+))?(?:\s+(.+))?$/);
        if (rm) {
            const minutes = rm[1];
            const msg = (rm[2] ?? "").replace(/["`$\\]/g, "").trim();
            const base = {
                type: "item",
                icon: "󰢌",
                checked: false,
                disabled: false,
                id: "trigger.reminder.compose"
            };
            if (!minutes)
                return [Object.assign({}, base, {
                            label: "Set a reminder",
                            desc: "Keep typing: @remind <minutes> <message>",
                            disabled: true
                        })];
            if (parseInt(minutes) === 0)
                return [Object.assign({}, base, {
                            label: "Minutes must be above zero",
                            desc: "@remind <minutes> <message>",
                            disabled: true
                        })];
            return [Object.assign({}, base, {
                        label: msg !== "" ? `${msg} — in ${minutes} min` : `${minutes} minute reminder`,
                        desc: "Enter to set",
                        action: `menu-reminder ${minutes}${msg !== "" ? ` ${msg}` : ""}`
                    })];
        }

        // Omarchy-style ranked search, scoped to the current subtree.
        const terms = needle.split(/\s+/).filter(t => t !== "");
        const fid = root.route.split("/").join(".");
        const results = [];
        let order = 0;

        function isDirect(id: string): bool {
            if (fid === "")
                return !id.includes(".");
            return id.startsWith(`${fid}.`) && !id.slice(fid.length + 1).includes(".");
        }

        function visit(n: var): void {
            if (!root.condPasses(n.when))
                return;
            const nt = root.nameText(n);
            const descWords = (n.desc ?? "").toLowerCase().split(/\s+/).filter(w => w !== "");
            if (!terms.every(t => nt.includes(t) || descWords.includes(t)))
                return;
            const isSection = !!n.provider || !!n.internal || root.childrenOf(n.id).length > 0;
            const s = root.baseScore(n, needle) + (isSection ? -2 : 0);
            const depth = String(n.id).split(".").length - 1;
            const path = root.parentPathFor(n.id);
            let row;
            if (n.internal) {
                row = {
                    type: "internal",
                    label: n.label ?? "",
                    desc: path,
                    icon: n.icon ?? "",
                    internal: n.internal,
                    id: n.id
                };
            } else if (isSection) {
                row = {
                    type: "submenu",
                    label: n.label ?? "",
                    desc: path,
                    icon: n.icon ?? "",
                    id: n.id
                };
            } else {
                row = {
                    type: "item",
                    label: n.label ?? "",
                    desc: path,
                    icon: n.icon ?? "",
                    action: n.action ?? "",
                    checked: root.isChecked(n),
                    toggle: !!n.toggle,
                    disabled: root.isDisabled(n),
                    id: n.id
                };
            }
            results.push({
                row,
                direct: isDirect(n.id),
                key: s * 1000 + depth * 25 + order
            });
            order += 1;
        }

        function walk(id: string): void {
            for (const n of root.childrenOf(id)) {
                visit(n);
                walk(n.id);
            }
        }
        walk(fid);

        // Installed applications only join the pool from the root level.
        const appsNode = fid === "" ? root.tree["apps"] : null;
        if (appsNode?.provider === "apps" && root.condPasses(appsNode.when)) {
            let i = 0;
            for (const e of Apps.search(needle)) {
                const label = String(e.name ?? "").toLowerCase();
                let s = 80;
                if (label === needle || label.split(/\s+/).includes(needle))
                    s = 0;
                else if (label.startsWith(needle))
                    s = 10;
                else if (label.includes(needle))
                    s = 30;
                else
                    continue;
                results.push({
                    row: {
                        type: "app",
                        entry: e,
                        icon: e.icon,
                        label: e.name ?? "",
                        desc: e.comment ?? e.genericName ?? ""
                    },
                    direct: false,
                    key: (s - 5) * 1000 + 900 * 25 + i
                });
                i += 1;
            }
        }

        results.sort((a, b) => a.key - b.key);
        const here = results.filter(r => r.direct);
        const deeper = results.filter(r => !r.direct);
        const rowsHere = here.map(r => r.row);
        const rowsDeeper = deeper.map(r => r.row);
        if (rowsHere.length > 0 && rowsDeeper.length > 0)
            return [...rowsHere, {
                        type: "separator"
                    }, ...rowsDeeper];
        return rowsHere.concat(rowsDeeper);
    }

    function openRoute(path: string): void {
        root.route = path.split("/").join(".");
        root.mode = "menu";
        root.viewChanged();
    }

    // Returns true when something was popped, false when already at root
    function back(): bool {
        if (root.mode === "keybindings" || root.mode === "emoji") {
            root.mode = "menu";
        } else if (root.route !== "") {
            const idx = root.route.lastIndexOf(".");
            root.route = idx > 0 ? root.route.slice(0, idx) : "";
        } else {
            return false;
        }
        root.viewChanged();
        return true;
    }

    function enter(row: var): void {
        console.log("enter:", row?.type, row?.id ?? row?.label ?? row?.internal);
        switch (row?.type) {
        case "submenu":
            root.route = row.id;
            root.viewChanged();
            break;
        case "internal":
            root.runInternal(row.internal);
            break;
        case "item":
            if (!row.disabled) {
                root.runAction(row.action);
                root.scheduleCondRefresh();
            }
            break;
        case "app":
            Apps.launch(row.entry);
            break;
        case "scheme":
            Quickshell.execDetached(["caelestia", "scheme", "set", "-n", row.schemeName, "-f", row.flavour]);
            break;
        case "wallpaper":
            Quickshell.execDetached(["caelestia", "wallpaper", "--file", row.path]);
            break;
        case "binding":
            root.dispatchBinding(row);
            break;
        case "emoji":
            Quickshell.execDetached(["bash", "-c", `printf '%s' '${row.char}' | wl-copy`]);
            break;
        }
    }

    function runAction(action: string): void {
        if (!action)
            return;
        Quickshell.execDetached(["bash", "-c", `export PATH="${root.binDir}:$PATH"; ${action}`]);
    }

    function runInternal(name: string): void {
        switch (name) {
        case "keybindings":
            root.mode = "keybindings";
            root.loadBindings();
            root.viewChanged();
            break;
        case "emoji":
            root.mode = "emoji";
            root.loadEmojis();
            root.viewChanged();
            break;
        case "speedtest-network":
            root.overlayRequested("speedtest");
            break;
        case "speedtest-disk":
            root.overlayRequested("disktest");
            break;
        case "wifiqr":
            root.overlayRequested("wifiqr");
            break;
        case "about":
            root.runAction("menu-about");
            break;
        }
    }

    function dispatchBinding(row: var): void {
        const d = row.dispatcher ?? "";
        const arg = row.arg ?? "";
        if (!d)
            return;
        if (d === "exec" && arg && !arg.includes(" ")) {
            // Fast path: a single word command needs no quoting machinery.
            Quickshell.execDetached(["bash", "-c", arg]);
            return;
        }
        // One dispatcher, the tested one. The dispatcher and arg ride as
        // positional parameters ($1/$2), not interpolated text, so args with
        // quotes or $(...) reach menu-keybindings byte for byte.
        Quickshell.execDetached(["bash", "-c",
            `export PATH="${root.binDir}:$PATH"; exec menu-keybindings --dispatch "$1" "$2"`,
            "menu-dispatch", d, arg
        ]);
    }

    function loadBindings(): void {
        bindingProc.command = ["bash", "-c", `export PATH="${root.binDir}:$PATH"; ${root.binDir}/menu-keybindings --records`];
        console.log("loadBindings starting");
        bindingProc.running = true;
    }

    Process {
        id: emojiProc

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const sp = lines[i].indexOf(" ");
                    if (sp < 1)
                        continue;
                    const name = lines[i].slice(sp + 1);
                    if (name.toLowerCase().includes("regional indicator"))
                        continue;
                    rows.push({
                        char: lines[i].slice(0, sp),
                        name
                    });
                }
                root.emojis = rows;
                root.viewChanged();
            }
        }
    }

    Process {
        id: loader

        running: true
        command: ["cat", `${root.menuDir}/menu.jsonc`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.tree = root.parseJsonc(text);
                    root.loaded = true;
                    root.evalConds();
                } catch (e) {
                    console.warn("MenuService: failed to parse menu.jsonc:", e);
                }
            }
        }
    }

    function evalConds(): void {
        const set = new Set();
        function walk(nodes) {
            for (const n of nodes) {
                if (n.when)
                    set.add(n.when);
                if (n.checked)
                    set.add(n.checked);
                if (n.disabled)
                    set.add(n.disabled);
            }
        }
        if (root.tree)
            walk(root.rootChildren());

        const conds = [...set];
        if (conds.length === 0)
            return;

        const script = conds.map((c, i) => `if ${c} >/dev/null 2>&1; then printf '%s\\t%s\\n' "${i}" true; else printf '%s\\t%s\\n' "${i}" false; fi`).join("\n");
        // Stop any in-flight batch first; a stale result must not overwrite
        // a fresher one when evalConds is called repeatedly.
        condProc.running = false;
        condProc.command = ["bash", "-c", script];
        condProc.condList = conds;
        condProc.running = true;
    }

    Process {
        id: condProc

        property var condList: []

        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const fields = lines[i].split("\t");
                    if (fields.length < 2)
                        continue;
                    map[condProc.condList[Number(fields[0])]] = fields[1].trim() === "true";
                }
                root.conds = map;
                root.viewChanged();
            }
        }
    }

    Process {
        id: bindingProc

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split("\t");
                    if (parts.length < 3)
                        continue;
                    rows.push({
                        display: parts[0],
                        dispatcher: parts[1],
                        arg: parts.slice(2).join("\t")
                    });
                }
                root.bindings = rows;
                root.viewChanged();
            }
        }
    }

    function loadEmojis(): void {
        console.log("loadEmojis starting");
        emojiProc.command = ["bash", "-c", "caelestia emoji"];
        emojiProc.running = true;
    }
}
