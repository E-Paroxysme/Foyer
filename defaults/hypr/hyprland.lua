-- Géré par Foyer : ce fichier est remplacé à chaque mise à jour.
-- Tes réglages personnels : ~/.config/foyer/perso.lua (chargé en dernier, il a le dernier mot).

local home = os.getenv("HOME")

-- Variables d'environnement de la session
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.config({
	general = {
		layout = "dwindle",
		resize_on_border = true,
	},
	dwindle = {
		preserve_split = true,
	},
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
	ecosystem = {
		no_update_news = true,
	},
})

require("ecrans")
require("entrees")
require("apparence")
-- Couleurs, bordures et arrondis du thème (produit par « foyer theme »)
pcall(require, "theme")
-- Réglages faits dans le hub (souris, pavé tactile, taille de l'affichage)
pcall(require, "reglages")
require("raccourcis")
require("demarrage")

-- Réglages liés au matériel (écrit par Foyer selon la carte graphique)
pcall(require, "materiel")

-- Réglages personnels : jamais écrasés par les mises à jour
local perso = home .. "/.config/foyer/perso.lua"
local f = io.open(perso, "r")
if f then
	f:close()
	dofile(perso)
end
