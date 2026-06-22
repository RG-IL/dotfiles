#!/bin/zsh
if [[ -S /tmp/nvim-editor.sock ]]; then
  for f in "$@"; do
    /opt/homebrew/bin/nvim --server /tmp/nvim-editor.sock --remote "$f"
  done
  exit 0
fi

first="$1"
shift

client=$(/opt/homebrew/bin/tmux list-clients -F '#{client_name}' 2>/dev/null | head -1)
if [[ -n "$client" ]]; then
  if /opt/homebrew/bin/tmux has-session -t editor 2>/dev/null; then
    /opt/homebrew/bin/tmux send-keys -t "editor" " /opt/homebrew/bin/nvim --listen /tmp/nvim-editor.sock \"$first\"" Enter
  else
    /opt/homebrew/bin/tmux new-session -d -s editor "/opt/homebrew/bin/nvim --listen /tmp/nvim-editor.sock \"$first\"; exec /bin/zsh -l"
  fi
  /opt/homebrew/bin/tmux switch-client -c "$client" -t editor
else
  export NVIM_QUICK_ACTION=1
  export NVIM_QUICK_FILE="$first"
  /Applications/Ghostty.app/Contents/MacOS/ghostty </dev/null >/dev/null 2>&1 &
fi

# Wait for socket to be ready, then send remaining files
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [[ -S /tmp/nvim-editor.sock ]] && break
  sleep 0.1
done

for f in "$@"; do
  /opt/homebrew/bin/nvim --server /tmp/nvim-editor.sock --remote "$f"
done
