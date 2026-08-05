#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title termusic change-mode
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔣

# Documentation:
# @raycast.author RaphaelGrumbach
# @raycast.authorURL https://raycast.com/RaphaelG

termusic playlist cycle-loop 2>/dev/null | cut -d' ' -f2-
