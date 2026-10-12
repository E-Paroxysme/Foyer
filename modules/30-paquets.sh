#!/usr/bin/env bash
# Installation des logiciels : base système, bureau, essentiels, puis les groupes
# optionnels choisis (liste dans ~/.config/foyer/groupes, un nom par ligne).
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

P="$FOYER_DIR/paquets"
CHOIX="$FOYER_CONFIG/foyer/groupes"
mkdir -p "$FOYER_CONFIG/foyer"

# --- Choix des groupes optionnels --------------------------------------------
if [[ ! -f "$CHOIX" ]]; then
  if [[ -s "$FOYER_ETAT/migrations-faites" ]]; then
    # Machine installée avec la v0.1, qui installait tout : on garde tout.
    for g in "$P"/groupes/*.txt; do basename "$g" .txt; done >"$CHOIX"
  elif [[ -n "${FOYER_GROUPES:-}" ]]; then
    tr -s ', ' '\n' <<<"$FOYER_GROUPES" | sed '/^$/d' >"$CHOIX"
  else
    etape "Choix des logiciels optionnels (modifiable plus tard : foyer installer <groupe>)"
    : >"$CHOIX"
    for g in "$P"/groupes/*.txt; do
      nom="$(basename "$g" .txt)"
      read -r -p "  Installer « $(description_groupe "$g") » ? [o/N] " rep </dev/tty || rep=n
      [[ "$rep" =~ ^[oOyY] ]] && echo "$nom" >>"$CHOIX"
    done
  fi
fi
mapfile -t groupes < <(sed '/^$/d' "$CHOIX")
info "Groupes choisis : ${groupes[*]:-aucun}"

total=$((3 + ${#groupes[@]}))
n=0
sous_etape() { n=$((n + 1)); info "Logiciels $n/$total : $1"; }

sous_etape "système de base"
installer_liste "$P/base.txt"

sous_etape "bureau"
installer_liste "$P/bureau.txt"

sous_etape "essentiels"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
installer_liste "$P/essentiel.txt"

# LibreWolf : natif sous 4 Go de mémoire vive (un Flatpak charge ses propres
# bibliothèques en plus de celles du système), Flatpak au-delà.
ram_mo=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if ((ram_mo < 4000)); then
  info "Mémoire vive : ${ram_mo} Mo -> LibreWolf natif (AUR)"
  aur_installer librewolf-bin
else
  info "Mémoire vive : ${ram_mo} Mo -> LibreWolf en Flatpak"
  flatpak_installer io.gitlab.librewolf-community
fi

for g in "${groupes[@]}"; do
  if [[ -f "$P/groupes/$g.txt" ]]; then
    sous_etape "groupe $g"
    installer_liste "$P/groupes/$g.txt"
  else
    avertir "Groupe inconnu, ignoré : $g"
  fi
done
