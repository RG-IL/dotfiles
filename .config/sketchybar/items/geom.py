#!/usr/bin/env python3
import subprocess
import re
import sys

# Emits: notch_left notch_width playpause_x bracket_left_right
#        media_width right_bracket_right
#
# Queries are parsed with a regex instead of json.loads because sketchybar
# emits unescaped double quotes in label values (e.g. a title containing
# quotes), which makes the item JSON invalid and crashes a full JSON parse.

SB = "/opt/homebrew/bin/sketchybar"

_PAT = re.compile(
    rb'"display-1":\s*\{\s*"origin":\s*\[\s*(-?\d+\.?\d*)\s*,'
    rb'\s*(-?\d+\.?\d*)\s*\],\s*"size":\s*\[\s*(-?\d+\.?\d*)\s*,'
    rb'\s*(-?\d+\.?\d*)\s*\]\s*\}'
)


def query(name):
    out = subprocess.check_output([SB, "--query", name])
    m = _PAT.search(out)
    if not m:
        sys.exit(1)
    return float(m.group(1)), float(m.group(3))


notch = query("center.notch")
playpause = query("center.media.playpause")
bracket_left = query("bracket.left")
bracket_right = query("bracket.right")
media = query("center.media")

print(
    notch[0], notch[1],
    playpause[0],
    bracket_left[0] + bracket_left[1],
    media[1],
    bracket_right[0] + bracket_right[1],
)
