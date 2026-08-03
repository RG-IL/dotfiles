import CoreWLAN

// Prints the current Wi-Fi transmit rate in Mbps, or "N/A".
// SSID is redacted on macOS 26+, so this only reports the tx rate.

if let iface = CWWiFiClient.shared().interface() {
    let rate = iface.transmitRate()
    if rate > 0 {
        print(String(format: "%.0f", rate))
    } else {
        print("N/A")
    }
} else {
    print("N/A")
}
