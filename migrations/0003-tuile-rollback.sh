#!/usr/bin/env bash
# v0.5 : ajoute la tuile « Version précédente » (foyer rollback) à côté de « Mettre à jour ».
# Ajout seulement : les autres tuiles et réglages restent tels quels. Si une tuile
# « rollback » existe déjà (ou si le fichier est illisible), on ne touche à rien.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"
f="$FOYER_CONFIG/foyer/tuiles.json"
[[ -f "$f" ]] || exit 0
command -v jq >/dev/null || { avertir "jq absent : tuile « Version précédente » non ajoutée"; exit 0; }
jq -e '(.tuiles // .) | map(.id) | index("rollback")' "$f" >/dev/null 2>&1 && exit 0
tuile='{"id":"rollback","nom":"Version précédente","icone":"↶","description":"Revenir à la version précédente de Foyer","action":{"type":"commande","cible":"uwsm app -- foot -e sh -c '"'"'foyer rollback; echo; read -p \"Entrée pour fermer\"'"'"'"}}'
tmp="$(mktemp)"
if jq --indent 2 --argjson t "$tuile" '
    def ajouter: (map(.id) | index("maj")) as $i
      | if $i == null then . + [$t] else .[:$i+1] + [$t] + .[$i+1:] end;
    if type == "array" then ajouter else .tuiles = ((.tuiles // []) | ajouter) end' "$f" >"$tmp"; then
  deposer "$tmp" "$f"
  info "Tuile ajoutée : « Version précédente »"
else
  avertir "tuiles.json illisible : tuile « Version précédente » non ajoutée"
fi
rm -f "$tmp"
