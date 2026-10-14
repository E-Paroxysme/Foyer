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
	},
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
	-- Pas de seconde barre pour les applis qui dessinent déjà la leur.
	pcall(hl.window_rule, {
		name = "foyer-sans-barre",
		match = { class = "^(org\\.gnome\\..*|librewolf|LibreWolf|firefox|io\\.gitlab\\.librewolf-community|com\\.mitchellh\\.ghostty)$" },
		["hyprbars:no_bar"] = true,
	})
	pcall(hl.window_rule, {
		name = "foyer-sans-barre-flottantes",
		match = { float = true, title = "^$" },
		["hyprbars:no_bar"] = true,
	})
end
