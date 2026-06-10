#!/usr/bin/env python3
import sys

def get_info():
    try:
        import CoreWLAN
        client = CoreWLAN.CWWiFiClient.sharedWiFiClient()
        iface = client.interface()
        if iface is None or not iface.serviceActive():
            return ("", "", "")
        rssi = iface.rssiValue()
        noise = iface.noiseMeasurement()
        return ("", str(rssi), str(noise))
    except Exception:
        pass
    return ("", "", "")

def main():
    ssid, rssi, noise = get_info()
    print(f"     agrCtlRSSI: {rssi}")
    print(f"    agrCtlNoise: {noise}")
    print(f"           SSID: {ssid}")

if __name__ == "__main__":
    main()
