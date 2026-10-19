-- Géré par Foyer : produit par « foyer theme » à partir du thème (ne pas modifier).
hl.config({
	general = {
		gaps_in = @@fenetres.espaceInterieur@@,
		gaps_out = @@fenetres.espaceExterieur@@,
		border_size = @@fenetres.bordure@@,
		col = {
			-- Couleur unie : la syntaxe des dégradés n'est pas acceptée telle quelle par la config Lua.
			active_border = "rgb(@@couleurs.accent.nu@@)",
			inactive_border = "rgba(ffffff1a)",
		},
	},
	decoration = {
		rounding = @@arrondis.fenetre@@,
		-- Flou « verre dépoli » plus vif, comme sur les maquettes (saturate).
		blur = {
			size = 8,
			passes = 3,
			vibrancy = 0.35,
			vibrancy_darkness = 0.2,
		},
	},
})

-- Le hub et la pastille floutent ce qui est derrière eux (le profil économe coupe
-- le flou partout). ignore_alpha : seules les parties presque opaques sont floutées.
pcall(hl.layer_rule, {
	name = "foyer-verre",
	match = { namespace = "^foyer-(hub|pastille)$" },
	blur = true,
	ignore_alpha = 0.3,
})

-- Barres de titre (extension hyprbars) : réduire, agrandir, fermer pour toutes les
-- fenêtres. Rien ne se passe si l'extension n'est pas chargée (Hyprland démarre
-- alors normalement, simplement sans barres).
if hl.plugin and hl.plugin.hyprbars then
	pcall(function()
		hl.config({
			plugin = {
				hyprbars = {
					bar_height = 30,
					bar_color = "rgb(@@couleurs.panneau.nu@@)",
					["col.text"] = "rgb(@@couleurs.texte.nu@@)",
					bar_text_font = "@@police.interface@@",
					bar_text_size = 10,
					bar_text_weight = "medium",
					bar_text_align = "center",
					bar_padding = 12,
					bar_button_padding = 8,
					bar_precedence_over_border = true,
					bar_part_of_window = true,
					icon_on_hover = true,
					inactive_button_color = "rgba(ffffff1a)",
					on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
				},
			},
		})
		-- Boutons de droite à gauche : fermer, agrandir, réduire.
		hl.plugin.hyprbars.add_button({
			bg_color = "rgb(@@couleurs.accent.nu@@)", fg_color = "rgb(@@couleurs.panneau.nu@@)",
			size = 14, icon = "×",
			action = [[hyprctl dispatch 'hl.dsp.window.close()']],
		})
		hl.plugin.hyprbars.add_button({
			bg_color = "rgba(ffffff33)", fg_color = "rgb(@@couleurs.texte.nu@@)",
			size = 14, icon = "+",
			action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
		})
		hl.plugin.hyprbars.add_button({
			bg_color = "rgba(ffffff33)", fg_color = "rgb(@@couleurs.texte.nu@@)",
			size = 14, icon = "−",
			-- Réduire : la fenêtre part sur un bureau caché ; le hub la ramène.
			action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:reduites", follow = false })']],
		})
	end)
	-- Pas de barre Foyer pour les applications qui dessinent déjà la leur (boutons
	-- dans leur en-tête : applis GNOME/libadwaita…). Hyprland ne peut pas le
	-- détecter tout seul, d'où cette liste. Pour en ajouter : une classe par ligne
	-- dans ~/.config/foyer/sans-barre.txt (classe visible avec « hyprctl clients »).
	local classes = {
		"org\\.gnome\\..*", "com\\.mitchellh\\.ghostty", "com\\.github\\.tchx84\\.Flatseal",
		"fr\\.romainvigier\\.MetadataCleaner", "io\\.github\\..*", "io\\.missioncenter\\..*",
	}
	local ok, perso = pcall(function() return io.open(os.getenv("HOME") .. "/.config/foyer/sans-barre.txt", "r") end)
	if ok and perso then
		for ligne in perso:lines() do
			ligne = ligne:gsub("#.*", ""):gsub("^%s+", ""):gsub("%s+$", "")
			if ligne ~= "" then
				table.insert(classes, (ligne:gsub("%.", "\\.")))
			end
		end
		perso:close()
	end
	pcall(hl.window_rule, {
		name = "foyer-sans-barre",
		match = { class = "^(" .. table.concat(classes, "|") .. ")$" },
		["hyprbars:no_bar"] = true,
	})
	pcall(hl.window_rule, {
		name = "foyer-sans-barre-flottantes",
		match = { float = true, title = "^$" },
		["hyprbars:no_bar"] = true,
	})
end
