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
bash -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
sudo systemctl enable sddm
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager
chsh -s $(which zsh)
sleep 5
sudo mkdir -p /etc/keyd
sudo tee /etc/keyd/default.conf <<'EOF'
[ids]
*

[main]
capslock = overload(capsmod,esc)

[capsmod:C-A-S]
EOF

sudo systemctl enable --now keyd
reboot
