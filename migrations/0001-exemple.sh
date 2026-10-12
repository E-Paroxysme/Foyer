#!/usr/bin/env bash
# Migration d'exemple. Chaque fichier de ce dossier est exécuté UNE seule fois
# par machine, dans l'ordre des numéros, lors de « foyer install » ou « foyer update ».
# Sert à ce qu'un simple « git pull » ne sait pas faire : installer ou retirer
# un paquet, activer un service, supprimer un ancien fichier…
set -euo pipefail
echo "  -> Migration 0001 : rien à faire (exemple)."
