import CoreWLAN

// Prints the current Wi-Fi signal magnitude and transmit rate as "rssi|rate"
// (e.g. "76|57"). SSID is redacted on macOS 26+, so it is not reported.
// Both fields are empty (e.g. "|") when Wi-Fi is off.

if let iface = CWWiFiClient.shared().interface() {
    let rssi = iface.rssiValue()
    let rate = iface.transmitRate()
    let rssiMag = (rssi < 0) ? String(format: "%ld", -rssi) : ""
    let rateStr = (rate > 0) ? String(format: "%.0f", rate) : ""
    print("\(rssiMag)|\(rateStr)")
} else {
    print("|")
}
