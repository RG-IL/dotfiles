#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${TARGET:-$HOME}"
TARGET="$(realpath -m "$TARGET")"

usage() {
  cat <<EOF
usage: ./setup.sh [option]

Bootstraps a fresh Arch machine from this dotfiles repo.
Every step asks for confirmation first.

order of operations (with -p):
  1. make sure an AUR helper exists (offers to build paru if none)
  2. install caelestia-cli if missing, then run "caelestia install"
     so the shell pulls its own dependencies first
  3. compare packages.txt + aur-packages.txt against what is
     installed, and install ONLY what is still missing
  4. delete whatever conflicts with this repo
  5. stow this repo over the target directory
  6. set up sddm: enable service, restore /etc/sddm.conf.d configs,
     install sddm-astronaut-theme, set zsh as default shell

options:
  -p, --packages       do steps 1-5 (otherwise only cleanup and stow)
  -y, --yes            assume yes for every prompt
      --no-caelestia   skip step 2 (step 3 conflict cleanup still runs)
      --unstow         remove the symlinks created by this script
  -h, --help           show this help

environment:
  TARGET               destination directory to link into (default: \$HOME)

examples:
  ./setup.sh -p              full interactive setup on a new machine
  ./setup.sh                 regenerate symlinks only
  ./setup.sh -y -p           same as above without prompts
EOF
}

DO_PACKAGES=0
UNSTOW=0
NO_CAELESTIA=0
ASSUME_YES=0
HELPER=''
while (($#)); do
  case $1 in
    -p | --packages) DO_PACKAGES=1 ;;
    -y | --yes) ASSUME_YES=1 ;;
    --no-caelestia) NO_CAELESTIA=1 ;;
    --unstow) UNSTOW=1 ;;
    -h | --help) usage ;;
    *) printf 'unknown option: %s\n\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'error: %s is required (sudo pacman -S %s)\n' "$1" "$1" >&2
    exit 1
  }
}

confirm() {
  ((ASSUME_YES)) && return 0
  local answer=''
  if ! read -rp "$1 [y/N] " answer </dev/tty 2>/dev/null; then
    printf '(no terminal available, answering no)\n' >&2
    return 1
  fi
  [[ $answer =~ ^[yY] ]]
}

have_pkg() {
  pacman -Qi "$1" >/dev/null 2>&1
}

ensure_aur_helper() {
  local h
  for h in paru yay; do
    if command -v "$h" >/dev/null 2>&1; then
      HELPER=$h
      printf ':: using AUR helper: %s\n' "$HELPER"
      return 0
    fi
  done
  printf ':: no AUR helper found\n'
  if ! have_pkg git; then
    if confirm "git is missing, install it via pacman?"; then
      sudo pacman -S --needed git
    else
      printf ':: !! git is required to build a helper\n'
      return 1
    fi
  fi
  if ! have_pkg base-devel; then
    if confirm "base-devel is missing (makepkg), install it via pacman?"; then
      sudo pacman -S --needed base-devel
    else
      printf ':: !! base-devel is required to build a helper\n'
      return 1
    fi
  fi
  if ! confirm "build paru from the AUR now? (git clone + makepkg)"; then
    printf ':: !! without a helper the AUR packages cannot be installed\n'
    return 1
  fi
  local tmp
  tmp=$(mktemp -d)
  if git clone https://aur.archlinux.org/paru.git "$tmp/paru" &&
    (
      cd "$tmp/paru"
      makepkg -si
    ); then
    rm -rf "$tmp"
  else
    rm -rf "$tmp"
    printf ':: !! paru could not be cloned or built, AUR step will be skipped\n'
    return 1
  fi
  if command -v paru >/dev/null 2>&1; then
    HELPER=paru
    printf ':: paru installed\n'
  else
    printf ':: !! paru build did not produce a binary, AUR step will be skipped\n'
    return 1
  fi
}

