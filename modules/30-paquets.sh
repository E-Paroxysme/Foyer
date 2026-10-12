#!/usr/bin/env bash
# Installation des logiciels : dépôts Arch, puis AUR, puis Flatpak.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

P="$FOYER_DIR/paquets"

info "Paquets des dépôts Arch"
mapfile -t liste < <(cat "$P/base.txt" "$P/bureau.txt" "$P/apps.txt" | sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d')
pacman_installer "${liste[@]}"

info "Paquets AUR (via yay)"
mapfile -t aur < <(lire_liste "$P/aur.txt")
if [[ ${#aur[@]} -gt 0 ]]; then
  yay -S --needed --noconfirm "${aur[@]}" || avertir "Certains paquets AUR n'ont pas pu être installés (voir le journal)."
fi

info "Applications Flatpak (Flathub)"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
while read -r id; do
  if flatpak info "$id" >/dev/null 2>&1; then
    info "$id déjà installé"
  else
    sudo flatpak install -y --noninteractive flathub "$id" || avertir "Flatpak introuvable ou en échec : $id"
  fi
done < <(lire_liste "$P/flatpak.txt")
