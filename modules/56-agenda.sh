#!/usr/bin/env bash
# Agenda du hub : dossier des événements, configuration de khal / vdirsyncer,
# synchronisation toutes les 15 minutes et rappels dans la pastille.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

info "Agenda : événements et agendas branchés"
for u in foyer-agenda-sync.service foyer-agenda-sync.timer foyer-agenda-rappels.service foyer-agenda-rappels.timer; do
  deposer "$FOYER_DIR/defaults/systemd/$u" "$FOYER_CONFIG/systemd/user/$u"
done
"$FOYER_DIR/bin/foyer-agenda" regenerer || avertir "Configuration de l'agenda non générée."
if systemctl --user daemon-reload 2>/dev/null; then
  systemctl --user enable --now foyer-agenda-sync.timer foyer-agenda-rappels.timer >/dev/null 2>&1 \
    || avertir "Minuteries de l'agenda non activées."
else
  avertir "Session utilisateur indisponible : minuteries de l'agenda activées à la prochaine mise à jour."
fi
