// Géré par Foyer. Le hub : un seul point d'entrée (touche Super).
// v3, d'après les maquettes validées : panneau flottant, en-tête au choix,
// recherche qui pousse le contenu (calcul, applications, tuiles, fenêtres,
// fichiers, web), tuiles aux icônes officielles, lecteur avec égaliseur,
// fenêtres par bureau (3 dispositions), calendrier qui s'ouvre depuis la date.
// Couleurs, police, arrondis : Theme.qml. Disposition : ~/.config/foyer/disposition.json.
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
    property string vue: "accueil"          // accueil | calendrier | reglages
    property var pastille: null             // donnée par shell.qml (Ne pas déranger dans les réglages)
    property var tuiles: []
    property var disposition: ({})
    property var resultats: []
    property var fichiers: []
    property int selection: 0
    property int curseur: -1                // sans recherche : tuiles puis fenêtres
    property int segment: 0                 // disposition « segments » : 0 = tous
    property bool cavaDispo: false
    property var barres: []
    property date maintenant: new Date()

    readonly property string home: Quickshell.env("HOME")
    readonly property bool enRecherche: recherche.text.length > 0
    readonly property int nbTuiles: tuiles.length
    readonly property int colonnes: 7
    readonly property var fenetres: listerFenetres()
    readonly property var fenetresVisibles: segment === 0 ? fenetres : fenetres.filter(f => f.bureau === segment)
    readonly property var lecteur: lecteurActif()
    readonly property string entete: disposition.entete || "compacte"
    readonly property string modeBureaux: disposition.bureaux || "titres"
    readonly property bool afficherMusique: !disposition.widgets || disposition.widgets.musique !== false
    readonly property bool afficherFenetres: !disposition.widgets || disposition.widgets.fenetres !== false
    readonly property bool egaliseur: (disposition.visualiseur || "colonnes") === "colonnes"
    readonly property int nbBarres: Theme.eco ? 12 : 24

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
            vue = "accueil";
            recherche.text = "";
            selection = 0;
            curseur = -1;
            segment = 0;
            recherche.forceActiveFocus();
            try {
                Hyprland.refreshToplevels();
            } catch (e) {}
        }
    }

    onFenetresChanged: {
        const total = nbTuiles + (fenetresVisibles ? fenetresVisibles.length : 0);
        if (curseur >= total)
            curseur = total - 1;
    }

    // --- Données ------------------------------------------------------------
    FileView {
        path: hub.home + "/.config/foyer/tuiles.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                hub.tuiles = Array.isArray(d) ? d : (d.tuiles || []);
            } catch (e) {
                console.warn("tuiles.json illisible : " + e);
                hub.tuiles = [];
            }
        }
    }

    FileView {
        path: hub.home + "/.config/foyer/disposition.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                hub.disposition = JSON.parse(text());
            } catch (e) {
                console.warn("disposition.json illisible : " + e);
                hub.disposition = {};
            }
        }
    }

    Timer {
        interval: 1000
        running: hub.ouvert
        repeat: true
        onTriggered: hub.maintenant = new Date()
    }

    // Égaliseur : cava, seulement quand le hub est ouvert et qu'une musique joue.
    Process {
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: code => hub.cavaDispo = code === 0
    }
    Process {
        running: hub.ouvert && hub.cavaDispo && hub.egaliseur && hub.afficherMusique && hub.lecteur !== null && hub.lecteur.isPlaying
        command: ["cava", "-p", hub.home + "/.config/foyer/cava.conf"]
        stdout: SplitParser {
            onRead: data => hub.barres = data.split(";").filter(x => x !== "").map(x => Math.min(1, parseInt(x) / 100))
        }
        onRunningChanged: if (!running) hub.barres = []
    }

    // Recherche de fichiers (fd), lancée un court instant après la frappe.
    Process {
        id: chercheFichiers
        property var lignes: []
        stdout: SplitParser {
            onRead: data => chercheFichiers.lignes.push(data)
        }
        onExited: {
            hub.fichiers = chercheFichiers.lignes.slice();
            hub.resultats = hub.chercher(recherche.text);
        }
    }
    Timer {
        id: delaiFichiers
        interval: 220
        onTriggered: {
            const q = recherche.text.trim();
            chercheFichiers.running = false;
            chercheFichiers.lignes = [];
            if (q.length < 3) {
                hub.fichiers = [];
                return;
            }
            chercheFichiers.command = ["fd", "-i", "-F", "-t", "f", "--max-results", "4", "--max-depth", "6", q, hub.home];
            chercheFichiers.running = true;
        }
    }

    // --- Fonctions ----------------------------------------------------------
    function normaliser(s) {
        let t = (s || "").toString().toLowerCase();
        try {
            t = t.normalize("NFD").replace(/[̀-ͯ]/g, "");
        } catch (e) {}
        return t;
    }

    function calculer(q) {
        const expr = q.replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**");
        if (!/^[\d\s+\-*/().%]+$/.test(expr) || !/\d/.test(expr) || !/[+\-*/%]/.test(expr))
            return null;
        try {
            const r = Function('"use strict"; return (' + expr + ');')();
            if (typeof r !== "number" || !isFinite(r))
                return null;
            return Math.round(r * 1e10) / 1e10;
        } catch (e) {
            return null;
        }
    }

    function chercher(texte) {
        const brut = texte.trim();
        const q = normaliser(brut);
        if (q.length === 0)
            return [];
        const res = [];
        const calcul = calculer(brut);
        if (calcul !== null)
            res.push({ genre: "calcul", groupe: "Calcul", nom: brut.replace(/\*/g, " × ") + " = " + String(calcul).replace(".", ","), detail: "Entrée pour copier", icone: "", valeur: String(calcul) });

        // Réglages : « wifi », « son », « thème »… ouvrent directement la bonne rubrique.
        const motsReglages = [
            ["accueil", "Réglages", "reglages parametres preferences configuration options"],
            ["wifi", "Wi-Fi", "wifi wi-fi reseau internet connexion sans fil"],
            ["bluetooth", "Bluetooth", "bluetooth casque ecouteurs souris sans fil appairer"],
            ["son", "Son", "son volume audio haut-parleurs micro micros sortie casque"],
            ["ecran", "Écran et énergie", "ecran luminosite veille energie batterie verrouillage affichage echelle"],
            ["entrees", "Souris et clavier", "souris clavier pave tactile touchpad pointeur defilement"],
            ["notifications", "Notifications", "notifications ne pas deranger alertes"],
            ["theme", "Thème", "theme couleur couleurs accent transparence arrondi apparence"],
            ["accessibilite", "Accessibilité", "accessibilite taille texte police grand animations contraste"],
            ["confidentialite", "Confidentialité", "confidentialite vie privee fichiers recents corbeille presse-papier"],
            ["defauts", "Applications par défaut", "applications par defaut navigateur courriel pdf ouvrir avec"],
            ["agendas", "Agendas", "agenda agendas calendrier pronote caldav ical"],
            ["systeme", "Système", "systeme mise a jour version disque stockage a propos imprimante heure date"],
            ["compte", "Compte", "compte photo nom mot de passe utilisateur fond d'ecran avatar"]
        ];
        let nbReglages = 0;
        for (const m of motsReglages) {
            if (nbReglages < 2 && (normaliser(m[1]).startsWith(q) || m[2].split(" ").some(w => q.length >= 3 && w.startsWith(q))))
                res.push({ genre: "reglage", groupe: "Réglages", nom: m[1], detail: m[0] === "accueil" ? "Tous les réglages" : "Réglages › " + m[1], icone: "preferences-system", valeur: m[0] }), nbReglages++;
        }

        const apps = [];
        for (const a of DesktopEntries.applications.values) {
            const n = normaliser(a.name);
            const g = normaliser(a.genericName);
            const k = (a.keywords || []).map(normaliser).join(" ");
            let score = -1;
            if (n.startsWith(q)) score = 0;
            else if (n.includes(q)) score = 1;
            else if (g.includes(q) || k.includes(q)) score = 2;
            if (score >= 0)
                apps.push({ genre: "app", groupe: "Applications", nom: a.name, detail: a.genericName || a.comment || "", icone: a.icon || "", donnee: a, score: score });
        }
        apps.sort((x, y) => x.score - y.score || x.nom.localeCompare(y.nom));
        res.push(...apps.slice(0, 4));

        const tuilesTrouvees = hub.tuiles.filter(t => normaliser(t.nom).includes(q) || normaliser(t.description).includes(q)).slice(0, 3);
        for (const t of tuilesTrouvees)
            res.push({ genre: "tuile", groupe: "Tuiles", nom: t.nom, detail: t.description || "", icone: iconeTuile(t), donnee: t });

        const fen = hub.fenetres.filter(f => normaliser(f.fenetre.title).includes(q) || normaliser(f.fenetre.appId).includes(q)).slice(0, 3);
        for (const f of fen) {
            const e = DesktopEntries.heuristicLookup(f.fenetre.appId);
            res.push({ genre: "fenetre", groupe: "Fenêtres ouvertes", nom: f.fenetre.title || f.fenetre.appId, detail: f.bureau > 0 ? "Bureau " + f.bureau : "", icone: e ? e.icon : f.fenetre.appId, donnee: f.fenetre });
        }

        for (const chemin of hub.fichiers) {
            const morceaux = chemin.split("/");
            res.push({ genre: "fichier", groupe: "Fichiers", nom: morceaux[morceaux.length - 1], detail: chemin.replace(hub.home, "~").split("/").slice(0, -1).join("/"), icone: "text-x-generic", valeur: chemin });
        }

        res.push({ genre: "web", groupe: "Web", nom: "Rechercher « " + brut + " » sur le web", detail: "DuckDuckGo", icone: "", valeur: "https://duckduckgo.com/?q=" + encodeURIComponent(brut) });
        return res;
    }

    function listerFenetres() {
        const hypr = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        const liste = ToplevelManager.toplevels.values.map((t, i) => {
            let bureau = 0, reduite = false, adresse = "";
            for (const h of hypr) {
                if (h.wayland === t) {
                    bureau = h.workspace ? h.workspace.id : 0;
                    // Bouton « réduire » des barres de titre : la fenêtre part sur ce bureau caché.
                    reduite = !!h.workspace && h.workspace.name === "special:reduites";
                    adresse = h.address ? (String(h.address).startsWith("0x") ? String(h.address) : "0x" + h.address) : "";
                    break;
                }
            }
            return { fenetre: t, bureau: bureau, ordre: i, reduite: reduite, adresse: adresse };
        });
        const rang = b => (b > 0 ? b : 1000 - b);
        liste.sort((a, b) => rang(a.bureau) - rang(b.bureau) || a.ordre - b.ordre);
        return liste;
    }

    function bureauxOuverts() {
        const ids = [];
        for (const f of hub.fenetres)
            if (f.bureau > 0 && !ids.includes(f.bureau))
                ids.push(f.bureau);
        return ids;
    }

    function nomBureau(b) {
        if (b > 0) {
            const actuel = Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === b;
            return "Bureau " + b + (actuel ? " · actuel" : "");
        }
        return b < 0 ? (hub.fenetres.some(f => f.bureau === b && f.reduite) ? "Fenêtres réduites" : "Bureau spécial") : "Fenêtres ouvertes";
    }

    // Affiche une fenêtre ; si elle est réduite, la ramène d'abord sur le bureau actuel.
    function montrerFenetre(t) {
        const e = hub.fenetres.find(f => f.fenetre === t);
        if (e && e.reduite && e.adresse && Hyprland.focusedWorkspace) {
            const fen = "address:" + e.adresse;
            executer(["sh", "-c", "hyprctl dispatch \"hl.dsp.window.move({ workspace = " + Hyprland.focusedWorkspace.id + ", window = '" + fen + "', follow = false })\" && hyprctl dispatch \"hl.dsp.focus({ window = '" + fen + "' })\""]);
        } else {
            t.activate();
        }
    }

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
        switch (r.genre) {
        case "calcul":
            executer(["wl-copy", r.valeur]);
            break;
        case "app":
            lancerEntree(r.donnee);
            break;
        case "tuile":
            lancerTuile(r.donnee);
            break;
        case "reglage":
            ouvrirReglages(r.valeur);
            return;
        case "fenetre":
            montrerFenetre(r.donnee);
            break;
        case "fichier":
        case "web":
            executer(["xdg-open", r.valeur]);
            break;
        }
        hub.ouvert = false;
    }

    // --- Clavier ------------------------------------------------------------
    function bas() {
        if (enRecherche) {
            selection = Math.min(selection + 1, resultats.length - 1);
            return;
        }
        const nT = nbTuiles, nF = afficherFenetres ? fenetresVisibles.length : 0;
        if (nT + nF === 0)
            return;
        if (curseur < 0) {
            curseur = 0;
        } else if (curseur < nT) {
            const ligne = Math.floor(curseur / colonnes);
            const derniere = Math.floor((nT - 1) / colonnes);
            if (curseur + colonnes < nT) curseur += colonnes;
            else if (ligne < derniere) curseur = nT - 1;
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
        else if (curseur === nT) curseur = nT - 1;
        else curseur = curseur - colonnes >= 0 ? curseur - colonnes : -1;
    }

    function lateral(sens) {
        if (vue === "calendrier") {
            vueCalendrier.decaler(sens);
            return true;
        }
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
            const f = fenetresVisibles[curseur - nbTuiles];
            if (f) {
                montrerFenetre(f.fenetre);
                ouvert = false;
            }
        }
    }

    function fermerChoix() {
        if (enRecherche || curseur < nbTuiles)
            return false;
        const f = fenetresVisibles[curseur - nbTuiles];
        if (f)
            f.fenetre.close();
        return true;
    }

    function echap() {
        if (vue === "reglages")
            vueReglages.retour();
        else if (vue === "calendrier")
            vue = "accueil";
        else
            ouvert = false;
    }

    // --- Icônes -------------------------------------------------------------
    function chemin(icone) {
        if (!icone) return "";
        if (icone.startsWith("/")) return "file://" + icone;
        return Quickshell.iconPath(icone, "application-x-executable");
    }

    function iconeTuile(t) {
        const a = t.action || {};
        if ((!t.icone || t.icone === "auto") && a.type === "app") {
            const e = DesktopEntries.byId(a.cible) || DesktopEntries.heuristicLookup(a.cible);
            if (e && e.icon) return e.icon;
        }
        return t.icone || "";
    }

    function estGlyphe(icone) {
        return icone && [...icone].length <= 2;
    }

    // --- Calendrier (interne pour l'instant) --------------------------------
    // Hauteur du hub au moment d'ouvrir le calendrier : le calendrier tient dedans
    // (il se réduit au besoin) au lieu d'agrandir le hub jusqu'au bord de l'écran.
    readonly property real hauteurAccueil: Math.max(540, vueAccueil.implicitHeight)
    function ouvrirReglages(rubrique) {
        recherche.text = "";
        vue = "reglages";
        vueReglages.ouvrir(rubrique);
    }
    function ouvrirCalendrier() {
        vue = "calendrier";
        vueCalendrier.ouvrir();
    }
    // --- Interface ----------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.14)
        MouseArea {
            anchors.fill: parent
            onClicked: hub.ouvert = false
        }
    }

    Rectangle {
        id: panneau
        width: Math.min(720, hub.width - 48)
        height: (hub.vue === "accueil" ? vueAccueil.implicitHeight : hub.hauteurAccueil) + 52
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(24, Math.min(48, hub.height * 0.05))
        radius: Theme.arrondiPanneau
        color: Theme.panneau
        border.width: 1
        border.color: Theme.trait
        clip: true
        Behavior on height {
            NumberAnimation {
                duration: Theme.duree
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        // ===================== Vue d'accueil =====================
        ColumnLayout {
            id: vueAccueil
            x: 28
            y: 26
            width: parent.width - 56
            spacing: 18
            opacity: hub.vue === "accueil" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.duree * 0.7 }
            }

            // En-tête « compacte » : petite heure, date cliquable, batterie
            RowLayout {
                visible: hub.entete === "compacte"
                Layout.fillWidth: true
                spacing: 14
                Text {
                    text: Qt.formatDateTime(hub.maintenant, "HH:mm")
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 34
                    font.weight: Font.Bold
                    font.letterSpacing: -1.2
                }
                DateCliquable {
                    Layout.fillWidth: true
                    date: hub.maintenant
                    onClic: hub.ouvrirCalendrier()
                }
                Batterie {}
            }

            // En-tête « ligne » : date à gauche, heure au centre, batterie à droite
            Item {
                visible: hub.entete === "ligne"
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                DateCliquable {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    date: hub.maintenant
                    onClic: hub.ouvrirCalendrier()
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: Qt.formatDateTime(hub.maintenant, "HH:mm")
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 60
                    font.weight: Font.Bold
                    font.letterSpacing: -2.4
                }
                Batterie {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                }
            }

            // En-tête « centrée » : grande heure, date et batterie dessous
            ColumnLayout {
                visible: hub.entete === "centree"
                Layout.fillWidth: true
                spacing: 4
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(hub.maintenant, "HH") + "<font color='" + Theme.accent + "'>:</font>" + Qt.formatDateTime(hub.maintenant, "mm")
                    textFormat: Text.StyledText
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 80
                    font.weight: Font.Bold
                    font.letterSpacing: -3
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    DateCliquable {
                        majuscules: true
                        date: hub.maintenant
                        onClic: hub.ouvrirCalendrier()
                    }
                    Batterie {}
                }
            }

            // Barre de recherche
            TextField {
                id: recherche
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                placeholderText: "Rechercher"
                placeholderTextColor: Theme.discret
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: 21
                leftPadding: 52
                background: Rectangle {
                    radius: 18
                    color: Theme.carte
                    border.width: recherche.activeFocus && hub.curseur < 0 ? 2 : 1
                    border.color: recherche.activeFocus && hub.curseur < 0 ? Theme.accent : Theme.trait
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌕"
                        color: Theme.discret
                        font.pixelSize: 24
                    }
                }
                onTextChanged: {
                    hub.resultats = hub.chercher(text);
                    hub.selection = 0;
                    hub.curseur = -1;
                    delaiFichiers.restart();
                }
                Keys.onEscapePressed: hub.echap()
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

            // Résultats : la zone s'ouvre et pousse le reste vers le bas
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: hub.enRecherche ? listeResultats.implicitHeight : 0
                Layout.topMargin: hub.enRecherche ? 0 : -18
                clip: true
                opacity: hub.enRecherche ? 1 : 0
                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Theme.duree
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on Layout.topMargin {
                    NumberAnimation { duration: Theme.duree }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.duree * 0.6 }
                }

                ColumnLayout {
                    id: listeResultats
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: hub.resultats
                        delegate: ColumnLayout {
                            id: res
                            required property var modelData
                            required property int index
                            readonly property bool choisi: index === hub.selection
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                visible: res.index === 0 || hub.resultats[res.index - 1].groupe !== res.modelData.groupe
                                text: res.modelData.groupe.toUpperCase()
                                color: Theme.discret
                                font.family: Theme.police
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.6
                                Layout.leftMargin: 10
                                Layout.topMargin: res.index === 0 ? 2 : 10
                                Layout.bottomMargin: 2
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: Theme.arrondiLigne
                                color: res.choisi ? Theme.carteChoisie : (zoneRes.containsMouse ? Theme.carte : "transparent")
                                border.width: res.choisi ? 2 : 0
                                border.color: Theme.accent

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 14
                                    spacing: 12
                                    Item {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: res.modelData.genre === "calcul" || res.modelData.genre === "web"
                                            radius: 8
                                            color: res.modelData.genre === "calcul" ? Theme.accent : Theme.bouton
                                            Text {
                                                anchors.centerIn: parent
                                                text: res.modelData.genre === "calcul" ? "=" : "↗"
                                                color: res.modelData.genre === "calcul" ? Theme.surAccent : Theme.texte
                                                font.pixelSize: 14
                                                font.weight: Font.Bold
                                            }
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: res.modelData.genre !== "calcul" && res.modelData.genre !== "web" && hub.estGlyphe(res.modelData.icone)
                                            text: res.modelData.icone
                                            font.pixelSize: 20
                                        }
                                        Image {
                                            anchors.fill: parent
                                            visible: res.modelData.genre !== "calcul" && res.modelData.genre !== "web" && !hub.estGlyphe(res.modelData.icone)
                                            source: visible ? hub.chemin(res.modelData.icone) : ""
                                            sourceSize.width: 26
                                            sourceSize.height: 26
                                        }
                                    }
                                    Text {
                                        text: res.modelData.nom
                                        color: Theme.texte
                                        font.family: Theme.police
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: res.modelData.detail
                                        color: Theme.discret
                                        font.family: Theme.police
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                        Layout.maximumWidth: 260
                                    }
                                }
                                MouseArea {
                                    id: zoneRes
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: hub.activer(res.modelData)
                                }
                            }
                        }
                    }
                }
            }

            // Le reste du hub : atténué pendant une recherche
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 18
                opacity: hub.enRecherche ? 0.45 : 1
                Behavior on opacity {
                    NumberAnimation { duration: Theme.duree }
                }

                // Tuiles
                GridLayout {
                    visible: hub.tuiles.length > 0
                    Layout.fillWidth: true
                    columns: hub.colonnes
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: hub.tuiles
                        delegate: Rectangle {
                            id: tuile
                            required property var modelData
                            required property int index
                            readonly property bool choisie: hub.curseur === index
                            readonly property string icone: hub.iconeTuile(modelData)
                            Layout.fillWidth: true
                            Layout.preferredHeight: 96
                            radius: Theme.arrondiCarte
                            color: choisie ? Theme.carteChoisie : Theme.carte
                            border.width: choisie || zoneTuile.containsMouse ? 2 : 1
                            border.color: choisie || zoneTuile.containsMouse ? Theme.accent : Theme.trait
                            scale: zoneTuile.containsMouse ? 1.03 : 1
                            Behavior on scale {
                                NumberAnimation { duration: 160 }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 9
                                Item {
                                    width: 44
                                    height: 44
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        visible: hub.estGlyphe(tuile.icone)
                                        text: tuile.icone
                                        color: Theme.texte
                                        font.pixelSize: 30
                                    }
                                    Image {
                                        anchors.fill: parent
                                        visible: !hub.estGlyphe(tuile.icone)
                                        source: visible ? hub.chemin(tuile.icone) : ""
                                        sourceSize.width: 44
                                        sourceSize.height: 44
                                    }
                                }
                                Text {
                                    width: tuile.width - 10
                                    horizontalAlignment: Text.AlignHCenter
                                    text: tuile.modelData.nom || ""
                                    color: Theme.texte
                                    font.family: Theme.police
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: zoneTuile
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    hub.lancerTuile(tuile.modelData);
                                    hub.ouvert = false;
                                }
                            }
                        }
                    }
                }

                // Lecteur de musique + égaliseur
                Rectangle {
                    id: musique
                    readonly property var p: hub.lecteur
                    visible: hub.afficherMusique && p !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: hub.egaliseur ? 128 : 74
                    radius: Theme.arrondiCarte
                    color: Theme.carte
                    border.width: 1
                    border.color: Theme.trait

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        anchors.rightMargin: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 12
                                color: Theme.bouton
                                clip: true
                                Logo {
                                    anchors.centerIn: parent
                                    visible: pochette.status !== Image.Ready
                                    taille: 20
                                }
                                Image {
                                    id: pochette
                                    anchors.fill: parent
                                    source: musique.p ? (musique.p.trackArtUrl || "") : ""
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 96
                                    sourceSize.height: 96
                                    asynchronous: true
                                }
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Text {
                                    text: musique.p ? (musique.p.trackTitle || musique.p.identity || "Lecture") : ""
                                    color: Theme.texte
                                    font.family: Theme.police
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: musique.p ? [musique.p.trackArtist, musique.p.identity].filter(s => s).join(" — ") : ""
                                    color: Theme.discret
                                    font.family: Theme.police
                                    font.pixelSize: 13
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
                                rond: true
                                plein: true
                                actif: !!(musique.p && musique.p.canTogglePlaying)
                                onClic: musique.p.togglePlaying()
                            }
                            Bouton {
                                glyphe: "⏭"
                                actif: !!(musique.p && musique.p.canGoNext)
                                onClic: musique.p.next()
                            }
                        }

                        // Égaliseur en colonnes (cava) ; à plat si rien ne joue
                        Row {
                            visible: hub.egaliseur
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            spacing: 4
                            Repeater {
                                model: hub.nbBarres
                                delegate: Item {
                                    id: colonne
                                    required property int index
                                    readonly property real niveau: hub.barres.length > index ? hub.barres[index] : 0
                                    width: (parent.width - (hub.nbBarres - 1) * 4) / hub.nbBarres
                                    height: 44
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: Math.max(3, colonne.niveau * parent.height)
                                        radius: 2
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: Theme.accentClair }
                                            GradientStop { position: 0.45; color: Theme.accent }
                                            GradientStop { position: 1; color: Theme.accentFonce }
                                        }
                                        Behavior on height {
                                            enabled: !Theme.eco
                                            NumberAnimation { duration: 70 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Fenêtres ouvertes (masquées pendant une recherche, pour la place)
                ColumnLayout {
                    visible: hub.afficherFenetres && !hub.enRecherche
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        visible: hub.fenetres.length === 0
                        text: "Aucune fenêtre ouverte"
                        color: Theme.discret
                        font.family: Theme.police
                        font.pixelSize: 13
                        Layout.leftMargin: 6
                    }

                    // Disposition « segments » : un sélecteur filtre par bureau
                    Rectangle {
                        visible: hub.modeBureaux === "segments" && hub.fenetres.length > 0
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: rangSegments.implicitWidth + 6
                        radius: 10
                        color: Theme.bouton
                        Row {
                            id: rangSegments
                            anchors.centerIn: parent
                            spacing: 2
                            Repeater {
                                model: [0].concat(hub.bureauxOuverts())
                                delegate: Rectangle {
                                    required property var modelData
                                    width: etiquetteSeg.implicitWidth + 26
                                    height: 28
                                    radius: 8
                                    color: hub.segment === modelData ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                                    Text {
                                        id: etiquetteSeg
                                        anchors.centerIn: parent
                                        text: parent.modelData === 0 ? "Tous" : "Bureau " + parent.modelData
                                        color: Theme.texte
                                        font.family: Theme.police
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: hub.segment = parent.modelData
                                    }
                                }
                            }
                        }
                    }

                    Repeater {
                        model: hub.fenetresVisibles
                        delegate: ColumnLayout {
                            id: ligne
                            required property var modelData
                            required property int index
                            readonly property var fenetre: modelData.fenetre
                            readonly property var entree: DesktopEntries.heuristicLookup(fenetre.appId)
                            readonly property bool choisie: hub.curseur === hub.nbTuiles + index
                            readonly property bool nouveauBureau: index === 0 || hub.fenetresVisibles[index - 1].bureau !== modelData.bureau
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                visible: hub.modeBureaux === "titres" && ligne.nouveauBureau
                                text: hub.nomBureau(ligne.modelData.bureau)
                                color: Theme.discret
                                font.family: Theme.police
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                Layout.leftMargin: 6
                                Layout.topMargin: ligne.index === 0 ? 0 : 8
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                radius: Theme.arrondiLigne
                                color: ligne.choisie ? Theme.carteChoisie : (zoneFenetre.containsMouse ? Theme.carte : "transparent")
                                border.width: ligne.choisie ? 2 : 0
                                border.color: Theme.accent

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: hub.modeBureaux === "badges" ? 6 : 10
                                    anchors.rightMargin: 6
                                    spacing: 12
                                    Rectangle {
                                        visible: hub.modeBureaux === "badges"
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 30
                                        radius: 9
                                        readonly property bool actuel: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ligne.modelData.bureau
                                        color: actuel ? Theme.accent : Theme.bouton
                                        Text {
                                            anchors.centerIn: parent
                                            text: ligne.modelData.bureau > 0 ? ligne.modelData.bureau : "·"
                                            color: parent.actuel ? Theme.surAccent : Theme.discret
                                            font.family: Theme.police
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                        }
                                    }
                                    Image {
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        source: hub.chemin(ligne.entree ? ligne.entree.icon : ligne.fenetre.appId)
                                        sourceSize.width: 24
                                        sourceSize.height: 24
                                    }
                                    Text {
                                        text: ligne.fenetre.title || ligne.fenetre.appId
                                        color: ligne.fenetre.activated ? Theme.texte : Theme.discret
                                        font.family: Theme.police
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Bouton {
                                        glyphe: "✕"
                                        rond: true
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
                                        hub.montrerFenetre(ligne.fenetre);
                                        hub.ouvert = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Aide clavier
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                spacing: 16
                Repeater {
                    model: hub.enRecherche ? [["↑ ↓", "choisir"], ["↵", "ouvrir"], ["Échap", "quitter"]] : [["↑ ↓ ← →", "naviguer"], ["↵", "ouvrir"], ["Suppr", "fermer"], ["Échap", "quitter"]]
                    delegate: Row {
                        required property var modelData
                        spacing: 6
                        Rectangle {
                            width: touche.implicitWidth + 12
                            height: 20
                            radius: 5
                            color: Theme.bouton
                            border.width: 1
                            border.color: Theme.trait
                            Text {
                                id: touche
                                anchors.centerIn: parent
                                text: modelData[0]
                                color: Theme.discret
                                font.family: Theme.police
                                font.pixelSize: 11
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData[1]
                            color: Theme.discret
                            font.family: Theme.police
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // ===================== Vue calendrier =====================
        Agenda {
            id: vueCalendrier
            x: 28
            y: 26
            width: parent.width - 56
            hauteurMax: hub.hauteurAccueil
            actif: hub.vue === "calendrier"
            opacity: actif ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.duree }
            }
            onFermer: hub.echap()
        }

        // ===================== Vue réglages =====================
        Reglages {
            id: vueReglages
            x: 28
            y: 26
            width: parent.width - 56
            height: hub.hauteurAccueil
            hauteurMax: hub.hauteurAccueil
            pastille: hub.pastille
            actif: hub.vue === "reglages" && hub.ouvert
            opacity: hub.vue === "reglages" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.duree }
            }
            onFermer: {
                hub.vue = "accueil";
                recherche.forceActiveFocus();
            }
        }
    }
}
