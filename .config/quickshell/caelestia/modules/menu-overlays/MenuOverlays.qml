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

        target: "menu"
    }
}
