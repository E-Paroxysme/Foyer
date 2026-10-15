#!/usr/bin/env bash
# Barres de titre pour toutes les fenêtres (réduire, agrandir, fermer) :
# extension officielle hyprbars, compilée par hyprpm pour la version d'Hyprland
# installée. Relancé à chaque « foyer update » : après une mise à jour d'Hyprland,
# l'extension est recompilée (sinon Hyprland refuse simplement de la charger).
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

# hyprpm : paquet séparé de hyprland sur Arch (depuis 0.56), plus ce qu'il faut
# pour compiler les en-têtes d'Hyprland (dépendances de construction du paquet).
pacman_installer hyprpm cmake meson ninja cpio glaze hyprland-protocols hyprwayland-scanner xorgproto wayland-protocols || true
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

# hyprpm clone Hyprland (~250 Mo avec ses sous-modules, plus la compilation) dans
# $XDG_RUNTIME_DIR, un disque en mémoire limité à 10 % de la RAM : sur un PC à
# 2-4 Go, il se remplit et le clone s'arrête en route (sous-module udis86 vide).
# On lui donne un dossier sur le disque, avec un lien vers le vrai dossier
# « hypr » pour qu'il parle toujours à la session Hyprland.
vrai_runtime="$XDG_RUNTIME_DIR"
runtime_disque="${XDG_CACHE_HOME:-$HOME/.cache}/foyer/hyprpm-runtime"
mkdir -p "$runtime_disque"
chmod 700 "$runtime_disque"
ln -sfn "$vrai_runtime/hypr" "$runtime_disque/hypr"
[[ -e "$vrai_runtime/wayland-1" ]] && ln -sfn "$vrai_runtime/wayland-1" "$runtime_disque/wayland-1"
hyprpm() { XDG_RUNTIME_DIR="$runtime_disque" command hyprpm "$@"; }
echo "== $(date '+%F %T') · mémoire de session : $(df -h --output=size,avail "$vrai_runtime" | tail -1)" >>"$journal"

info "Barres de titre : en-têtes d'Hyprland (première fois : quelques minutes)"
debut=$(wc -l <"$journal" 2>/dev/null || echo 0)
mettre_a_jour() {
  hyprpm update >>"$journal" 2>&1 && return 0
  # Sous-module des sources (ex. subprojects/udis86) resté vide : clone incomplet
  # en cache. On vide le cache et on retente une fois, en mode bavard pour que le
  # journal contienne la sortie de git si ça recommence.
  if tail -n +"$((debut + 1))" "$journal" | grep -q "does not contain a CMakeLists.txt"; then
    info "Barres de titre : sources incomplètes, nouvel essai avec un cache propre"
    hyprpm purge-cache >>"$journal" 2>&1 <<<"y" || true
    rm -rf "$runtime_disque/hyprpm"
    hyprpm update -v >>"$journal" 2>&1 && return 0
  fi
  return 1
}
if ! mettre_a_jour; then
  # On montre la cause : la ligne qui suit « CMake Error » s'il y en a une,
  # sinon les dernières lignes de cette tentative. (|| true : un grep sans
  # résultat ne doit pas faire échouer tout le module.)
  essai=$(tail -n +"$((debut + 1))" "$journal" || true)
  # hyprpm retire la ligne « CMake Error at » et recopie la suite : la cause est
  # juste après « cmake complained: », pas à la fin du journal.
  cause=$(grep -A8 "cmake complained" <<<"$essai" | tail -9 || true)
  # Sortie de git (mode bavard) : dit pourquoi un sous-module n'a pas été récupéré.
  git_sortie=$(grep -A6 "git returned (rs)" <<<"$essai" | grep -iE "fatal|error|unable|could not" | head -4 || true)
  [[ -z "$git_sortie" ]] || cause="$cause"$'\n'"$git_sortie"
  [[ -n "$cause" ]] || cause=$(grep -B2 -A4 -iE "error" <<<"$essai" | head -10 || true)
  [[ -n "$cause" ]] || cause=$(tail -8 <<<"$essai" || true)
  while IFS= read -r l; do if [[ -n "$l" ]]; then avertir "  $l"; fi; done <<<"$cause"
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
