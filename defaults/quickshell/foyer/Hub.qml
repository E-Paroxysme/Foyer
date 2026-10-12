// Géré par Foyer. Le hub : un seul point d'entrée (touche Super).
// v2 : heure et batterie, recherche d'applications et de tuiles, tuiles
// personnalisables (~/.config/foyer/tuiles.json), lecteur de musique, fenêtres
// ouvertes regroupées par bureau, navigation complète au clavier.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

PanelWindow {
    id: hub

    property bool ouvert: false
    property var tuiles: []
    property var resultats: []
    property int selection: 0     // résultat choisi (quand on cherche)
    property int curseur: -1      // élément choisi sans recherche : tuiles puis fenêtres (-1 = aucun)
    property bool afficherMusique: true
    property date maintenant: new Date()

    readonly property bool enRecherche: recherche.text.length > 0
    readonly property int nbTuiles: tuiles.length
    readonly property var fenetres: listerFenetres()
    readonly property int colonnes: Math.max(1, Math.floor((contenu.width + 12) / 112))
    readonly property var lecteur: lecteurActif()

    // --- Palette (le futur thème global la remplacera) ---------------------
    readonly property color cFond: "#d9111116"
    readonly property color cCarte: "#1e1e26"
    readonly property color cCarteSurvol: "#2a2a34"
    readonly property color cTexte: "#f0ece6"
    readonly property color cDiscret: "#9a948c"
    readonly property color cAccent: "#e8875a"
    readonly property string police: "Inter"

    visible: ouvert
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.namespace: "foyer-hub"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: ouvert ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOuvertChanged: {
        if (ouvert) {
            maintenant = new Date();
            recherche.text = "";
            selection = 0;
            curseur = -1;
            recherche.forceActiveFocus();
            try {
                Hyprland.refreshToplevels();
            } catch (e) {}
        }
    }

    // Une fenêtre fermée raccourcit la liste : le curseur reste dans les bornes.
    onFenetresChanged: {
        const total = nbTuiles + fenetres.length;
        if (curseur >= total)
            curseur = total - 1;
    }

    // --- Données ------------------------------------------------------------
    FileView {
        id: fichierTuiles
        path: Quickshell.env("HOME") + "/.config/foyer/tuiles.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const donnees = JSON.parse(text());
                hub.tuiles = Array.isArray(donnees) ? donnees : (donnees.tuiles || []);
                const w = (donnees && donnees.widgets) || {};
                hub.afficherMusique = w.musique !== false;
            } catch (e) {
                console.warn("tuiles.json illisible : " + e);
                hub.tuiles = [];
            }
        }
    }

    Timer {
        interval: 1000
        running: hub.ouvert
        repeat: true
        onTriggered: hub.maintenant = new Date()
    }

    // --- Fonctions ----------------------------------------------------------
    function normaliser(s) {
        let t = (s || "").toString().toLowerCase();
        try {
            t = t.normalize("NFD").replace(/[̀-ͯ]/g, "");
        } catch (e) {}
        return t;
    }

    function chercher(texte) {
        const q = normaliser(texte.trim());
        if (q.length === 0)
            return [];
        const trouves = [];
        for (const t of hub.tuiles) {
            const n = normaliser(t.nom);
            const d = normaliser(t.description);
            if (n.includes(q) || d.includes(q))
                trouves.push({ genre: "tuile", nom: t.nom, detail: t.description || "Tuile", icone: iconeTuile(t), donnee: t, score: n.startsWith(q) ? 0 : 1 });
        }
        for (const a of DesktopEntries.applications.values) {
            const n = normaliser(a.name);
            const g = normaliser(a.genericName);
            const k = (a.keywords || []).map(normaliser).join(" ");
            let score = -1;
            if (n.startsWith(q)) score = 0;
            else if (n.includes(q)) score = 1;
            else if (g.includes(q) || k.includes(q)) score = 2;
            if (score >= 0)
                trouves.push({ genre: "app", nom: a.name, detail: a.genericName || a.comment || "Application", icone: a.icon || "", donnee: a, score: score });
        }
        trouves.sort((x, y) => x.score - y.score || x.nom.localeCompare(y.nom));
        return trouves.slice(0, 8);
    }

    // Fenêtres ouvertes, avec leur bureau (via Hyprland), triées par bureau.
    function listerFenetres() {
        const hypr = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        const liste = ToplevelManager.toplevels.values.map((t, i) => {
            let bureau = 0;
            for (const h of hypr) {
                if (h.wayland === t) {
                    bureau = h.workspace ? h.workspace.id : 0;
                    break;
                }
            }
            return { fenetre: t, bureau: bureau, ordre: i };
        });
        const rang = b => (b > 0 ? b : 1000 - b);   // bureaux normaux d'abord, spéciaux et inconnus ensuite
        liste.sort((a, b) => rang(a.bureau) - rang(b.bureau) || a.ordre - b.ordre);
        return liste;
    }

    function nomBureau(b) {
        if (b > 0) {
            const actuel = Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === b;
            return "Bureau " + b + (actuel ? " · actuel" : "");
        }
        return b < 0 ? "Bureau spécial" : "";
    }

    // Lecteur affiché : celui qui joue, sinon le premier trouvé.
    function lecteurActif() {
        const lecteurs = Mpris.players.values;
        for (const p of lecteurs)
            if (p.isPlaying)
                return p;
        return lecteurs.length > 0 ? lecteurs[0] : null;
    }

    function executer(commande) {
        Quickshell.execDetached(commande);
    }

    function lancerEntree(e) {
        if (!e || !e.command)
            return;
        if (e.runInTerminal)
            executer(["uwsm", "app", "--", "foot", "-e"].concat(e.command));
        else
            executer(["uwsm", "app", "--"].concat(e.command));
    }

    function lancerTuile(t) {
        const a = t.action || {};
        const cible = a.cible || "";
        switch (a.type) {
        case "app": {
            const e = DesktopEntries.byId(cible) || DesktopEntries.heuristicLookup(cible);
            if (e) lancerEntree(e);
            else executer(["uwsm", "app", "--", "sh", "-c", cible]);
            break;
        }
        case "url":
            executer(["xdg-open", cible]);
            break;
        case "commande":
            executer(["sh", "-c", cible]);
            break;
        case "routine":
            executer(["notify-send", "Foyer", "Les routines arrivent dans une prochaine version (« " + cible + " »)."]);
            break;
        default:
            executer(["notify-send", "Foyer", "Action inconnue pour la tuile « " + (t.nom || "?") + " »."]);
        }
    }

    function activer(r) {
        if (!r)
            return;
        if (r.genre === "app") lancerEntree(r.donnee);
        else lancerTuile(r.donnee);
        hub.ouvert = false;
    }

    // --- Navigation au clavier (sans recherche : tuiles, puis fenêtres) ------
    function bas() {
        if (enRecherche) {
            selection = Math.min(selection + 1, resultats.length - 1);
            return;
        }
        const nT = nbTuiles, nF = fenetres.length;
        if (nT + nF === 0)
            return;
        if (curseur < 0) {
            curseur = 0;
        } else if (curseur < nT) {
            const ligne = Math.floor(curseur / colonnes);
            const derniereLigne = Math.floor((nT - 1) / colonnes);
            if (curseur + colonnes < nT) curseur += colonnes;
            else if (ligne < derniereLigne) curseur = nT - 1;
            else if (nF > 0) curseur = nT;
        } else if (curseur < nT + nF - 1) {
            curseur++;
        }
    }

    function haut() {
        if (enRecherche) {
            selection = Math.max(selection - 1, 0);
            return;
        }
        const nT = nbTuiles;
        if (curseur < 0)
            return;
        if (curseur > nT) curseur--;
        else if (curseur === nT) curseur = nT - 1;           // retour à la dernière tuile (ou -1 s'il n'y en a pas)
        else curseur = curseur - colonnes >= 0 ? curseur - colonnes : -1;
    }

    // ← → : se déplacer dans les tuiles. Renvoie false si la touche doit aller au champ.
    function lateral(sens) {
        if (enRecherche || curseur < 0 || curseur >= nbTuiles)
            return false;
        curseur = Math.max(0, Math.min(nbTuiles - 1, curseur + sens));
        return true;
    }

    function valider() {
        if (enRecherche) {
            activer(resultats[selection]);
        } else if (curseur >= 0 && curseur < nbTuiles) {
            lancerTuile(tuiles[curseur]);
            ouvert = false;
        } else if (curseur >= nbTuiles) {
            const f = fenetres[curseur - nbTuiles];
            if (f) {
                f.fenetre.activate();
                ouvert = false;
            }
        }
    }

    // Suppr : ferme la fenêtre choisie. Renvoie false si la touche doit aller au champ.
    function fermerChoix() {
        if (enRecherche || curseur < nbTuiles)
            return false;
        const f = fenetres[curseur - nbTuiles];
        if (f)
            f.fenetre.close();
        return true;
    }

    // --- Icônes -------------------------------------------------------------
    function chemin(icone) {
        if (!icone) return "";
        if (icone.startsWith("/")) return "file://" + icone;
        return Quickshell.iconPath(icone, "application-x-executable");
    }

    // Icône d'une tuile : celle de l'application quand l'action lance une app et
    // qu'aucune icône n'est imposée (ou "auto") ; sinon l'icône indiquée.
    function iconeTuile(t) {
        const a = t.action || {};
        if ((!t.icone || t.icone === "auto") && a.type === "app") {
            const e = DesktopEntries.byId(a.cible) || DesktopEntries.heuristicLookup(a.cible);
            if (e && e.icon) return e.icon;
        }
        return t.icone || "";
    }

    // Une icône courte (1 ou 2 caractères, ex. un emoji) s'affiche comme du texte.
    function estGlyphe(icone) {
        return icone && [...icone].length <= 2;
    }

    // --- Interface ----------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: hub.cFond

        // Un clic en dehors du contenu ferme le hub.
        MouseArea {
            anchors.fill: parent
            onClicked: hub.ouvert = false
        }
    }

    // Absorbe les clics dans la zone du contenu (seul un clic à l'extérieur ferme).
    MouseArea {
        anchors.fill: contenu
        anchors.margins: -16
    }

    ColumnLayout {
        id: contenu
        width: Math.min(680, hub.width - 48)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(48, hub.height * 0.14)
        spacing: 18

        // Ligne d'infos, alignée sur la barre de recherche :
        // batterie à gauche, heure au centre, date à droite.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: heure.implicitHeight
            Text {
                readonly property var batt: UPower.displayDevice
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                visible: batt && batt.isLaptopBattery
                text: visible ? (UPower.onBattery ? "" : "⚡ ") + Math.round(batt.percentage * 100) + " %" : ""
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 15
            }
            Text {
                id: heure
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(hub.maintenant, "HH:mm")
                color: hub.cTexte
                font.family: hub.police
                font.pixelSize: 44
                font.weight: Font.DemiBold
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: hub.maintenant.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 15
            }
        }

        // Barre de recherche. Elle garde le clavier en permanence : taper lance
        // une recherche, les flèches naviguent dans les tuiles et les fenêtres.
        TextField {
            id: recherche
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            placeholderText: "Rechercher une application, une tuile…"
            placeholderTextColor: hub.cDiscret
            color: hub.cTexte
            font.family: hub.police
            font.pixelSize: 18
            leftPadding: 20
            background: Rectangle {
                radius: 14
                color: hub.cCarte
                border.width: 2
                border.color: recherche.activeFocus && hub.curseur < 0 ? hub.cAccent : "transparent"
            }
            onTextChanged: {
                hub.resultats = hub.chercher(text);
                hub.selection = 0;
                hub.curseur = -1;
            }
            Keys.onEscapePressed: hub.ouvert = false
            Keys.onDownPressed: hub.bas()
            Keys.onUpPressed: hub.haut()
            Keys.onTabPressed: hub.bas()
            Keys.onBacktabPressed: hub.haut()
            Keys.onLeftPressed: event => event.accepted = hub.lateral(-1)
            Keys.onRightPressed: event => event.accepted = hub.lateral(1)
            Keys.onDeletePressed: event => event.accepted = hub.fermerChoix()
            Keys.onReturnPressed: hub.valider()
            Keys.onEnterPressed: hub.valider()
        }

        // Résultats de recherche
        ColumnLayout {
            visible: hub.enRecherche
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: hub.resultats
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 10
                    color: index === hub.selection ? hub.cCarteSurvol : (zone.containsMouse ? hub.cCarte : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 14
                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Text {
                                anchors.centerIn: parent
                                visible: hub.estGlyphe(modelData.icone)
                                text: modelData.icone
                                font.pixelSize: 22
                            }
                            Image {
                                anchors.fill: parent
                                visible: !hub.estGlyphe(modelData.icone)
                                source: hub.estGlyphe(modelData.icone) ? "" : hub.chemin(modelData.icone)
                                sourceSize.width: 28
                                sourceSize.height: 28
                            }
                        }
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Text {
                                text: modelData.nom
                                color: hub.cTexte
                                font.family: hub.police
                                font.pixelSize: 15
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.detail
                                color: hub.cDiscret
                                font.family: hub.police
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        Text {
                            text: modelData.genre === "tuile" ? "tuile" : ""
                            color: hub.cAccent
                            font.family: hub.police
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        id: zone
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: hub.activer(modelData)
                    }
                }
            }

            Text {
                visible: hub.resultats.length === 0
                text: "Aucun résultat"
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 14
                Layout.leftMargin: 14
            }
        }

        // Tuiles (quand la recherche est vide)
        Flow {
            visible: !hub.enRecherche && hub.tuiles.length > 0
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: hub.tuiles
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool choisie: hub.curseur === index
                    width: 100
                    height: 92
                    radius: 14
                    color: zoneTuile.containsMouse || choisie ? hub.cCarteSurvol : hub.cCarte
                    border.width: zoneTuile.containsMouse || choisie ? 2 : 0
                    border.color: hub.cAccent

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Item {
                            width: 32
                            height: 32
                            anchors.horizontalCenter: parent.horizontalCenter
                            readonly property string icone: hub.iconeTuile(modelData)
                            Text {
                                anchors.centerIn: parent
                                visible: hub.estGlyphe(parent.icone)
                                text: parent.icone
                                color: hub.cTexte
                                font.pixelSize: 26
                            }
                            Image {
                                anchors.fill: parent
                                visible: !hub.estGlyphe(parent.icone)
                                source: hub.estGlyphe(parent.icone) ? "" : hub.chemin(parent.icone)
                                sourceSize.width: 32
                                sourceSize.height: 32
                            }
                        }
                        Text {
                            width: 88
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.nom || ""
                            color: hub.cTexte
                            font.family: hub.police
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        id: zoneTuile
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            hub.lancerTuile(modelData);
                            hub.ouvert = false;
                        }
                    }
                }
            }
        }

        // Lecteur de musique : apparaît dès qu'un lecteur est actif (LibreWolf,
        // mpv, Spotify…). Désactivable dans tuiles.json : "widgets": { "musique": false }
        Rectangle {
            id: musique
            readonly property var p: hub.lecteur
            visible: hub.afficherMusique && p !== null && !hub.enRecherche
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: 14
            color: hub.cCarte

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    radius: 8
                    color: hub.cCarteSurvol
                    clip: true
                    Text {
                        anchors.centerIn: parent
                        visible: pochette.status !== Image.Ready
                        text: "♪"
                        color: hub.cDiscret
                        font.pixelSize: 24
                    }
                    Image {
                        id: pochette
                        anchors.fill: parent
                        source: musique.p ? (musique.p.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 104
                        sourceSize.height: 104
                        asynchronous: true
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: musique.p ? (musique.p.trackTitle || musique.p.identity || "Lecture") : ""
                        color: hub.cTexte
                        font.family: hub.police
                        font.pixelSize: 15
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: musique.p ? [musique.p.trackArtist, musique.p.identity].filter(s => s).join(" · ") : ""
                        color: hub.cDiscret
                        font.family: hub.police
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Bouton {
                    glyphe: "⏮"
                    actif: !!(musique.p && musique.p.canGoPrevious)
                    onClic: musique.p.previous()
                }
                Bouton {
                    glyphe: musique.p && musique.p.isPlaying ? "⏸" : "▶"
                    actif: !!(musique.p && musique.p.canTogglePlaying)
                    onClic: musique.p.togglePlaying()
                }
                Bouton {
                    glyphe: "⏭"
                    actif: !!(musique.p && musique.p.canGoNext)
                    onClic: musique.p.next()
                }
            }
        }

        // Fenêtres ouvertes, regroupées par bureau (quand la recherche est vide)
        ColumnLayout {
            visible: !hub.enRecherche
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 4

            Text {
                visible: hub.fenetres.length === 0
                text: "Aucune fenêtre ouverte"
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 13
                Layout.leftMargin: 4
            }

            Repeater {
                model: hub.fenetres
                delegate: ColumnLayout {
                    id: ligne
                    required property var modelData
                    required property int index
                    readonly property var fenetre: modelData.fenetre
                    readonly property var entree: DesktopEntries.heuristicLookup(fenetre.appId)
                    readonly property bool choisie: hub.curseur === hub.nbTuiles + index
                    readonly property bool nouveauBureau: index === 0 || hub.fenetres[index - 1].bureau !== modelData.bureau
                    Layout.fillWidth: true
                    spacing: 4

                    // Titre de groupe : « Bureau 2 », au premier élément de chaque bureau
                    Text {
                        visible: ligne.nouveauBureau
                        text: hub.nomBureau(ligne.modelData.bureau) || "Fenêtres ouvertes"
                        color: hub.cDiscret
                        font.family: hub.police
                        font.pixelSize: 13
                        Layout.leftMargin: 4
                        Layout.topMargin: ligne.index === 0 ? 0 : 8
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 10
                        color: ligne.choisie ? hub.cCarteSurvol : (zoneFenetre.containsMouse ? hub.cCarte : "transparent")
                        border.width: ligne.choisie ? 2 : 0
                        border.color: hub.cAccent

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 12
                            Image {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                source: hub.chemin(ligne.entree ? ligne.entree.icon : ligne.fenetre.appId)
                                sourceSize.width: 24
                                sourceSize.height: 24
                            }
                            Text {
                                text: ligne.fenetre.title || ligne.fenetre.appId
                                color: ligne.fenetre.activated ? hub.cTexte : hub.cDiscret
                                font.family: hub.police
                                font.pixelSize: 14
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            // Bouton fermer : un clic ferme l'application
                            Bouton {
                                glyphe: "✕"
                                survol: "#5a2a24"
                                z: 2
                                onClic: ligne.fenetre.close()
                            }
                        }
                        MouseArea {
                            id: zoneFenetre
                            anchors.fill: parent
                            anchors.rightMargin: 44
                            hoverEnabled: true
                            onClicked: {
                                ligne.fenetre.activate();
                                hub.ouvert = false;
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            text: hub.enRecherche
                ? "↑ ↓ puis Entrée · Échap pour fermer"
                : "Flèches pour naviguer · Entrée pour ouvrir · Suppr ferme la fenêtre choisie · Échap"
            color: hub.cDiscret
            font.family: hub.police
            font.pixelSize: 11
            opacity: 0.7
        }
    }
}
