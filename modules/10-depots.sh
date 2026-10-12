#!/usr/bin/env bash
# Réglages de pacman et installation de yay (pour l'AUR).
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

info "Réglages de pacman (couleurs, téléchargements parallèles)"
sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
sudo sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf

info "Mise à jour du système"
sudo pacman -Syu --noconfirm

pacman_installer base-devel git

if ! command -v yay >/dev/null 2>&1; then
  info "Installation de yay (accès à l'AUR)"
  tmp="$(mktemp -d)"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
else
  info "yay déjà présent"
fi
