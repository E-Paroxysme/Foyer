#!/usr/bin/env bash
# shellcheck disable=SC2088
# Thème : un seul fichier décide des couleurs, de la police, des arrondis et des
# animations de tout le bureau (hub, pastille, fenêtres, terminal, lanceur,
# écran de verrouillage, applications GTK).
#   Thème par défaut : defaults/foyer/theme.json (géré par Foyer)
#   Tes réglages     : ~/.config/foyer/theme.json (jamais écrasé ; seules les
#                      valeurs que tu y mets remplacent celles par défaut)
# Relancer après une modification : foyer theme
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

D="$FOYER_DIR/defaults"
M="$D/modeles"
perso="$FOYER_CONFIG/foyer/theme.json"
final="$FOYER_CONFIG/quickshell/foyer/theme.json"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/foyer"
mkdir -p "$FOYER_CONFIG/foyer" "$FOYER_CONFIG/quickshell/foyer" "$cache"

if [[ ! -f "$perso" ]]; then
  cat >"$perso" <<'EOF'
{
  "description": "Tes réglages de thème. Choisis un thème avec « foyer theme <nom> » (liste : foyer theme liste). Pour aller plus loin, ajoute ici seulement ce que tu veux changer, avec les mêmes noms que dans ~/.local/share/foyer/defaults/foyer/theme.json, puis lance : foyer theme. Exemple : \"couleurs\": { \"accent\": \"#5aa0e8\" }",
  "base": "braise"
}
EOF
  info "Fichier de thème personnel créé : ~/.config/foyer/theme.json"
fi

# Thème de base choisi (« foyer theme <nom> ») : braise si rien n'est indiqué.
base="$(jq -r '.base // "braise"' "$perso" 2>/dev/null || echo braise)"
[[ -f "$D/themes/$base.json" ]] || { avertir "Thème « $base » inconnu : braise utilisé."; base=braise; }
info "Thème : $base, avec tes réglages personnels"
tmp="$(mktemp)"
if ! jq -s '.[0] * .[1] * .[2]' "$D/foyer/theme.json" "$D/themes/$base.json" "$perso" >"$tmp" 2>/dev/null; then
  avertir "Le fichier ~/.config/foyer/theme.json est illisible (virgule oubliée ?) : thème par défaut utilisé."
  jq -s '.[0] * .[1]' "$D/foyer/theme.json" "$D/themes/$base.json" >"$tmp"
fi
deposer "$tmp" "$final"
rm -f "$tmp"

# --- Valeurs pour les modèles : « chemin.de.la.cle<TAB>valeur » ---------------
valeurs="$(mktemp)"
jq -r 'paths(scalars) as $p | "\($p | map(tostring) | join("."))\t\(getpath($p))"' "$final" \
  | awk -F'\t' '{ print; if ($2 ~ /^#[0-9a-fA-F]{6}$/) print $1 ".nu\t" substr($2, 2) }' >"$valeurs"

profil="$(cat "$FOYER_CONFIG/foyer/profil-graphique" 2>/dev/null || echo normal)"
if [[ "$profil" == "eco" ]]; then
  printf 'eco.barres\t12\neco.images\t20\n' >>"$valeurs"
else
  printf 'eco.barres\t24\neco.images\t30\n' >>"$valeurs"
fi
utilisateur="${USER:-$(id -un)}"
nom="$(jq -r '.compte.nom // ""' "$FOYER_CONFIG/foyer/reglages.json" 2>/dev/null || true)"
[[ -n "$nom" ]] || nom="$(getent passwd "$utilisateur" | cut -d: -f5 | cut -d, -f1)"
printf 'verrou.nom\t%s\nverrou.image\t%s\n' "${nom:-$utilisateur}" "$cache/verrou.png" >>"$valeurs"

# --- Icônes des dossiers aux couleurs du thème --------------------------------
# Petit thème d'icônes « Foyer » dans ~/.local/share/icons : il ne contient que
# les dossiers (pris dans Papirus, dans la couleur du thème) et laisse tout le
# reste à Adwaita, pour garder les icônes officielles des applications.
icones_dossiers() {
  local papirus="${FOYER_PAPIRUS:-/usr/share/icons/Papirus}" couleur dest taille f nom n
  couleur="$(jq -r '.icones.dossiers // "blue"' "$final")"
  dest="${XDG_DATA_HOME:-$HOME/.local/share}/icons/Foyer"
  [[ -d "$papirus" ]] || { avertir "Papirus absent : icônes de dossiers par défaut."; return 1; }
  [[ -e "$papirus/64x64/places/folder-$couleur.svg" ]] || { avertir "Couleur de dossiers inconnue : $couleur."; return 1; }
  rm -rf "$dest"; mkdir -p "$dest"
  local dossiers=()
  for taille in 16 22 24 32 48 64; do
    [[ -d "$papirus/${taille}x${taille}/places" ]] || continue
    mkdir -p "$dest/${taille}x${taille}/places"
    dossiers+=("${taille}x${taille}/places")
    # folder-<couleur>-documents.svg → folder-documents.svg, user-<couleur>-home.svg → user-home.svg…
    for f in "$papirus/${taille}x${taille}/places"/{folder,user}-"$couleur"{,-*}.svg; do
      [[ -e "$f" ]] || continue
      nom="$(basename "$f")"; nom="${nom/-$couleur/}"
      ln -sf "$f" "$dest/${taille}x${taille}/places/$nom"
    done
    # Alias de Papirus (inode-directory.svg → folder.svg…) qui pointent vers nos dossiers.
    for f in "$papirus/${taille}x${taille}/places"/*.svg; do
      [[ -L "$f" ]] || continue
      nom="$(basename "$f")"; n="$(readlink "$f")"
      [[ "$n" != */* && ! -e "$dest/${taille}x${taille}/places/$nom" && -e "$dest/${taille}x${taille}/places/$n" ]] \
        && ln -s "$n" "$dest/${taille}x${taille}/places/$nom"
    done
  done
  {
    echo "[Icon Theme]"
    echo "Name=Foyer"
    echo "Comment=Dossiers aux couleurs du thème Foyer (généré par « foyer theme »)"
    echo "Inherits=Adwaita,hicolor"
    echo "Directories=$(IFS=,; echo "${dossiers[*]}")"
    for f in "${dossiers[@]}"; do
      taille="${f%%x*}"
      echo; echo "[$f]"; echo "Context=Places"; echo "Size=$taille"
      if [[ "$taille" == 64 ]]; then echo "Type=Scalable"; echo "MinSize=64"; echo "MaxSize=512"; else echo "Type=Fixed"; fi
    done
  } >"$dest/index.theme"
  info "Thème : dossiers $couleur"
}
if icones_dossiers; then
  printf 'icones.theme\tFoyer\n' >>"$valeurs"
