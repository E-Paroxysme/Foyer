#!/usr/bin/env bash
# Configuration du bureau : Hyprland, verrouillage, lanceur, notifications, terminal.
# Les fichiers marqués « géré par Foyer » sont remplacés à chaque mise à jour.
# Tes réglages personnels vont dans ~/.config/foyer/perso.lua : jamais écrasé.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

D="$FOYER_DIR/defaults"

info "Dossiers personnels (Documents, Images, Téléchargements…)"
LANG=fr_FR.UTF-8 xdg-user-dirs-update 2>/dev/null || xdg-user-dirs-update || true

info "Configuration Hyprland"
for f in "$D"/hypr/*; do
  deposer "$f" "$FOYER_CONFIG/hypr/$(basename "$f")"
done

# Profil graphique écrit par le module pilotes.
profil="$(cat "$FOYER_CONFIG/foyer/profil-graphique" 2>/dev/null || echo normal)"
if [[ "$profil" == "eco" ]]; then
  info "Profil « eco » : flou et ombres désactivés, animations allégées"
  cat >"$FOYER_CONFIG/hypr/materiel.lua" <<'EOF'
-- Géré par Foyer (profil graphique « eco », carte graphique ancienne)
hl.config({
	decoration = {
		blur = { enabled = false },
		shadow = { enabled = false },
	},
	animations = { enabled = false },
})
EOF
else
  printf -- '-- Géré par Foyer (profil graphique « normal »)\n' >"$FOYER_CONFIG/hypr/materiel.lua"
fi

# Fichier personnel : créé une seule fois, jamais remplacé.
if [[ ! -f "$FOYER_CONFIG/foyer/perso.lua" ]]; then
  deposer "$D/foyer/perso.lua" "$FOYER_CONFIG/foyer/perso.lua"
  info "Fichier personnel créé : ~/.config/foyer/perso.lua"
fi

info "Lanceur temporaire (fuzzel), notifications temporaires (mako), terminal (foot)"
deposer "$D/fuzzel/fuzzel.ini" "$FOYER_CONFIG/fuzzel/fuzzel.ini"
deposer "$D/mako/config"       "$FOYER_CONFIG/mako/config"
deposer "$D/foot/foot.ini"     "$FOYER_CONFIG/foot/foot.ini"

info "Démarrage automatique de Hyprland après connexion sur le terminal 1"
profil_bash="$HOME/.bash_profile"
touch "$profil_bash"
if ! grep -q 'foyer: session' "$profil_bash"; then
  cat >>"$profil_bash" <<'EOF'

# foyer: session — lance Hyprland (via uwsm) après connexion sur tty1
if uwsm check may-start >/dev/null 2>&1; then
  exec uwsm start hyprland-uwsm.desktop
fi
EOF
fi
