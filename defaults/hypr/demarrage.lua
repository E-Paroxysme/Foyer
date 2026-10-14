-- Géré par Foyer. Programmes lancés à l'ouverture de session.
hl.on("hyprland.start", function()
	-- Fond d'écran (remplaçable : ~/.config/foyer/fond.jpg)
	hl.exec_cmd("uwsm app -s b -- swaybg -m fill -i " .. os.getenv("HOME") .. "/.config/foyer/fond.jpg")
	-- Extensions Hyprland (barres de titre) : chargées si elles sont compilées pour cette version
	hl.exec_cmd("hyprpm reload -n")
	-- Hub Foyer (Quickshell)
	hl.exec_cmd("uwsm app -s b -- qs -c foyer")
	-- Notifications : gérées par la pastille du hub (mako ne démarre qu'en secours)
	hl.exec_cmd("uwsm app -s b -t service -- hypridle")
	hl.exec_cmd("uwsm app -s b -- udiskie --no-tray")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	-- Thème des applications GTK (police, accent, curseur, boutons des fenêtres)
	hl.exec_cmd("sh " .. os.getenv("HOME") .. "/.config/foyer/session-theme.sh")
	-- Historique du presse-papier : vidé à chaque ouverture de session, puis enregistré
	hl.exec_cmd("sh -c 'cliphist wipe; exec uwsm app -s b -- wl-paste --watch cliphist store'")
end)
