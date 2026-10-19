-- Géré par Foyer. Raccourcis de base (clavier AZERTY).
-- Ajoute ou remplace des raccourcis dans ~/.config/foyer/perso.lua.

local terminal = "uwsm app -- foot"
local hub = "qs -c foyer ipc call hub basculer"
local lanceur = "uwsm app -- fuzzel" -- lanceur de secours, si le hub ne répond pas
-- LibreWolf natif s'il est installé (petites configurations), sinon la version Flatpak
local navigateur = "uwsm app -- sh -c 'command -v librewolf >/dev/null && exec librewolf || exec flatpak run io.gitlab.librewolf-community'"
local fichiers = "uwsm app -- nautilus"

-- Super seul (au relâchement) : ouvre ou ferme le hub.
-- Super + Espace : lanceur de secours (fuzzel), utile si le hub ne répond pas.
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(hub), { release = true })
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(lanceur))

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + B", hl.dsp.exec_cmd(navigateur))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fichiers))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

-- Super + P : choix d'affichage pour le vidéoprojecteur (rappuyer pour changer)
hl.bind("SUPER + P", hl.dsp.exec_cmd("qs -c foyer ipc call pastille projection"))
-- Enregistrement de l'écran (dans Vidéos/Enregistrements) : Super + Alt + R pour
-- l'écran entier, Super + Alt + Maj + R pour une zone ; le même raccourci arrête.
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("qs -c foyer ipc call pastille enregistrer"))
hl.bind("SUPER + ALT + SHIFT + R", hl.dsp.exec_cmd("qs -c foyer ipc call pastille enregistrerZone"))
-- Super + . : emojis et caractères spéciaux (ouvre le hub en mode « : »)
hl.bind("SUPER + period", hl.dsp.exec_cmd("qs -c foyer ipc call hub caracteres"))
hl.bind("SUPER + semicolon", hl.dsp.exec_cmd("qs -c foyer ipc call hub caracteres"))

-- Captures d'écran (dans le dossier Images)
hl.bind("Print", hl.dsp.exec_cmd("sh -c 'grim \"$(xdg-user-dir PICTURES)/capture-$(date +%F-%H%M%S).png\"'"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("sh -c 'grim -g \"$(slurp)\" - | wl-copy'"))

-- Déplacement entre fenêtres
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Bureaux 1 à 10 : touches de la rangée du haut d'un clavier AZERTY
-- (& é " ' ( - è _ ç à), sans Maj.
local touches = {
	"ampersand", "eacute", "quotedbl", "apostrophe", "parenleft",
	"minus", "egrave", "underscore", "ccedilla", "agrave",
}
for i, touche in ipairs(touches) do
	hl.bind("SUPER + " .. touche, hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. touche, hl.dsp.window.move({ workspace = i }))
end

-- Bureau précédent / suivant (Super + Ctrl + flèches, ou Super + molette)
hl.bind("SUPER + CTRL + left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
-- Alt + Tab : fenêtre suivante du bureau actuel, en boucle (après la dernière,
-- on revient à la première). Les fenêtres réduites ne font pas partie du tour.
-- Super + Tab : bureau suivant parmi ceux qui existent, en boucle aussi.
-- Une seule fenêtre (ou aucune) sur le bureau : Alt + Tab passe au bureau suivant.
hl.bind("ALT + TAB", function()
	local bureau = hl.get_active_workspace()
	if bureau and bureau.windows <= 1 then
		hl.dispatch(hl.dsp.focus({ workspace = "e+1" }))
		return
	end
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "e+1" }))
-- Emmener la fenêtre sur le bureau d'à côté
hl.bind("SUPER + CTRL + SHIFT + left", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + SHIFT + right", hl.dsp.window.move({ workspace = "r+1" }))

-- Touches multimédia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"))
-- Luminosité : la pastille affiche le niveau
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("sh -c 'brightnessctl -q set +5%; qs -c foyer ipc call pastille luminosite'"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sh -c 'brightnessctl -q set 5%-; qs -c foyer ipc call pastille luminosite'"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
