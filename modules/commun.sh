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
  info "Vérification de la connexion Internet…"
  if ! timeout 10 ping -c1 -W3 archlinux.org >/dev/null 2>&1; then
    if timeout 5 ping -c1 -W3 9.9.9.9 >/dev/null 2>&1; then
      erreur "Internet répond, mais pas la résolution des noms (DNS). Voir « DNS chiffré » dans le README."
    fi
    erreur "Pas de connexion Internet. Connecte-toi avec : nmtui"
  fi
  info "Droits administrateur (mot de passe de ton utilisateur)…"
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

flatpak_installer() {
  local id
  for id in "$@"; do
    if flatpak info "$id" >/dev/null 2>&1; then
      info "$id déjà installé"
    else
      info "Flatpak : $id (le premier peut télécharger un socle de plusieurs centaines de Mo)"
      sudo flatpak install -y --noninteractive flathub "$id" \
        || avertir "Flatpak introuvable ou en échec : $id"
    fi
  done
}

aur_installer() {
  [[ $# -eq 0 ]] && return 0
  yay -S --needed --noconfirm "$@" || avertir "Certains paquets AUR n'ont pas pu être installés : $*"
}

# Installe une liste mixte : « paquet », « aur:paquet », « flatpak:id ».
installer_liste() {
  local fichier="$1" ligne p_pacman=() p_aur=() p_flatpak=()
  while read -r ligne; do
    case "$ligne" in
      aur:*)     p_aur+=("${ligne#aur:}") ;;
      flatpak:*) p_flatpak+=("${ligne#flatpak:}") ;;
      *)         p_pacman+=("$ligne") ;;
    esac
  done < <(lire_liste "$fichier")
  pacman_installer "${p_pacman[@]}"
  aur_installer "${p_aur[@]}"
  flatpak_installer "${p_flatpak[@]}"
}

# Description d'un groupe (1re ligne « # Description: … »).
description_groupe() {
  sed -n 's/^# Description: //p' "$1" | head -1
}

# Barre de progression : barre <pourcentage> <texte>
barre() {
  local pct="$1" texte="$2" i b=""
  for ((i = 0; i < 20; i++)); do
    if ((i < pct / 5)); then b+="█"; else b+="░"; fi
  done
  printf '\n\033[1;37m[%s] %3d %%  %s\033[0m\n' "$b" "$pct" "$texte"
}

# Installe un fichier de config « géré par Foyer » (écrasé à chaque mise à jour).
# Écriture atomique (copie temporaire puis renommage) et seulement si le contenu
# change : Hyprland relit sa config dès qu'un fichier bouge, et ne doit jamais
# tomber sur un fichier absent ou à moitié écrit.
deposer() {
  local source="$1" cible="$2" tmp
  mkdir -p "$(dirname "$cible")"
  cmp -s "$source" "$cible" && return 0
  tmp="$(mktemp "$(dirname "$cible")/.foyer.XXXXXX")"
  cp "$source" "$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$cible"
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
