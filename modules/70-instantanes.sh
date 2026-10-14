#!/usr/bin/env bash
# Instantanés Btrfs : un état du système avant et après chaque installation de
# paquets, pour revenir en arrière si une mise à jour casse quelque chose.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

if [[ "$(findmnt -no FSTYPE /)" != "btrfs" ]]; then
  avertir "La racine n'est pas en Btrfs : instantanés non disponibles (choisis Btrfs dans archinstall)."
  exit 0
fi

pacman_installer snapper snap-pac

if ! sudo snapper list-configs 2>/dev/null | grep -q '^root'; then
  info "Configuration de snapper pour /"
  # archinstall crée souvent déjà un sous-volume /.snapshots : snapper refuse alors
  # de créer sa config. On le démonte, on laisse snapper faire, puis on remonte.
  if mountpoint -q /.snapshots; then
    sudo umount /.snapshots
    sudo rm -rf /.snapshots
    sudo snapper -c root create-config /
    sudo btrfs subvolume delete /.snapshots >/dev/null
    sudo mkdir /.snapshots
    sudo mount -a
  else
    sudo snapper -c root create-config /
  fi
fi

info "Limite : 5 instantanés de mises à jour conservés"
sudo snapper -c root set-config NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=5 TIMELINE_CREATE=no
# Les Réglages du hub listent les instantanés, en créent, et permettent de
# parcourir leurs fichiers : accès donné à l'utilisateur.
sudo snapper -c root set-config ALLOW_USERS="${USER:-$(id -un)}" SYNC_ACL=yes || avertir "Accès utilisateur aux instantanés non réglé."

if pacman -Q grub >/dev/null 2>&1; then
  info "GRUB détecté : instantanés proposés au démarrage (grub-btrfs)"
  pacman_installer grub-btrfs inotify-tools
  activer_service grub-btrfsd.service
  sudo grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || avertir "grub-mkconfig a échoué."
else
  avertir "Chargeur de démarrage autre que GRUB : instantanés disponibles, mais pas dans le menu de démarrage."
fi

sudo snapper -c root create -d "Foyer : après installation" >/dev/null || true
