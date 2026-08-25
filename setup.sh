cd
sleep 5
sudo pacman -S stow
sleep 5
sudo pacman -S base-devel
sleep 5
git clone https://aur.archlinux.org/paru.git
sleep 5
cd paru/
sleep 5
makepkg -si
sleep 5
rustup default stable
sleep 5
makepkg -si
sleep 5
cd ..
sleep 5
rm -rf paru/
sleep 5
paru -S caelestia-cli
sleep 5
caelestia install --disable-components micro,firefox,fish,foot,starship
sleep 5
sudo pacman -S - <dotfiles/packages.txt
sleep 5
paru -S - <dotfiles/aur-packages.txt
sleep 5
rm -rf ~/.bashrc
rm -rf ~/.config/fastfetch/
rm -rf ~/.config/caelestia/
rm -rf ~/.config/btop/
rm -rf ~/.config/lazygit/
rm -rf ~/.config/hypr/
sleep 5
cd dotfiles
sleep 5
stow .
sleep 5
bash -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
sleep 5
sudo systemctl enable --now sddm
sleep 5
sudo systemctl enable --now bluetooth
sleep 5
sudo systemctl enable --now NetworkManager
sleep 5
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

sudo systemctl restart keyd
reboot
