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
materiel="$(mktemp)"
if [[ "$profil" == "eco" ]]; then
  info "Profil « eco » : flou et ombres désactivés, animations allégées"
  cat >"$materiel" <<'EOF2'
-- Géré par Foyer (profil graphique « eco », carte graphique ancienne)
hl.config({
	decoration = {
		blur = { enabled = false },
		shadow = { enabled = false },
	},
	animations = { enabled = false },
})
EOF2
else
  printf -- '-- Géré par Foyer (profil graphique « normal »)\n' >"$materiel"
fi
deposer "$materiel" "$FOYER_CONFIG/hypr/materiel.lua"
rm -f "$materiel"

# Fichier personnel : créé une seule fois, jamais remplacé.
if [[ ! -f "$FOYER_CONFIG/foyer/perso.lua" ]]; then
  deposer "$D/foyer/perso.lua" "$FOYER_CONFIG/foyer/perso.lua"
  info "Fichier personnel créé : ~/.config/foyer/perso.lua"
fi

info "Hub Foyer (Quickshell)"
for f in "$D"/quickshell/foyer/*; do
  deposer "$f" "$FOYER_CONFIG/quickshell/foyer/$(basename "$f")"
done
# Tuiles : copiées une seule fois, ensuite le fichier t'appartient.
if [[ ! -f "$FOYER_CONFIG/foyer/tuiles.json" ]]; then
  deposer "$D/foyer/tuiles.json" "$FOYER_CONFIG/foyer/tuiles.json"
  info "Tuiles par défaut : ~/.config/foyer/tuiles.json"
fi


# Fond d'écran : copié une seule fois, remplace ~/.config/foyer/fond.jpg par le tien.
if [[ ! -f "$FOYER_CONFIG/foyer/fond.jpg" ]]; then
  deposer "$D/fonds/braise.jpg" "$FOYER_CONFIG/foyer/fond.jpg"
  info "Fond d'écran par défaut : ~/.config/foyer/fond.jpg"
fi

# Dans la session graphique : (re)lance le hub et le fond d'écran pour appliquer
# la nouvelle version tout de suite, sans attendre la prochaine connexion.
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  pkill -x qs 2>/dev/null || true
  (setsid uwsm app -s b -- qs -c foyer >/dev/null 2>&1 &) || true
  pkill -x swaybg 2>/dev/null || true
  (setsid uwsm app -s b -- swaybg -m fill -i "$FOYER_CONFIG/foyer/fond.jpg" >/dev/null 2>&1 &) || true
  info "Hub et fond d'écran (re)lancés"
fi

info "Lanceur de secours (fuzzel), notifications temporaires (mako), terminal (foot)"
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
