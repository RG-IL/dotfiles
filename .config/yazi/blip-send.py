#!/usr/bin/env python3
import AppKit
import subprocess
import sys
import time
from Quartz import (
    CGEventCreateKeyboardEvent, CGEventPost, kCGHIDEventTap,
    CGWindowListCopyWindowInfo, kCGWindowListOptionOnScreenOnly, kCGNullWindowID
)

focus_app = "Ghostty"
downs = 1
files = []
for arg in sys.argv[1:]:
    if arg.startswith("--focus="):
        focus_app = arg.split("=", 1)[1]
    elif arg.startswith("--downs="):
        downs = int(arg.split("=", 1)[1])
    else:
        files.append(arg)
if not files:
    sys.exit(0)

def blip_windows():
    return [w for w in CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID)
            if w.get('kCGWindowOwnerName') == 'Blip' and w.get('kCGWindowName')]

def send_key(code):
    CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(None, code, True))
    CGEventPost(kCGHIDEventTap, CGEventCreateKeyboardEvent(None, code, False))

def clop_pause(pause=True):
    pid = subprocess.run(['pgrep', '-x', 'Clop'], capture_output=True, text=True).stdout.strip()
    if not pid:
        return
    sig = 'STOP' if pause else 'CONT'
    subprocess.run(['kill', f'-{sig}', pid])

clop_pause(True)
try:
    pb = AppKit.NSPasteboard.generalPasteboard()
    pb.clearContents()
    urls = [AppKit.NSURL.fileURLWithPath_(f) for f in files]
    pb.writeObjects_(urls)
    AppKit.NSPerformService("Blip…", pb)

    for _ in range(10):
        for w in blip_windows():
            if 'Items' in str(w.get('kCGWindowName', '')):
                time.sleep(0.01)
                for _ in range(downs):
                    send_key(125)
                    time.sleep(0.01)
                send_key(36)
                break
        else:
            time.sleep(0.01)
            continue
        break
    else:
        for _ in range(downs):
            send_key(125)
            time.sleep(0.01)
        send_key(36)

    for _ in range(600):
        time.sleep(0.05)
        if not blip_windows():
            break

    subprocess.run(['osascript', '-e', f'tell app "{focus_app}" to activate'])
finally:
    pb.clearContents()
    time.sleep(0.3)
    clop_pause(False)
