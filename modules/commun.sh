#!/usr/bin/env bash
# Fonctions partagées par tous les modules. Ce fichier est « sourcé », pas exécuté.
# shellcheck disable=SC2034

FOYER_DIR="${FOYER_DIR:-$HOME/.local/share/foyer}"
FOYER_ETAT="${XDG_STATE_HOME:-$HOME/.local/state}/foyer"
FOYER_JOURNAL="$FOYER_ETAT/journal.log"
FOYER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$FOYER_ETAT"

_ecrire() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$FOYER_JOURNAL"; }
etape()   { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; _ecrire "== $*"; }
info()    { printf '\033[1;34m  -> %s\033[0m\n' "$*"; _ecrire "   $*"; }
avertir() { printf '\033[1;33m  !! %s\033[0m\n' "$*"; _ecrire "!! $*"; }
succes()  { printf '\n\033[1;32m%s\033[0m\n' "$*"; _ecrire "OK $*"; }
erreur()  { printf '\033[1;31m  XX %s\033[0m\n' "$*" >&2; _ecrire "XX $*"; exit 1; }

verifier_prerequis() {
  [[ $EUID -eq 0 ]] && erreur "Lance Foyer avec ton utilisateur, pas en root."
  [[ -f /etc/arch-release ]] || erreur "Foyer est prévu pour Arch Linux."
  ping -c1 -W3 archlinux.org >/dev/null 2>&1 || erreur "Pas de connexion Internet (connecte-toi avec : nmtui)."
  sudo -v || erreur "sudo est nécessaire."
}

# Lit une liste de paquets : un par ligne, « # » pour les commentaires.
lire_liste() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Installe des paquets des dépôts Arch. Un nom inconnu ne bloque pas les autres :
# il est signalé dans le journal et ignoré.
pacman_installer() {
  [[ $# -eq 0 ]] && return 0
  local p valides=()
  for p in "$@"; do
    if pacman -Si "$p" >/dev/null 2>&1 || pacman -Sg "$p" >/dev/null 2>&1; then
      valides+=("$p")
    else
      avertir "Paquet introuvable dans les dépôts, ignoré : $p"
    fi
  done
  [[ ${#valides[@]} -eq 0 ]] && return 0
  sudo pacman -S --needed --noconfirm "${valides[@]}"
}

# Installe un fichier de config « géré par Foyer » (écrasé à chaque mise à jour).
deposer() {
  local source="$1" cible="$2"
  mkdir -p "$(dirname "$cible")"
  install -m 644 "$source" "$cible"
}

# Écrit un fichier système seulement si son contenu change.
ecrire_systeme() {
  local cible="$1" contenu
  contenu="$(cat)"
  if [[ ! -f "$cible" ]] || [[ "$(sudo cat "$cible")" != "$contenu" ]]; then
    sudo mkdir -p "$(dirname "$cible")"
    printf '%s\n' "$contenu" | sudo tee "$cible" >/dev/null
    return 0
  fi
  return 1
}

activer_service() {
  sudo systemctl enable "$@" >/dev/null 2>&1 || avertir "Impossible d'activer : $*"
}
