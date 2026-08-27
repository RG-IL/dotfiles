import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.launcher.services

// Hosts the menu's standalone overlays (speed tests, Wi-Fi QR) and exposes
// deep links over IPC so scripts can open menu routes directly:
//   qs -c caelestia ipc call menu open "style.scheme"
//   qs -c caelestia ipc call menu speedtest

Item {
    id: root

    NetworkSpeedTest {
        id: networkSpeedTest
    }
    DiskSpeedTest {
        id: diskSpeedTest
    }
    WifiQrOverlay {
        id: wifiQrOverlay
    }

    // Stack the overlay cards when several are open at once so they don't
    // cover each other: they pack toward the vertical center as cards. The
    // vertical order is fixed: Wi-Fi QR on top, disk (read/write) in the
    // middle, network (download/upload) at the bottom. Each overlay gets the
    // total-open count and its rank, which the coordinator turns into a
    // vertical center offset.
    readonly property bool netOpen: networkSpeedTest.opened
    readonly property bool diskOpen: diskSpeedTest.opened
    readonly property bool qrOpen: wifiQrOverlay.opened
    readonly property int openTotal: (netOpen ? 1 : 0) + (diskOpen ? 1 : 0) + (qrOpen ? 1 : 0)

    // Rank within the open set, by fixed priority (QR > disk > network) and
    // only assigned when the overlay is itself open; -1 otherwise. Since an
    // overlay's card only shows while open, the -1 ranks are never rendered.
    readonly property int netRank: netOpen ? (qrOpen ? 1 : 0) + (diskOpen ? 1 : 0) : -1
    readonly property int diskRank: diskOpen ? (qrOpen ? 1 : 0) : -1
    readonly property int qrRank: qrOpen ? 0 : -1

    Binding {
        target: networkSpeedTest
        property: "stackCount"
        value: root.openTotal
    }
    Binding {
        target: networkSpeedTest
        property: "stackRank"
        value: root.netRank
    }
    Binding {
        target: networkSpeedTest
        property: "stackCenter"
        value: root.stackCenterFor("net")
    }
    Binding {
        target: diskSpeedTest
        property: "stackCount"
        value: root.openTotal
    }
    Binding {
        target: diskSpeedTest
        property: "stackRank"
        value: root.diskRank
    }
    Binding {
        target: diskSpeedTest
        property: "stackCenter"
        value: root.stackCenterFor("disk")
    }
    Binding {
        target: wifiQrOverlay
        property: "stackCount"
        value: root.openTotal
    }
    Binding {
        target: wifiQrOverlay
        property: "stackRank"
        value: root.qrRank
    }
    Binding {
        target: wifiQrOverlay
        property: "stackCenter"
        value: root.stackCenterFor("qr")
    }

    // Global key handling: one Esc closes every overlay, Enter re-runs every
    // open speed test. Because only the topmost focused window receives keys,
    // whichever overlay is focused forwards its request here and the
    // coordinator acts on the whole set.
    function closeAll() {
        networkSpeedTest.close();
        diskSpeedTest.close();
        wifiQrOverlay.close();
    }

    function runOpenSpeedTests() {
        if (root.netOpen)
            networkSpeedTest.runSpeedTest();
        if (root.diskOpen)
            diskSpeedTest.runTest();
    }

    // Vertical center fraction for a given overlay, decided by which overlays
    // are actually open. The two speed tests alone stay close together as a
    // square near the middle; the Wi-Fi QR card sits up high whenever it is
    // stacked with a speed test.
    function stackCenterFor(type) {
        const n = root.netOpen, d = root.diskOpen, q = root.qrOpen;
        const total = (n ? 1 : 0) + (d ? 1 : 0) + (q ? 1 : 0);
        if (total <= 1)
            return 0.5;
        if (n && d && q)
            return type === "qr" ? 0.20 : type === "disk" ? 0.50 : 0.76;
        if (n && d && !q)
            return type === "net" ? 0.63 : 0.37;
        if ((n || d) && q)
            return type === "qr" ? 0.35 : 0.65;
        return 0.5;
    }

    Connections {
        target: networkSpeedTest.overlay

        function onCloseRequested(): void {
            root.closeAll();
        }
        function onRunAgainRequested(): void {
            root.runOpenSpeedTests();
        }
    }
    Connections {
        target: diskSpeedTest.overlay

        function onCloseRequested(): void {
            root.closeAll();
        }
        function onRunAgainRequested(): void {
            root.runOpenSpeedTests();
        }
    }
    Connections {
        target: wifiQrOverlay

        function onCloseRequested(): void {
            root.closeAll();
        }
        function onRunAgainRequested(): void {
            root.runOpenSpeedTests();
        }
    }

    Connections {
        function onOverlayRequested(name: string): void {
            if (name === "speedtest")
                networkSpeedTest.open();
            else if (name === "disktest")
                diskSpeedTest.open();
            else if (name === "wifiqr")
                wifiQrOverlay.open();
        }

        target: MenuService
    }

    IpcHandler {
        function open(route: string): string {
            MenuService.openRoute(route);
            const screenState = ShellState.forActive();
            if (!screenState.launcher)
                screenState.launcher = true;
            return "ok";
        }

        function speedtest(): string {
            networkSpeedTest.open();
            return "ok";
        }

        function disktest(): string {
            diskSpeedTest.open();
            return "ok";
        }

        function wifiqr(): string {
            wifiQrOverlay.open();
            return "ok";
        }

        function refresh(): string {
            MenuService.evalConds();
            return "ok";
        }

        target: "menu"
    }
}
