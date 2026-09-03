cd
sudo pacman -S stow
sudo pacman -S base-devel
git clone https://aur.archlinux.org/paru.git
cd paru/
makepkg -si
rustup default stable
makepkg -si
cd ..
rm -rf paru/
paru -S caelestia-cli
caelestia install --disable-components micro,firefox,fish,foot,starship
sudo pacman -S - <dotfiles/packages.txt
paru -S - <dotfiles/aur-packages.txt
rm -rf ~/.bashrc
rm -rf ~/.config/fastfetch/
rm -rf ~/.config/caelestia/
rm -rf ~/.config/btop/
rm -rf ~/.config/lazygit/
rm -rf ~/.config/hypr/
cd dotfiles
stow .
~/.config/quickshell/caelestia/sync-upstream.sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
sudo systemctl enable sddm
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager
sudo usermod --shell $(which zsh) $(whoami)
sudo mkdir -p /etc/keyd
sudo tee /etc/keyd/default.conf <<'EOF'
[ids]
*

[main]
capslock = overload(capsmod,esc)

[capsmod:C-A-S]
EOF

sudo systemctl enable --now keyd
systemctl --user enable wl-clip-persist.service

# Cloudflare WARP - auto-enable on networks doing SSL interception.
# Installed from aur-packages.txt (cloudflare-warp-bin).
# Registration below is one-time per device and is interactive.
if command -v warp-cli >/dev/null; then
sudo systemctl enable --now warp-svc
sudo mkdir -p /etc/NetworkManager/dispatcher.d
sudo tee /etc/NetworkManager/dispatcher.d/50-warp-autoconnect.sh <<'EOF'
#!/bin/bash

IFACE="$1"
ACTION="$2"
CONN="$CONNECTION_UUID"

WARP_NETWORKS=(
  "Dorit"
  "Dorit 1"
  "Pelech-Wifi"
  "Pelech-Wifi 1"
)

conn_name() {
  nmcli -t -f UUID,NAME connection show | awk -F: -v u="$1" '$1==u {print $2; exit}'
}

is_warp_network() {
  local name="$1"
  local n
  for n in "${WARP_NETWORKS[@]}"; do
    [[ "$name" == "$n" ]] && return 0
  done
  return 1
}

case "$ACTION" in
  up)
    NAME="$(conn_name "$CONN")"
    if is_warp_network "$NAME"; then
      warp-cli --accept-tos connect 2>/dev/null || true
    fi
    ;;
  down)
    NAME="$(conn_name "$CONN")"
    if is_warp_network "$NAME"; then
      warp-cli --accept-tos disconnect 2>/dev/null || true
    fi
    ;;
esac
EOF
sudo chmod +x /etc/NetworkManager/dispatcher.d/50-warp-autoconnect.sh
if ! warp-cli --accept-tos registration show >/dev/null 2>&1; then
  warp-cli --accept-tos registration new
else
  echo "WARP already registered, skipping."
fi
fi
reboot