ensure_caelestia_cli() {
  ((NO_CAELESTIA)) && return 0
  command -v caelestia >/dev/null 2>&1 && return 0
  [[ -n $HELPER ]] || { printf ':: !! cannot bootstrap caelestia-cli without an AUR helper\n'; return 1; }
  if confirm "install caelestia-cli via $HELPER? (provides the 'caelestia' command)"; then
    "$HELPER" -S --needed caelestia-cli
  else
    printf ':: skipped caelestia-cli\n'
    return 1
  fi
}

install_missing_packages() {
  local want missing=''
  while read -r want; do
    [[ -n $want ]] || continue
    if ! have_pkg "$want"; then
      missing+="$want"$'\n'
    fi
  done < <(cat packages.txt aur-packages.txt 2>/dev/null | sort -u)
  if [[ -z $missing ]]; then
    printf ':: everything in the package lists is already installed\n'
    return 0
  fi

  local repo=() aur=() p
  while read -r p; do
    [[ -n $p ]] || continue
    if pacman -Si "$p" >/dev/null 2>&1; then
      repo+=("$p")
    else
      aur+=("$p")
    fi
  done <<< "$missing"

  printf ':: %s repo and %s AUR packages still missing:\n' "${#repo[@]}" "${#aur[@]}"
  ((${#repo[@]})) && printf '   repo: %s\n' "${repo[*]}"
  ((${#aur[@]})) && printf '   aur:  %s\n' "${aur[*]}"

  if ((${#repo[@]})) && confirm "install the ${#repo[@]} repo packages with pacman?"; then
    sudo pacman -S --needed "${repo[@]}"
  fi
  if ((${#aur[@]})); then
    if [[ -n $HELPER ]] && confirm "install the ${#aur[@]} AUR packages with $HELPER?"; then
      "$HELPER" -S --needed "${aur[@]}"
    else
      printf ':: !! AUR packages left uninstalled: %s\n' "${aur[*]}"
    fi
  fi
}

caelestia_owned() {
  local p="$TARGET/.config/caelestia"
  [[ -L $p && $(readlink -f -- "$p" 2>/dev/null || true) == "$(realpath -- "$DOTFILES/.config/caelestia" 2>/dev/null)" ]]
}

run_caelestia_install() {
  if ((UNSTOW || NO_CAELESTIA)); then
    return 0
  fi
  if caelestia_owned; then
    printf ':: caelestia already linked from this repo, skipping installer\n'
    return 0
  fi
  if ! command -v caelestia >/dev/null 2>&1; then
    printf ':: !! caelestia not found, skipping installer (run it manually before stowing)\n'
    return 0
  fi
  local args=(--disable-components micro,starship,firefox,foot,fish)
  local h
  for h in paru yay; do
    if command -v "$h" >/dev/null 2>&1; then
      args+=(--aur-helper "$h")
      break
    fi
  done
  if confirm "run 'caelestia install ${args[*]}'? (it will ask its own questions too)"; then
    printf ':: running caelestia install\n'
    caelestia install "${args[@]}"
  else
    printf ':: skipped caelestia install, its generated files will not be cleaned\n'
    return 1
  fi
}

clear_conflicts() {
  local src rel dst src_real dst_target
  while IFS= read -r src; do
    rel="${src#"$DOTFILES"/}"
    dst="$TARGET/$rel"
    if [[ -d $src && -d $dst && ! -L $dst ]]; then
      continue
    fi
    [[ -e $dst || -L $dst ]] || continue
    src_real="$(realpath -- "$src")"
    dst_target="$(readlink -f -- "$dst" 2>/dev/null || true)"
    if [[ $dst_target == "$src_real" ]]; then
      continue
    fi
    if confirm "remove conflicting '$dst'?"; then
      rm -rf -- "$dst"
      printf ":: removed %s\n" "$dst"
    else
      printf ':: kept %s (stow may report a conflict)\n' "$dst"
    fi
  done < <(find "$DOTFILES" -mindepth 1 \( -name .git -prune \) -o -print | sort)
}

run_stow() {
  local act=(-R)
  ((UNSTOW)) && act=(-D)
  if ((UNSTOW)) && ! confirm "unstow dotfiles from $TARGET (removes the symlinks)?"; then
    printf ':: aborted\n'
    exit 0
  fi
  if ((UNSTOW)) && ((ASSUME_YES)); then
    :
  elif ((! UNSTOW)) && ! confirm "stow dotfiles into $TARGET now?"; then
    printf ':: aborted before stowing\n'
    exit 0
  fi
  printf ':: %s into %s\n' "$([[ ${act[0]} == -D ]] && echo unstowing || echo stowing)" "$TARGET"
  (
    cd "$DOTFILES"
    stow -v -t "$TARGET" "${act[@]}" .
  )
}

setup_sddm() {
  ((UNSTOW)) && return 0
  command -v systemctl >/dev/null 2>&1 || return 0
  if ! have_pkg sddm; then
    printf ':: !! sddm not installed, skipping sddm setup\n'
    return 0
  fi
  if ! systemctl is-enabled --quiet sddm 2>/dev/null; then
    if confirm "enable the sddm service?"; then
      sudo systemctl enable sddm
    fi
  fi
  local conf name
  for conf in "$DOTFILES"/etc-sddm/*.conf; do
    [[ -e $conf ]] || continue
    name=$(basename "$conf")
    if diff -q -- "$conf" "/etc/sddm.conf.d/$name" >/dev/null 2>&1; then
      continue
    fi
    if confirm "install $name into /etc/sddm.conf.d/? (sets the active theme and keyboard config)"; then
      sudo install -Dm644 -- "$conf" "/etc/sddm.conf.d/$name"
    fi
  done
  if confirm "install sddm-astronaut-theme? (clones to ~/sddm-astronaut-theme, its own installer asks questions)"; then
    if [[ ! -d $HOME/sddm-astronaut-theme ]]; then
      git clone https://github.com/Keyitdev/sddm-astronaut-theme.git "$HOME/sddm-astronaut-theme"
    fi
    bash "$HOME/sddm-astronaut-theme/setup.sh"
  fi
}

setup_shell() {
  ((UNSTOW)) && return 0
  if ! have_pkg zsh; then
    printf ':: !! zsh not installed, skipping default shell setup\n'
    return 0
  fi
  local user="${USER:-$(id -un)}"
  local current
  current=$(getent passwd "$user" | cut -d: -f7)
  if [[ $current == */zsh ]]; then
    printf ':: default shell is already zsh\n'
    return 0
  fi
  if confirm "set zsh as your default shell? (chsh will ask for your password)"; then
    chsh -s "$(command -v zsh)" "$user"
  fi
}

post_notes() {
  cat <<'EOF'

done. remaining manual steps:
  - restore personal data (Documents, Projects, Videos, ...) from your backup
EOF
  if [[ -x .config/caelestia/menu/install.sh && -t 0 ]]; then
    local answer=''
    read -rp 'run the caelestia menu installer now? [y/N] ' answer
    if [[ $answer =~ ^[yY] ]]; then
      bash .config/caelestia/menu/install.sh
    fi
  fi
}

cd "$DOTFILES"

if ((DO_PACKAGES)) && ((! UNSTOW)); then
  ensure_aur_helper || printf ':: continuing without an AUR helper\n'
  ensure_caelestia_cli || printf ':: continuing without caelestia bootstrap\n'
fi

need stow

if ((UNSTOW)); then
  run_stow
else
  run_caelestia_install || printf ':: continuing without the caelestia installer\n'
  if ((DO_PACKAGES)); then
    install_missing_packages
  fi
  mkdir -p "$TARGET/.config"
  clear_conflicts
  run_stow
  if ((DO_PACKAGES)); then
    setup_sddm
    setup_shell
  fi
  post_notes
fi
