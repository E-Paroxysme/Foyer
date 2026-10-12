// Géré par Foyer. Le hub : un seul point d'entrée (touche Super).
// v1 : heure et batterie, recherche d'applications et de tuiles, tuiles
// personnalisables (~/.config/foyer/tuiles.json), fenêtres ouvertes avec
// fermeture d'un clic.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower

PanelWindow {
    id: hub

    property bool ouvert: false
    property var tuiles: []
    property var resultats: []
    property int selection: 0
    property date maintenant: new Date()

    // --- Palette (le futur thème global la remplacera) ---------------------
    readonly property color cFond: "#e6111116"
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
            recherche.forceActiveFocus();
        }
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
                trouves.push({ genre: "tuile", nom: t.nom, detail: t.description || "Tuile", icone: t.icone || "", donnee: t, score: n.startsWith(q) ? 0 : 1 });
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

    function chemin(icone) {
        if (!icone) return "";
        if (icone.startsWith("/")) return "file://" + icone;
        return Quickshell.iconPath(icone, "application-x-executable");
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

        // Ligne d'infos : heure, date, batterie
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Text {
                text: Qt.formatDateTime(hub.maintenant, "HH:mm")
                color: hub.cTexte
                font.family: hub.police
                font.pixelSize: 40
                font.weight: Font.DemiBold
            }
            Text {
                text: hub.maintenant.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 16
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
            }
            Item { Layout.fillWidth: true }
            Text {
                readonly property var batt: UPower.displayDevice
                visible: batt && batt.isLaptopBattery
                text: visible ? Math.round(batt.percentage * 100) + " %" + (UPower.onBattery ? "" : "  ⚡") : ""
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 16
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
            }
        }

        // Barre de recherche
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
                border.color: recherche.activeFocus ? hub.cAccent : "transparent"
            }
            onTextChanged: {
                hub.resultats = hub.chercher(text);
                hub.selection = 0;
            }
            Keys.onEscapePressed: hub.ouvert = false
            Keys.onDownPressed: hub.selection = Math.min(hub.selection + 1, hub.resultats.length - 1)
            Keys.onUpPressed: hub.selection = Math.max(hub.selection - 1, 0)
            Keys.onReturnPressed: hub.activer(hub.resultats[hub.selection])
            Keys.onEnterPressed: hub.activer(hub.resultats[hub.selection])
        }

        // Résultats de recherche
        ColumnLayout {
            visible: recherche.text.length > 0
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
            visible: recherche.text.length === 0 && hub.tuiles.length > 0
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: hub.tuiles
                delegate: Rectangle {
                    required property var modelData
                    width: 100
                    height: 92
                    radius: 14
                    color: zoneTuile.containsMouse ? hub.cCarteSurvol : hub.cCarte
                    border.width: zoneTuile.containsMouse ? 2 : 0
                    border.color: hub.cAccent

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Item {
                            width: 32
                            height: 32
                            anchors.horizontalCenter: parent.horizontalCenter
                            Text {
                                anchors.centerIn: parent
                                visible: hub.estGlyphe(modelData.icone)
                                text: modelData.icone || ""
                                font.pixelSize: 26
                            }
                            Image {
                                anchors.fill: parent
                                visible: !hub.estGlyphe(modelData.icone)
                                source: hub.estGlyphe(modelData.icone) ? "" : hub.chemin(modelData.icone)
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

        // Fenêtres ouvertes (quand la recherche est vide)
        ColumnLayout {
            visible: recherche.text.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 4

            Text {
                text: ToplevelManager.toplevels.values.length > 0 ? "Fenêtres ouvertes" : "Aucune fenêtre ouverte"
                color: hub.cDiscret
                font.family: hub.police
                font.pixelSize: 13
                Layout.leftMargin: 4
                Layout.bottomMargin: 4
            }

            Repeater {
                model: ToplevelManager.toplevels
                delegate: Rectangle {
                    id: ligne
                    required property var modelData
                    readonly property var entree: DesktopEntries.heuristicLookup(modelData.appId)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 10
                    color: zoneFenetre.containsMouse ? hub.cCarte : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 12
                        Image {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            source: hub.chemin(ligne.entree ? ligne.entree.icon : ligne.modelData.appId)
                            sourceSize.width: 24
                            sourceSize.height: 24
                        }
                        Text {
                            text: ligne.modelData.title || ligne.modelData.appId
                            color: ligne.modelData.activated ? hub.cTexte : hub.cDiscret
                            font.family: hub.police
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        // Bouton fermer : un clic ferme l'application
                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 8
                            color: zoneFermer.containsMouse ? "#5a2a24" : "transparent"
                            z: 2
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: zoneFermer.containsMouse ? hub.cAccent : hub.cDiscret
                                font.pixelSize: 15
                            }
                            MouseArea {
                                id: zoneFermer
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ligne.modelData.close()
                            }
                        }
                    }
                    MouseArea {
                        id: zoneFenetre
                        anchors.fill: parent
                        anchors.rightMargin: 44
                        hoverEnabled: true
                        onClicked: {
                            ligne.modelData.activate();
                            hub.ouvert = false;
                        }
                    }
                }
            }
        }

        Text {
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            text: "Échap pour fermer · ↑ ↓ puis Entrée dans les résultats"
            color: hub.cDiscret
            font.family: hub.police
            font.pixelSize: 11
            opacity: 0.7
        }
    }
}
