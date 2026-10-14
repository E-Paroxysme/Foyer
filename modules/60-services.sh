#!/usr/bin/env bash
# Services système à activer.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

info "Réseau, Bluetooth, énergie, impression"
activer_service NetworkManager.service
activer_service bluetooth.service
activer_service power-profiles-daemon.service
activer_service cups.socket
activer_service fstrim.timer

info "Son (PipeWire) pour la session utilisateur"
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service >/dev/null 2>&1 \
  || avertir "Services audio utilisateur non activés (ils démarreront sans doute seuls)."

info "Dates en français (langue fr_FR disponible, sans changer la langue du système)"
if ! locale -a 2>/dev/null | grep -qi '^fr_FR\.utf-\?8$'; then
  # shellcheck disable=SC2015
  sudo sed -i 's/^#\s*fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen \
    && sudo locale-gen >/dev/null \
    || avertir "Impossible de générer la langue fr_FR (les dates resteront en anglais)."
fi

info "Clavier français dans la console"
sudo localectl set-keymap fr 2>/dev/null || avertir "Impossible de régler le clavier de la console."
