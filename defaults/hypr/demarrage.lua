-- Géré par Foyer. Programmes lancés à l'ouverture de session.
hl.on("hyprland.start", function()
	-- Fond d'écran (remplaçable : ~/.config/foyer/fond.jpg)
	hl.exec_cmd("uwsm app -s b -- swaybg -m fill -i " .. os.getenv("HOME") .. "/.config/foyer/fond.jpg")
	hl.exec_cmd("uwsm app -s b -t service -- mako")
	hl.exec_cmd("uwsm app -s b -t service -- hypridle")
	hl.exec_cmd("uwsm app -s b -- udiskie --no-tray")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	-- Curseur identique dans les applications GTK
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
	-- Historique du presse-papier : vidé à chaque ouverture de session, puis enregistré
	hl.exec_cmd("sh -c 'cliphist wipe; exec uwsm app -s b -- wl-paste --watch cliphist store'")
end)
