#!/usr/bin/env bash
# Détection du matériel : microcode du processeur et pilotes graphiques.
# Écrit aussi un profil graphique (« eco » ou « normal ») lu par la config Hyprland.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

pacman_installer pciutils

cpu="$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')"
case "$cpu" in
  GenuineIntel) info "Processeur Intel : microcode intel-ucode"; pacman_installer intel-ucode ;;
  AuthenticAMD) info "Processeur AMD : microcode amd-ucode";     pacman_installer amd-ucode ;;
  *) avertir "Processeur non reconnu ($cpu), pas de microcode installé." ;;
esac

gpu="$(lspci -nn | grep -Ei 'vga|3d|display' || true)"
info "Carte(s) graphique(s) : ${gpu:-aucune détectée}"

profil="normal"

if grep -qi intel <<<"$gpu"; then
  pacman_installer mesa vulkan-intel intel-media-driver libva-intel-driver
  # Générations Intel anciennes (2011-2014) : OpenGL ES 3.0 au mieux, juste le
  # minimum de Hyprland. On coupe le flou et les ombres pour garder de la fluidité.
  if grep -Eqi '2nd Generation|3rd Generation|4th Generation|Sandy|Ivy|Haswell|HD Graphics (2000|3000|2500|4000)' <<<"$gpu"; then
    profil="eco"
  fi
fi

if grep -Eqi 'amd|ati|radeon' <<<"$gpu"; then
  pacman_installer mesa vulkan-radeon
fi

if grep -qi nvidia <<<"$gpu"; then
  avertir "Carte NVIDIA détectée : pilote nvidia-open-dkms (cartes GTX 16xx / RTX et plus récentes)."
  avertir "Pour une carte plus ancienne, ce pilote ne convient pas : à traiter à la main."
  pacman_installer linux-headers nvidia-open-dkms nvidia-utils libva-nvidia-driver
fi

mkdir -p "$FOYER_CONFIG/foyer"
echo "$profil" >"$FOYER_CONFIG/foyer/profil-graphique"
info "Profil graphique : $profil"
