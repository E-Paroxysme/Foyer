#!/bin/sh
# Géré par Foyer : produit par « foyer theme », lancé à l'ouverture de session.
# Applique le thème aux applications GTK (Fichiers, visionneuses…).
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface accent-color '@@gtk.accent@@' 2>/dev/null
gsettings set org.gnome.desktop.interface font-name '@@police.interface@@ @@police.taille@@'
gsettings set org.gnome.desktop.interface monospace-font-name '@@police.mono@@ @@police.taille@@'
# Icônes (aller-retour pour que les fenêtres ouvertes relisent les dossiers).
gsettings set org.gnome.desktop.interface icon-theme Adwaita
gsettings set org.gnome.desktop.interface icon-theme '@@icones.theme@@'
gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice
gsettings set org.gnome.desktop.interface cursor-size 24
# Boutons réduire, agrandir et fermer sur les fenêtres GNOME
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
