#!/usr/bin/env bash
# v0.3 : les tuiles d'applications utilisent l'icône officielle de l'app.
# On remplace tuiles.json UNIQUEMENT s'il est resté identique à celui livré en
# v0.3 initiale (emojis) : un fichier modifié par l'utilisateur n'est jamais touché.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"
f="$FOYER_CONFIG/foyer/tuiles.json"
ancien="335011541db919fb48067397b72e7ddb4fc3e6c9bc06fe77949f5d247033327f"
if [[ -f "$f" ]] && [[ "$(sha256sum "$f" | cut -d' ' -f1)" == "$ancien" ]]; then
  deposer "$FOYER_DIR/defaults/foyer/tuiles.json" "$f"
  info "Tuiles : icônes officielles des applications"
else
  info "Tuiles personnalisées : laissées telles quelles"
fi
