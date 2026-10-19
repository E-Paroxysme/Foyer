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
# Bloc « machine virtuelle » dans ~/.config/uwsm/env (variables de toute la
# session). Sans argument : retire le bloc. Le reste du fichier est conservé.
bloc_vm() {
  local f="$FOYER_CONFIG/uwsm/env"
  mkdir -p "$(dirname "$f")"
  touch "$f"
  sed -i '/# Foyer : machine virtuelle (début)/,/# Foyer : machine virtuelle (fin)/d' "$f"
  if (( $# > 0 )); then
    { echo "# Foyer : machine virtuelle (début)"; printf '%s\n' "$@"; echo "# Foyer : machine virtuelle (fin)"; } >>"$f"
  fi
}
# Machine virtuelle (VMware, QEMU, VirtualBox…) : le curseur matériel s'y affiche mal.
if command -v systemd-detect-virt >/dev/null && systemd-detect-virt -q --vm; then
  info "Machine virtuelle détectée ($(systemd-detect-virt --vm)) : curseur logiciel"
  printf -- '-- Machine virtuelle : curseur dessiné par Hyprland\nhl.config({ cursor = { no_hardware_cursors = true } })\n' >>"$materiel"
  # Le pilote graphique virtuel (VMware notamment) fait planter Quickshell :
  # le hub dessine alors sans la carte graphique.
  # VMware : outils invités (l'écran suit la taille de la fenêtre, texte net).
  if [[ "$(systemd-detect-virt --vm)" == "vmware" ]]; then
    pacman_installer open-vm-tools || avertir "open-vm-tools non installé."
    activer_service vmtoolsd.service
  fi
  mkdir -p "$FOYER_CONFIG/foyer"
  printf '# Géré par Foyer (machine virtuelle détectée).\nQT_QUICK_BACKEND=software\n' >"$FOYER_CONFIG/foyer/hub.env"
  # Applis GTK 4 (Flatseal, Fichiers…) et WebKit : même souci avec le pilote
  # virtuel (« Lost connection to Wayland compositor »). Rendu sans carte
  # graphique pour toute la session (pris en compte à la prochaine connexion)
  # et pour les applis Flatpak.
  info "Machine virtuelle : applications GTK 4 dessinées sans la carte graphique"
  bloc_vm 'export GSK_RENDERER=cairo' 'export WEBKIT_DISABLE_DMABUF_RENDERER=1'
  if command -v flatpak >/dev/null; then
    flatpak override --user --env=GSK_RENDERER=cairo --env=WEBKIT_DISABLE_DMABUF_RENDERER=1 2>/dev/null || true
  fi
else
  if grep -q 'machine virtuelle' "$FOYER_CONFIG/foyer/hub.env" 2>/dev/null; then
    rm -f "$FOYER_CONFIG/foyer/hub.env"
  fi
  if grep -q '# Foyer : machine virtuelle' "$FOYER_CONFIG/uwsm/env" 2>/dev/null; then
    bloc_vm
    command -v flatpak >/dev/null && flatpak override --user --unset-env=GSK_RENDERER --unset-env=WEBKIT_DISABLE_DMABUF_RENDERER 2>/dev/null || true
  fi
fi
deposer "$materiel" "$FOYER_CONFIG/hypr/materiel.lua"
# Réglages faits dans le hub (veille, souris, écran) : réécrits par-dessus les fichiers par défaut.
"$FOYER_DIR/bin/foyer-reglages" appliquer || avertir "Réglages du hub non appliqués."
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
# Disposition du hub (en-tête, bureaux, widgets) : copiée une seule fois.
if [[ ! -f "$FOYER_CONFIG/foyer/disposition.json" ]]; then
  deposer "$D/foyer/disposition.json" "$FOYER_CONFIG/foyer/disposition.json"
  info "Disposition du hub : ~/.config/foyer/disposition.json"
fi
# Tuiles : copiées une seule fois, ensuite le fichier t'appartient.
if [[ ! -f "$FOYER_CONFIG/foyer/tuiles.json" ]]; then
  deposer "$D/foyer/tuiles.json" "$FOYER_CONFIG/foyer/tuiles.json"
  info "Tuiles par défaut : ~/.config/foyer/tuiles.json"
fi


# LibreWolf : barre de titre du système (boutons Foyer, réduire compris) au lieu
# de ses boutons dans la barre d'onglets, que Hyprland grise. Ligne ajoutée une
# fois dans le fichier de réglages personnels de LibreWolf, sans toucher au reste.
# Emplacements (doc LibreWolf) : ~/.config/librewolf/librewolf/ pour les versions
# récentes (dossiers XDG), ~/.librewolf/ pour les anciens profils, Flatpak à part.
xdg_lw="${XDG_CONFIG_HOME:-$HOME/.config}/librewolf/librewolf"
ancien_lw="$HOME/.librewolf"
# Ancienne version de Foyer : ~/.librewolf créé pour rien (aucun profil dedans).
if [[ -d "$ancien_lw" && ! -e "$ancien_lw/profiles.ini" ]] \
   && [[ -z "$(ls -A "$ancien_lw" | grep -v '^librewolf.overrides.cfg$')" ]]; then
  rm -rf "$ancien_lw"
fi
dossiers_lw=("$xdg_lw")
[[ -e "$ancien_lw/profiles.ini" ]] && dossiers_lw+=("$ancien_lw")
[[ -d "$HOME/.var/app/io.gitlab.librewolf-community" ]] && dossiers_lw+=("$HOME/.var/app/io.gitlab.librewolf-community/.librewolf")
for dossier in "${dossiers_lw[@]}"; do
  mkdir -p "$dossier"
  f="$dossier/librewolf.overrides.cfg"
  # pref() et non defaultPref() : s'impose aussi quand LibreWolf a déjà enregistré
  # une autre valeur dans le profil.
  if grep -q 'browser.tabs.inTitlebar' "$f" 2>/dev/null; then
    sed -i 's/defaultPref("browser.tabs.inTitlebar"/pref("browser.tabs.inTitlebar"/' "$f"
  else
    printf '// Foyer : barre de titre du système (boutons réduire, agrandir, fermer).\npref("browser.tabs.inTitlebar", 0);\n' >>"$f"
  fi
done

# Fond d'écran : copié une seule fois, remplace ~/.config/foyer/fond.jpg par le tien.
if [[ ! -f "$FOYER_CONFIG/foyer/fond.jpg" ]]; then
  deposer "$D/fonds/braise.jpg" "$FOYER_CONFIG/foyer/fond.jpg"
  info "Fond d'écran par défaut : ~/.config/foyer/fond.jpg"
fi

# Dans la session graphique : (re)lance le hub et le fond d'écran pour appliquer
# la nouvelle version tout de suite, sans attendre la prochaine connexion.
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  pkill -x qs 2>/dev/null || true
  # La pastille remplace mako pour les notifications (mako reste en secours).
  pkill -x mako 2>/dev/null || true
  (setsid env -u FOYER_DIR -u FOYER_RELANCE -u FOYER_RELAIS uwsm app -s b -- "$FOYER_DIR/bin/foyer-hub" >/dev/null 2>&1 &) || true
  pkill -x swaybg 2>/dev/null || true
  (setsid env -u FOYER_DIR -u FOYER_RELANCE -u FOYER_RELAIS uwsm app -s b -- swaybg -m fill -i "$FOYER_CONFIG/foyer/fond.jpg" >/dev/null 2>&1 &) || true
  # hypridle ne relit pas sa config tout seul.
  pkill -x hypridle 2>/dev/null || true
  (setsid env -u FOYER_DIR -u FOYER_RELANCE -u FOYER_RELAIS uwsm app -s b -t service -- hypridle >/dev/null 2>&1 &) || true
  info "Hub et fond d'écran (re)lancés"
fi

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
