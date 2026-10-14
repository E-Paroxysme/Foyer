// Géré par Foyer. Le thème, lu depuis ~/.config/quickshell/foyer/theme.json
// (fichier produit par « foyer theme » : thème par défaut + tes réglages de
// ~/.config/foyer/theme.json). Toute l'interface prend ses couleurs ici.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    property var donnees: ({})
    property bool eco: false

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/foyer/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                theme.donnees = JSON.parse(text());
            } catch (e) {
                console.warn("theme.json illisible, thème par défaut : " + e);
                theme.donnees = {};
            }
        }
    }

    // Profil « eco » (carte graphique ancienne) : moins d'effets et d'animations.
    FileView {
        path: Quickshell.env("HOME") + "/.config/foyer/profil-graphique"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: theme.eco = text().trim() === "eco"
    }

    function v(chemin, defaut) {
        let o = theme.donnees;
        for (const k of chemin.split(".")) {
            if (o !== null && typeof o === "object" && k in o)
                o = o[k];
            else
                return defaut;
        }
        return o;
    }

    function rgba(hex, a) {
        let h = String(hex || "#000000").replace("#", "");
        if (h.length === 3)
            h = h.split("").map(c => c + c).join("");
        const n = parseInt(h.slice(0, 6), 16) || 0;
        return Qt.rgba(((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255, a === undefined ? 1 : a);
    }

    // --- Couleurs ------------------------------------------------------------
    readonly property color accent: rgba(v("couleurs.accent", "#e8875a"))
    readonly property color accentClair: rgba(v("couleurs.accentClair", "#f6c27f"))
    readonly property color accentFonce: rgba(v("couleurs.accentFonce", "#d9603b"))
    readonly property color texte: rgba(v("couleurs.texte", "#f5f0eb"))
    readonly property color discret: rgba(v("couleurs.texte", "#f5f0eb"), v("transparence.discret", 0.64))
    readonly property color panneau: rgba(v("couleurs.panneau", "#1c1714"), eco ? v("transparence.panneauEco", 0.94) : v("transparence.panneau", 0.86))
    readonly property color carte: Qt.rgba(1, 1, 1, v("transparence.carte", 0.06))
    readonly property color carteChoisie: Qt.rgba(1, 1, 1, v("transparence.carteChoisie", 0.13))
    readonly property color trait: Qt.rgba(1, 1, 1, v("transparence.trait", 0.10))
    readonly property color bouton: Qt.rgba(1, 1, 1, 0.10)
    readonly property color surAccent: "#1a1210"
    readonly property color danger: rgba(v("couleurs.danger", "#e05d5d"))

    // --- Police, formes, mouvement --------------------------------------------
    readonly property string police: v("police.interface", "Geist")
    readonly property string policeMono: v("police.mono", "GeistMono Nerd Font")
    readonly property int arrondiPanneau: v("arrondis.panneau", 30)
    readonly property int arrondiCarte: v("arrondis.carte", 20)
    readonly property int arrondiLigne: v("arrondis.ligne", 12)
    readonly property bool animations: v("animations.actives", true)
    readonly property int duree: !animations ? 0 : (eco ? Math.round(v("animations.duree", 380) * 0.6) : v("animations.duree", 380))

    // --- Logo (tracés SVG 24×24) ----------------------------------------------
    readonly property string logoTrace: v("logo.trace", "M12 2.5c.6 2.6 2.2 4.3 3.7 6 1.4 1.6 2.3 3.2 2.3 5.4A6 6 0 0 1 6 13.9c0-2.4 1.1-4.1 2.6-5.5.2 1.7 1 2.9 2.2 3.4-.5-3.4.2-6.3 1.2-9.3z")
    readonly property string logoCoeur: v("logo.coeur", "")
}
