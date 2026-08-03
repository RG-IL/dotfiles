#!/bin/bash
# Fast now-playing probe.
#
# Uses nowplaying-cli's mediaremote-mini helper, which queries the macOS
# 15.4+ media daemon directly and answers in ~20ms whether or not anything is
# playing. nowplaying-cli itself blocks ~2.7s when idle (its legacy fallback),
# so polling it on a timer piled up processes and burned CPU.
#
# The helper's JSON exposes a real "playing" boolean, whereas "playbackRate"
# is always null for browser (WebKit) sessions — so the boolean is the only
# reliable play/pause signal and is used here (falling back to playbackRate).
#
# Output: <playing:0|1>\n<title>\n<artist>
SCRIPT="/opt/homebrew/opt/nowplaying-cli/share/nowplaying-cli/scripts/mediaremote-mini.pl"
DYLIB="/opt/homebrew/opt/nowplaying-cli/lib/nowplaying-cli/MediaRemoteMini.dylib"

OUT=$(/usr/bin/perl "$SCRIPT" "$DYLIB" adapter_get_env 2>/dev/null \
  | /usr/bin/perl -ne '
    $p = /"playing":\s*(true|false)/ ? ($1 eq "true" ? 1 : 0) : 0;
    $r = /"playbackRate":\s*([0-9.]+)/ ? $1 : 0;
    $playing = $p || ($r > 0 ? 1 : 0);
    $title = /"title":"((?:[^"\\]|\\.)*)"/ ? $1 : "";
    $artist = /"artist":"((?:[^"\\]|\\.)*)"/ ? $1 : "";
    print "$playing\n$title\n$artist\n";
  ')

if [ -z "$OUT" ]; then
    exec nowplaying-cli get playbackRate title artist
fi

printf '%s' "$OUT"
