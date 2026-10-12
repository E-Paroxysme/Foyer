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

-- Touches multimédia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
