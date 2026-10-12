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

info "Clavier français dans la console"
sudo localectl set-keymap fr 2>/dev/null || avertir "Impossible de régler le clavier de la console."
