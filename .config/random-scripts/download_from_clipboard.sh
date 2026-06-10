#!/bin/bash

QUERY=$(pbpaste)

cd ~/Music/Media

yt-dlp "ytsearch1:$QUERY" \
  -x --audio-format mp3 \
  --audio-quality 0 \
  --embed-metadata \
  --output "%(title)s.%(ext)s"
