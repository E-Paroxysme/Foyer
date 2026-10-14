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