else
  printf 'icones.theme\tAdwaita\n' >>"$valeurs"
fi

valeur() { awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$valeurs"; }

# Remplace chaque @@cle@@ d'un modèle par sa valeur, et dépose le résultat.
rendre() {
  local modele="$1" cible="$2" sortie
  sortie="$(mktemp)"
  awk -F'\t' '
    NR == FNR { v[$1] = $2; next }
    {
      ligne = $0; res = ""
      while (match(ligne, /@@[^@]+@@/)) {
        cle = substr(ligne, RSTART + 2, RLENGTH - 4)
        res = res substr(ligne, 1, RSTART - 1) ((cle in v) ? v[cle] : "")
        ligne = substr(ligne, RSTART + RLENGTH)
      }
      print res ligne
    }' "$valeurs" "$modele" >"$sortie"
  deposer "$sortie" "$cible"
  rm -f "$sortie"
}

info "Thème : fenêtres, terminal, lanceur, notifications de secours, égaliseur"
rendre "$M/theme.lua"      "$FOYER_CONFIG/hypr/theme.lua"
rendre "$M/foot.ini"       "$FOYER_CONFIG/foot/foot.ini"
rendre "$M/fuzzel.ini"     "$FOYER_CONFIG/fuzzel/fuzzel.ini"
rendre "$M/mako.conf"      "$FOYER_CONFIG/mako/config"
rendre "$M/cava.conf"      "$FOYER_CONFIG/foyer/cava.conf"
rendre "$M/hyprlock.conf"  "$FOYER_CONFIG/hypr/hyprlock.conf"
rendre "$M/session.sh"     "$FOYER_CONFIG/foyer/session-theme.sh"

# --- Image de l'écran de verrouillage -----------------------------------------
# Fond d'écran + icône du compte au centre ; la moitié droite est floutée (verre).
# Refaite seulement si le fond, l'icône ou la couleur ont changé.
generer_verrou() {
  local magick=magick
  command -v magick >/dev/null || magick=convert
  command -v "$magick" >/dev/null || { avertir "ImageMagick absent : écran de verrouillage sans image."; return 0; }
  local fond="$FOYER_CONFIG/foyer/fond.jpg" face="$HOME/.face" accent panneau empreinte
  [[ -f "$fond" ]] || return 0
  accent="$(valeur couleurs.accent)"; panneau="$(valeur couleurs.panneau)"
  empreinte="$( { sha256sum "$fond"; [[ -f "$face" ]] && sha256sum "$face"; echo "$accent $panneau v1"; } | sha256sum | cut -c1-16)"
  [[ -f "$cache/verrou.png" && "$(cat "$cache/verrou.empreinte" 2>/dev/null)" == "$empreinte" ]] && return 0

  info "Thème : image de l'écran de verrouillage"
  local w=1920 h=1080 r=210 t
  t="$(mktemp -d)"
  "$magick" "$fond" -resize "${w}x${h}^" -gravity center -extent "${w}x${h}" "$t/base.png"
  if [[ -f "$face" ]]; then
    "$magick" "$face" -resize "$((2 * r))x$((2 * r))^" -gravity center -extent "$((2 * r))x$((2 * r))" \
      \( -size "$((2 * r))x$((2 * r))" xc:black -fill white -draw "circle $r,$r $r,0" \) \
      -alpha off -compose CopyOpacity -composite "$t/icone.png"
  else
    "$magick" -size "$((2 * r))x$((2 * r))" xc:none -fill "$accent" -draw "circle $r,$r $r,0" "$t/icone.png"
  fi
  "$magick" "$t/base.png" "$t/icone.png" -gravity center -compose over -composite "$t/avec.png"
  "$magick" "$t/avec.png" -crop "$((w / 2))x${h}+$((w / 2))+0" +repage -blur 0x30 \
    -fill "$panneau" -colorize 28 "$t/droite.png"
  "$magick" "$t/avec.png" -fill black -colorize 18 \
    "$t/droite.png" -geometry "+$((w / 2))+0" -compose over -composite \
    -fill "rgba(255,255,255,0.14)" -draw "line $((w / 2)),0 $((w / 2)),$h" \
    "$cache/verrou.png"
  echo "$empreinte" >"$cache/verrou.empreinte"
  rm -rf "$t"
}
generer_verrou || avertir "Image de l'écran de verrouillage non générée (voir le journal)."

# Applications GTK : appliqué tout de suite si une session est ouverte.
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  sh "$FOYER_CONFIG/foyer/session-theme.sh" >/dev/null 2>&1 || true
  command -v makoctl >/dev/null && makoctl reload >/dev/null 2>&1 || true
fi
rm -f "$valeurs"
