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

# LibreWolf : dans les dépôts officiels d'Arch depuis août 2026 (paquet natif,
# plus léger qu'un Flatpak). Repli sur Flathub si le paquet n'est pas trouvé.
if pacman -Si librewolf >/dev/null 2>&1; then
  info "LibreWolf (dépôts Arch)"
  pacman_installer librewolf
else
  avertir "LibreWolf absent des dépôts : installation via Flathub"
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

# Cache des paquets : on ne garde que la dernière version de chacun (les
# instantanés Btrfs permettent déjà de revenir en arrière). Évite de remplir
# les petits disques.
if command -v paccache >/dev/null; then
  sudo paccache -qrk1 || true
  sudo paccache -qruk0 || true
fi
