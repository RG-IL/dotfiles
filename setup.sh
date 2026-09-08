cd
sudo pacman -S --needed --noconfirm stow base-devel rustup

# CPU vendor-specific: microcode + VA-API video driver
if grep -qm1 "AuthenticAMD" /proc/cpuinfo; then
  echo "AMD CPU detected"
  sudo pacman -S --needed --noconfirm amd-ucode libva-mesa-driver
elif grep -qm1 "GenuineIntel" /proc/cpuinfo; then
  echo "Intel CPU detected"
  sudo pacman -S --needed --noconfirm intel-ucode intel-media-driver
fi

git clone https://aur.archlinux.org/paru.git
cd paru/
rustup default stable
export PATH="$HOME/.cargo/bin:$PATH"
makepkg -si
cd ..
rm -rf paru/
paru -S caelestia-cli
caelestia install --disable-components micro,firefox,fish,foot,starship
sudo pacman -S --needed - <dotfiles/packages.txt
paru -S --needed - <dotfiles/aur-packages.txt
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

# Swap: keep whatever archinstall created; if none, fall back to zram
if ! swapon --show=NAME --noheadings 2>/dev/null | grep -q .; then
  sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram]
zram-size = ram / 2
EOF
fi

# Weekly SSD TRIM
sudo systemctl enable --now fstrim.timer

# Cloudflare WARP - auto-enable on networks doing SSL interception.
# Optional: prompted, so home machines can skip it entirely.
read -rp "Install and set up Cloudflare WARP? [y/N] " install_warp
if [[ "$install_warp" =~ ^[Yy]$ ]]; then
paru -S --needed --noconfirm cloudflare-warp-bin
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
