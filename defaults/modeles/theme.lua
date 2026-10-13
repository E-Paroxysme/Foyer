-- Géré par Foyer : produit par « foyer theme » à partir du thème (ne pas modifier).
hl.config({
	general = {
		gaps_in = @@fenetres.espaceInterieur@@,
		gaps_out = @@fenetres.espaceExterieur@@,
		border_size = @@fenetres.bordure@@,
		col = {
			active_border = "rgb(@@couleurs.accent.nu@@) rgb(@@couleurs.accentClair.nu@@) 45deg",
			inactive_border = "rgba(ffffff1a)",
		},
	},
	decoration = {
		rounding = @@arrondis.fenetre@@,
	},
})
