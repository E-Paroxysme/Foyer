#!/usr/bin/env bash
# Foyer — script d'amorçage.
# Usage, sur une Arch fraîchement installée, connecté en utilisateur (pas root) :
#   curl -fsSL https://raw.githubusercontent.com/E-Paroxysme/Foyer/main/install.sh | bash
# Variables optionnelles :
#   FOYER_DEPOT   URL du dépôt Git (défaut : celle ci-dessous)
#   FOYER_BRANCHE branche à utiliser (défaut : main)
set -euo pipefail

FOYER_DEPOT="${FOYER_DEPOT:-https://github.com/E-Paroxysme/Foyer.git}"
FOYER_BRANCHE="${FOYER_BRANCHE:-main}"
FOYER_DIR="${FOYER_DIR:-$HOME/.local/share/foyer}"

erreur() { printf '\033[1;31m[foyer] %s\033[0m\n' "$*" >&2; exit 1; }
info()   { printf '\033[1;34m[foyer] %s\033[0m\n' "$*"; }

[[ $EUID -eq 0 ]] && erreur "Lance ce script avec ton utilisateur, pas en root."
[[ -f /etc/arch-release ]] || erreur "Ce script est prévu pour Arch Linux."

if ! command -v git >/dev/null 2>&1; then
  info "Installation de git…"
  sudo pacman -S --needed --noconfirm git
fi

if [[ -d "$FOYER_DIR/.git" ]]; then
  info "Dépôt déjà présent, mise à jour…"
  git -C "$FOYER_DIR" fetch --quiet origin "$FOYER_BRANCHE"
  git -C "$FOYER_DIR" checkout --quiet -B "$FOYER_BRANCHE" "origin/$FOYER_BRANCHE"
  git -C "$FOYER_DIR" reset --quiet --hard "origin/$FOYER_BRANCHE"
else
  info "Récupération de Foyer dans $FOYER_DIR…"
  mkdir -p "$(dirname "$FOYER_DIR")"
  git clone --branch "$FOYER_BRANCHE" "$FOYER_DEPOT" "$FOYER_DIR"
fi

# Un dépôt envoyé par l'interface web de GitHub perd les droits d'exécution :
# on les remet, et on dit à Git de ne pas considérer ça comme une modification.
git -C "$FOYER_DIR" config core.fileMode false
chmod +x "$FOYER_DIR/install.sh" "$FOYER_DIR/bin/foyer" "$FOYER_DIR"/modules/*.sh

# Le script est souvent lancé via « curl | bash » : on rattache le clavier
# pour que sudo puisse demander le mot de passe.
exec bash "$FOYER_DIR/bin/foyer" install </dev/tty
