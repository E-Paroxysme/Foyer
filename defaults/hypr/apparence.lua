-- Géré par Foyer. Apparence par défaut (le futur thème global remplacera ces valeurs).
hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		col = {
			active_border = "rgb(e8875a)", -- braise
			inactive_border = "rgb(3a3a44)",
		},
	},
	decoration = {
		rounding = 10,
		active_opacity = 1.0,
		inactive_opacity = 0.95,
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
		},
		shadow = {
			enabled = true,
			range = 12,
		},
	},
	animations = {
		enabled = true,
	},
})
