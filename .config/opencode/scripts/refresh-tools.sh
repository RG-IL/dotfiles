#!/usr/bin/env zsh
# Discover and print all Composio tools across connected + discovered toolkits.
# Regenerates a full tool listing to stdout (for manual review/merge into learned-tools.md).
# Usage: refresh-tools.sh [toolkit1 toolkit2 ...]
# Add new toolkit slugs as arguments when installing new MCP servers.

# Collect toolkits: connected accounts + command-line args
TOOLKITS=("$@")

# Add ACTIVE connected accounts
for tk in $(composio connections list 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for tk, conns in data.items():
    for c in conns:
        if c.get('status') == 'ACTIVE':
            print(tk)
            break
"); do
  TOOLKITS+=("$tk")
done

# Known discoverable toolkits (add new ones here as needed)
for slug in openweather_api weathermap text_to_pdf pdf4me; do
  TOOLKITS+=("$slug")
done

# Deduplicate
typeset -U TOOLKITS

echo "=== TOOLKITS WITH ACTIVE CONNECTIONS ==="
echo "${TOOLKITS[*]}"
echo ""
echo "=== TOOL LISTING ==="
echo ""

for tk in "${TOOLKITS[@]}"; do
  result=$(composio tools list "$tk" 2>/dev/null)
  tools=$(echo "$result" | python3 -c "
import json, sys
try:
    tools = json.load(sys.stdin)
    for t in tools:
        slug = t['slug']
        desc = t.get('description', '').split('.')[0].strip()
        print(f'- \`{slug}\` — {desc}')
except:
    pass
" 2>/dev/null)
  if [[ -n "$tools" ]]; then
    echo "## $tk"
    echo ""
    echo "$tools"
    echo ""
  fi
done

echo "Toolkits: ${TOOLKITS[*]}"
