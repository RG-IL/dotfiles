#!/usr/bin/env python3
"""
Screen Section Scraper — border‑based section detection.

1. Scan a horizontal line for separator colour #424548.
2. Group nearby matching pixels (≤5 px apart) into single borders.
3. Sections are formed from LEFT_X to first border, between consecutive
   borders, up to the last border (which is the right edge of the last
   section).
4. For each section: click at its midpoint, move 60 px down, click
   again, Cmd+Tab → nvim, type "yag", Option+Tab, Cmd+Tab back,
   Cmd+A, Cmd+V.

Requires: pip install mss Pillow pyobjc-framework-Quartz
Needs: macOS Accessibility permission
"""

import time
import sys

import mss
from PIL import Image

from Quartz import (
    CGEventCreateMouseEvent,  # type: ignore
    CGEventCreateKeyboardEvent,  # type: ignore
    CGEventPost,  # type: ignore
    CGEventSetFlags,  # type: ignore
    CGPointMake,  # type: ignore
    kCGHIDEventTap,  # type: ignore
    kCGMouseButtonLeft,  # type: ignore
    kCGEventMouseMoved,  # type: ignore
    kCGEventLeftMouseDown,  # type: ignore
    kCGEventLeftMouseUp,  # type: ignore
    kCGEventFlagMaskCommand,  # type: ignore
    kCGEventFlagMaskAlternate,  # type: ignore
)

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════════

LEFT_X = 555  # Left boundary of the first section (hardcoded)
SCAN_LEFT = LEFT_X  # X where pixel scanning starts
SCAN_RIGHT = 1373  # X where pixel scanning ends
SCAN_Y = 225  # Y coordinate of the scan line

TARGET_COLORS = [
    (66, 69, 72),  # #424548
    (39, 40, 43),  # #27282b
]
COLOR_TOLERANCE = 3
GROUP_GAP = 5  # matching pixels ≤ this apart → one border
CLICK_OFFSET_Y = 60  # px down from SCAN_Y for the second click
DELAY_S = 0.02
DEBUG = False  # if True: print debug info and exit before clicking
TMUX_WIN = 1  # Cmd+<N> after Cmd+Tab to jump to tmux window

# ═══════════════════════════════════════════════════════════════════════════════
# macOS key codes
# ═══════════════════════════════════════════════════════════════════════════════

KVK_A = 0x00
KVK_V = 0x09
KVK_Y = 0x10
KVK_G = 0x05
KVK_TAB = 0x30
KVK_CMD = 0x37
KVK_OPTION = 0x3A
KVK_1 = 0x12
KVK_2 = 0x13
KVK_3 = 0x14
KVK_4 = 0x15
KVK_5 = 0x17
KVK_6 = 0x16
KVK_7 = 0x1A
KVK_8 = 0x1C
KVK_9 = 0x19
KVK_0 = 0x1D

CHAR_KEYS = {"y": KVK_Y, "a": KVK_A, "g": KVK_G}
NUM_KEYS = {
    i: k
    for i, k in enumerate(
        [KVK_0, KVK_1, KVK_2, KVK_3, KVK_4, KVK_5, KVK_6, KVK_7, KVK_8, KVK_9]
    )
}

# ═══════════════════════════════════════════════════════════════════════════════
# Mouse helpers
# ═══════════════════════════════════════════════════════════════════════════════


def _mouse(etype, x, y):
    e = CGEventCreateMouseEvent(None, etype, CGPointMake(x, y), kCGMouseButtonLeft)
    CGEventPost(kCGHIDEventTap, e)


def move_mouse(x, y):
    _mouse(kCGEventMouseMoved, x, y)


def click(x, y):
    _mouse(kCGEventLeftMouseDown, x, y)
    time.sleep(0.04)
    _mouse(kCGEventLeftMouseUp, x, y)


# ═══════════════════════════════════════════════════════════════════════════════
# Keyboard helpers
# ═══════════════════════════════════════════════════════════════════════════════


def _key(keycode, down, flags=0):
    e = CGEventCreateKeyboardEvent(None, keycode, down)
    if flags:
        CGEventSetFlags(e, flags)
    CGEventPost(kCGHIDEventTap, e)


def tap(keycode, flags=0):
    _key(keycode, True, flags)
    time.sleep(0.03)
    _key(keycode, False, flags)


def modifier(keycode, press):
    _key(keycode, press)


def cmd_tab():
    modifier(KVK_CMD, True)
    time.sleep(0.12)
    tap(KVK_TAB, kCGEventFlagMaskCommand)
    time.sleep(0.12)
    modifier(KVK_CMD, False)
    time.sleep(DELAY_S)


def opt_tab():
    modifier(KVK_OPTION, True)
    time.sleep(0.12)
    tap(KVK_TAB, kCGEventFlagMaskAlternate)
    time.sleep(0.12)
    modifier(KVK_OPTION, False)
    time.sleep(DELAY_S)


def cmd_a():
    modifier(KVK_CMD, True)
    time.sleep(0.05)
    tap(KVK_A, kCGEventFlagMaskCommand)
    time.sleep(0.05)
    modifier(KVK_CMD, False)
    time.sleep(DELAY_S)


def cmd_v():
    modifier(KVK_CMD, True)
    time.sleep(0.05)
    tap(KVK_V, kCGEventFlagMaskCommand)
    time.sleep(0.05)
    modifier(KVK_CMD, False)
    time.sleep(DELAY_S)


def send_yag():
    for ch in "yag":
        code = CHAR_KEYS.get(ch)
        if code is not None:
            tap(code)
            time.sleep(0.08)
    time.sleep(DELAY_S)


