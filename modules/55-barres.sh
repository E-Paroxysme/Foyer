#!/usr/bin/env bash
# Barres de titre pour toutes les fenêtres (réduire, agrandir, fermer) :
# extension officielle hyprbars, compilée par hyprpm pour la version d'Hyprland
# installée. Relancé à chaque « foyer update » : après une mise à jour d'Hyprland,
# l'extension est recompilée (sinon Hyprland refuse simplement de la charger).
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

if ! command -v hyprpm >/dev/null; then
  avertir "hyprpm absent : pas de barres de titre."
  exit 0
fi
# hyprpm a besoin d'une session Hyprland ouverte (il compile pour la version qui tourne).
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  avertir "Barres de titre : à installer depuis ta session (lance « foyer update barres » dans un terminal)."
  exit 0
fi

journal="${XDG_STATE_HOME:-$HOME/.local/state}/foyer/hyprpm.log"
mkdir -p "$(dirname "$journal")"

info "Barres de titre : en-têtes d'Hyprland (première fois : quelques minutes)"
if ! hyprpm update >>"$journal" 2>&1; then
  avertir "hyprpm update a échoué (détails : $journal). Pas de barres de titre pour l'instant."
  exit 0
fi

if ! hyprpm list 2>/dev/null | grep -q hyprbars; then
  info "Barres de titre : compilation de l'extension hyprbars"
  # hyprpm demande confirmation pour un nouveau dépôt : c'est le dépôt officiel d'Hyprland.
  if ! echo y | hyprpm add https://github.com/hyprwm/hyprland-plugins >>"$journal" 2>&1; then
    avertir "Ajout de hyprland-plugins impossible (détails : $journal)."
    exit 0
  fi
fi

repere="${XDG_STATE_HOME:-$HOME/.local/state}/foyer/barres-actives"
hyprpm enable hyprbars >>"$journal" 2>&1 || { rm -f "$repere"; avertir "Activation de hyprbars impossible (détails : $journal)."; exit 0; }
hyprpm reload >>"$journal" 2>&1 || avertir "Rechargement des extensions impossible (détails : $journal)."
if hyprctl plugin list 2>/dev/null | grep -qi hyprbars; then
  touch "$repere"
else
  rm -f "$repere"
  avertir "hyprbars compilé mais pas chargé par Hyprland (détails : $journal, et « hyprctl plugin list »)."
fi
# Le terminal prend la barre de hyprbars (ou garde la sienne si l'extension manque).
bash "$FOYER_DIR/modules/45-theme.sh" >/dev/null 2>&1 || true
# La config relit theme.lua : les barres prennent les couleurs du thème.
hyprctl reload >/dev/null 2>&1 || true
info "Barres de titre actives"