def cmd_num(n):
    code = NUM_KEYS.get(n)
    if code is None:
        return
    modifier(KVK_CMD, True)
    time.sleep(0.05)
    tap(code, kCGEventFlagMaskCommand)
    time.sleep(0.05)
    modifier(KVK_CMD, False)
    time.sleep(DELAY_S)


# ═══════════════════════════════════════════════════════════════════════════════
# Scan
# ═══════════════════════════════════════════════════════════════════════════════


def scan_line(debug=False):
    """Capture 1‑px strip from SCAN_LEFT→SCAN_RIGHT at SCAN_Y.

    Returns list of (r,g,b) tuples, one per pixel.
    """
    width = max(SCAN_RIGHT - SCAN_LEFT, 1)
    with mss.MSS() as sct:
        region = {"left": SCAN_LEFT, "top": SCAN_Y, "width": width, "height": 1}
        raw = sct.grab(region)
        img = Image.frombytes("RGB", (width, 1), raw.rgb)
        flat = img.get_flattened_data()
        pixels = [flat[i] for i in range(width)]

    if debug:
        from collections import defaultdict

        colormap = defaultdict(list)
        for x, px in enumerate(pixels):
            colormap[px].append(SCAN_LEFT + x)
        print(
            f"Debug — {len(colormap)} unique colours along scan line (Y={SCAN_Y}, {SCAN_LEFT}→{SCAN_RIGHT}):"
        )
        for color, xs in sorted(colormap.items(), key=lambda kv: -len(kv[1])):
            hexc = f"#{color[0]:02x}{color[1]:02x}{color[2]:02x}"
            if len(xs) > 1:
                start = xs[0]
                end = xs[0]
                runs = []
                for x in xs[1:]:
                    if x == end + 1:
                        end = x
                    else:
                        runs.append(f"{start}-{end}" if start != end else str(start))
                        start = end = x
                runs.append(f"{start}-{end}" if start != end else str(start))
                pos_str = ", ".join(runs)
            else:
                pos_str = str(xs[0])
            print(
                f"    {hexc:>8}  ({color[0]:3d},{color[1]:3d},{color[2]:3d})  x{len(xs):>4}  [{pos_str}]"
            )
        print()

    return pixels


def color_match(px):
    return any(
        abs(px[0] - r) <= COLOR_TOLERANCE
        and abs(px[1] - g) <= COLOR_TOLERANCE
        and abs(px[2] - b) <= COLOR_TOLERANCE
        for r, g, b in TARGET_COLORS
    )


# ═══════════════════════════════════════════════════════════════════════════════
# Grouping & Section computation
# ═══════════════════════════════════════════════════════════════════════════════


def group_borders(matching_xs):
    """Group X positions ≤ GROUP_GAP apart; return midpoint of each group."""
    if not matching_xs:
        return []
    groups = []
    cur = [matching_xs[0]]
    for p in matching_xs[1:]:
        if p - cur[-1] <= GROUP_GAP:
            cur.append(p)
        else:
            groups.append(cur)
            cur = [p]
    groups.append(cur)
    return [(g[0] + g[-1]) // 2 for g in groups]


def compute_sections(borders):
    """Build (lo, hi, range_str) for each section.

    borders are the midpoint of each border group.
    Section i  →  (borders[i-1], borders[i])  with borders[-1] = LEFT_X.

    Returns list of (lo, hi, "lo–hi") tuples.
    """
    if not borders:
        return []
    boundaries = [LEFT_X] + borders
    return [
        (boundaries[i], boundaries[i + 1], f"{boundaries[i]}–{boundaries[i + 1]}")
        for i in range(len(boundaries) - 1)
    ]


# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════


def main():
    cmd_tab()  # warm up the app switcher (avoid first‑time delay later)
    time.sleep(1)
    hexes = [f"#{r:02x}{g:02x}{b:02x}" for r, g, b in TARGET_COLORS]
    print(
        f"Scanning for colours: {', '.join(hexes)}  at Y={SCAN_Y}  X={SCAN_LEFT}→{SCAN_RIGHT}"
    )
    sys.stdout.flush()

    pixels = scan_line(debug=DEBUG)

    target_xs = [SCAN_LEFT + x for x, px in enumerate(pixels) if color_match(px)]
    print(f"  Matching pixels: {len(target_xs)}")
    sys.stdout.flush()

    borders = group_borders(target_xs)
    border_strs = [str(b) for b in borders]
    print(f"  Border midpoints: {', '.join(border_strs) if border_strs else 'none'}")
    sys.stdout.flush()

    sections = compute_sections(borders)
    if not sections:
        print("  No sections found. Exiting.")
        sys.exit(1)

    print(f"  Sections ({len(sections)}):")
    for i, (lo, hi, rng) in enumerate(sections):
        cx = (lo + hi) // 2 if i > 0 else lo + (hi - lo) * 3 // 4
        print(f"    {i + 1}. range {rng}  →  click X = {cx}")
    print()
    sys.stdout.flush()

    if DEBUG:
        sys.exit(0)

    time.sleep(1)

    for i, (lo, hi, rng) in enumerate(sections):
        cx = (lo + hi) // 2 if i > 0 else lo + (hi - lo) * 3 // 4
        print(f"[{i + 1}/{len(sections)}] Section {rng}  X={cx}")

        move_mouse(cx, SCAN_Y)
        time.sleep(0.1)
        click(cx, SCAN_Y)
        time.sleep(DELAY_S)

        click(cx, SCAN_Y + CLICK_OFFSET_Y)
        time.sleep(DELAY_S)

        cmd_tab()
        if TMUX_WIN:
            cmd_num(TMUX_WIN)
        send_yag()
        opt_tab()
        cmd_tab()
        cmd_a()
        cmd_v()

        sys.stdout.flush()

    print("\nDone!")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted.")
        sys.exit(1)
