// Géré par Foyer. Vue Réglages du hub (maquettes P et R validées) : un accueil avec
// le compte et les rubriques ; un clic fait glisser la rubrique choisie.
// Tout ce qui touche au système passe par bin/foyer-reglages (et foyer-agenda).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: reglages

    property bool actif: false
    property real hauteurMax: 560
    property var pastille: null
    signal fermer

    property string page: "accueil"
    property string choixImage: ""        // "photo" | "fond" quand on choisit une image
    property var etat: ({})
    property var wifi: ({ actif: false, reseaux: [] })
    property var bt: ({ actif: false, appareils: [] })
    property bool btRecherche: false
    property int lum: 100
    property bool lumDispo: false
    property var images: []
    property var agendas: []
    property var ecrans: []
    property var energieEtat: ({ capot: "veille", limiteDisponible: false, limite: null })
    property var demarrage: []
    property var instantanes: ({ disponible: false, liste: [] })
    property string saisieWifi: ""        // réseau dont on tape le mot de passe
    property string message: ""
    property bool versLaDroite: true

    readonly property string home: Quickshell.env("HOME")
    readonly property string outil: home + "/.local/share/foyer/bin/foyer-reglages"
    readonly property string outilAgenda: home + "/.local/share/foyer/bin/foyer-agenda"

    readonly property var titres: ({
        accueil: "Réglages", compte: "Compte", wifi: "Wi-Fi", bluetooth: "Bluetooth", son: "Son",
        ecrans: "Écrans", energie: "Énergie", entrees: "Souris et clavier", notifications: "Notifications", theme: "Thème",
        accessibilite: "Accessibilité", confidentialite: "Confidentialité", applications: "Applications",
        agendas: "Agendas", systeme: "Système"
    })
    // Icônes au trait (24×24)
    readonly property var icones: ({
        wifi: "M2 9a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01",
        bluetooth: "M7 7l10 10-5 4V3l5 4L7 17",
        son: "M4 9h4l5-4v14l-5-4H4zM16.5 8.5a5 5 0 0 1 0 7M19 6a8.5 8.5 0 0 1 0 12",
        ecrans: "M3 5h18v11H3zM8 20h8M12 16v4",
        energie: "M3 8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM22 10.5v3M10 9l-2 3h4l-2 3",
        entrees: "M12 3a6 6 0 0 1 6 6v6a6 6 0 0 1-12 0V9a6 6 0 0 1 6-6zM12 7v3",
        notifications: "M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 21h4",
        theme: "M12 3a9 9 0 1 0 0 18c1 0 1.5-.8 1.5-1.6 0-1.2-1-1.4-1-2.4 0-.9.7-1.5 1.6-1.5H16a5 5 0 0 0 5-5c0-4-4-7.5-9-7.5zM7.5 11h.01M10 7.5h.01M15 7.5h.01",
        accessibilite: "M12 4a1.5 1.5 0 1 1 0 3a1.5 1.5 0 1 1 0-3zM5 9l7 1.5L19 9M12 10.5V15M12 15l-3 6M12 15l3 6",
        confidentialite: "M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6zM9 12l2 2 4-4",
        applications: "M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z",
        agendas: "M4 6h16v14H4zM4 10h16M8 3v4M16 3v4",
        systeme: "M12 15a3 3 0 1 0 0-6a3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"
    })

    implicitHeight: hauteurMax
    focus: actif
    Keys.onEscapePressed: retour()

    // --- Navigation -------------------------------------------------------------
    function ouvrir(rubrique) {
        message = "";
        choixImage = "";
        saisieWifi = "";
        aller(rubrique && titres[rubrique] ? rubrique : "accueil", true);
        lireEtat();
        forceActiveFocus();
    }
    function aller(p, droite) {
        versLaDroite = droite;
        page = p;
        choixImage = "";
        message = "";
        glisse.restart();
        if (p === "wifi") lireWifi();
        if (p === "bluetooth") lireBt(false);
        if (p === "ecrans") { lireLum(); lireEcrans(); }
        if (p === "energie") lireEnergie();
        if (p === "applications") lireDemarrage();
        if (p === "systeme") lireInstantanes();
        if (p === "agendas") lireAgendas();
    }
    function retour() {
        if (choixImage !== "") {
            choixImage = "";
            return;
        }
        if (page === "accueil")
            fermer();
        else
            aller("accueil", false);
    }

    // --- Lectures -------------------------------------------------------------------
    function lireEtat() { pEtat.running = false; pEtat.running = true; }
    function lireWifi() { pWifi.running = false; pWifi.running = true; }
    function lireBt(chercher) {
        btRecherche = chercher;
        pBt.running = false;
        pBt.command = [outil, "bt"].concat(chercher ? ["chercher"] : []);
        pBt.running = true;
    }
    function lireLum() { pLum.running = false; pLum.running = true; }
    function lireImages() { pImages.running = false; pImages.running = true; }
    function lireEcrans() { pEcrans.running = false; pEcrans.running = true; }
    function lireEnergie() { pEnergie.running = false; pEnergie.running = true; }
    function lireDemarrage() { pDemarrage.running = false; pDemarrage.running = true; }
    function lireInstantanes() { pInstantanes.running = false; pInstantanes.running = true; }
    function lireAgendas() {
        const d = new Date();
        pAgendas.running = false;
        pAgendas.command = [outilAgenda, "mois", d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0")];
        pAgendas.running = true;
    }
    function json(texte, defaut) {
        try { return JSON.parse(texte); } catch (e) { return defaut; }
    }
    Process { id: pEtat; command: [reglages.outil, "etat"]; stdout: StdioCollector { onStreamFinished: reglages.etat = reglages.json(text, reglages.etat) } }
    Process { id: pWifi; command: [reglages.outil, "wifi"]; stdout: StdioCollector { onStreamFinished: reglages.wifi = reglages.json(text, reglages.wifi) } }
    Process { id: pBt; stdout: StdioCollector { onStreamFinished: { reglages.bt = reglages.json(text, reglages.bt); reglages.btRecherche = false; } } }
    Process {
        id: pLum
        command: [reglages.outil, "luminosite"]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = reglages.json(text, null);
                if (d) { reglages.lum = d.valeur; reglages.lumDispo = d.disponible; }
            }
        }
    }
    Process { id: pImages; command: [reglages.outil, "images"]; stdout: StdioCollector { onStreamFinished: reglages.images = reglages.json(text, []) } }
    Process { id: pEcrans; command: [reglages.outil, "ecrans"]; stdout: StdioCollector { onStreamFinished: reglages.ecrans = reglages.json(text, []) } }
    Process { id: pEnergie; command: [reglages.outil, "energie-etat"]; stdout: StdioCollector { onStreamFinished: reglages.energieEtat = reglages.json(text, reglages.energieEtat) } }
    Process { id: pDemarrage; command: [reglages.outil, "demarrage"]; stdout: StdioCollector { onStreamFinished: reglages.demarrage = reglages.json(text, []) } }
    Process { id: pInstantanes; command: [reglages.outil, "instantanes"]; stdout: StdioCollector { onStreamFinished: reglages.instantanes = reglages.json(text, reglages.instantanes) } }
    Process { id: pAgendas; stdout: StdioCollector { onStreamFinished: reglages.agendas = (reglages.json(text, {}).agendas || []) } }
    Timer {
        interval: 10000
        repeat: true
        running: reglages.actif && reglages.page === "wifi" && reglages.saisieWifi === ""
        onTriggered: reglages.lireWifi()
    }

    // --- Actions : une file, exécutées l'une après l'autre ------------------------
    property var file: []
    property var courante: null
    function agir(args, apres, erreur, entree) {
        file = file.concat([{ cmd: [outil].concat(args), apres: apres, erreur: erreur, entree: entree }]);
        suivante();
    }
    function agirCmd(cmd, apres) {
        file = file.concat([{ cmd: cmd, apres: apres }]);
        suivante();
    }
    function suivante() {
        if (courante || file.length === 0)
            return;
        courante = file[0];
        file = file.slice(1);
        pAction.command = courante.cmd;
        pAction.running = true;
    }
    Process {
        id: pAction
        stdinEnabled: true
        onStarted: {
            if (reglages.courante && reglages.courante.entree !== undefined)
                write(reglages.courante.entree + "\n");
        }
        onExited: code => {
            const t = reglages.courante;
            reglages.courante = null;
            if (t) {
                if (code !== 0 && t.erreur) reglages.message = t.erreur;
                if (t.apres) t.apres(code);
            }
            reglages.suivante();
        }
    }
    function terminal(titre, commande) {
        Quickshell.execDetached(["uwsm", "app", "--", "foot", "-T", titre].concat(commande));
        fermer();
    }

    // --- Raccourcis vers les valeurs ----------------------------------------------
    function r(chemin, defaut) {
        let o = etat.reglages || {};
        for (const k of chemin.split(".")) {
            if (o && typeof o === "object" && k in o) o = o[k];
            else return defaut;
        }
        return o;
    }
    function octets(n) {
        if (!n) return "—";
        const u = ["o", "Ko", "Mo", "Go", "To"];
        let i = 0;
        while (n >= 1024 && i < 4) { n /= 1024; i++; }
        return (n >= 100 ? Math.round(n) : n.toFixed(1)).toString().replace(".", ",") + " " + u[i];
    }
    function nomAppli(id) {
        if (!id) return "—";
        const e = DesktopEntries.byId(id.replace(/\.desktop$/, ""));
        return e ? e.name : id.replace(/\.desktop$/, "");
    }
    readonly property var batterie: UPower.displayDevice
    function etatRubrique(cle) {
        switch (cle) {
        case "wifi": {
            if (r("avion", false)) return "Mode avion";
            const c = (wifi.reseaux || []).find(w => w.connecte);
            return wifi.actif ? (c ? c.nom : "Non connecté") : "Désactivé";
        }
        case "bluetooth": {
            const c = (bt.appareils || []).filter(a => a.connecte);
            return bt.actif ? (c.length ? c[0].nom + " connecté" : "Activé") : "Désactivé";
        }
        case "son": {
            const s = Pipewire.defaultAudioSink;
            return s ? Math.round((s.audio ? s.audio.volume : 0) * 100) + " %" + (s.audio && s.audio.muted ? " · muet" : "") : "—";
        }
        case "ecrans": return r("nuit.mode", "non") !== "non" ? "Éclairage nocturne" : (ecrans.length > 1 ? ecrans.length + " écrans" : "Luminosité, taille");
        case "energie": return batterie && batterie.isLaptopBattery ? "Batterie " + Math.round(batterie.percentage * 100) + " %" : "Veille, capot";
        case "entrees": return "Pavé tactile, clavier";
        case "notifications": return pastille && pastille.nePasDeranger ? "Ne pas déranger" : "Activées";
        case "theme": return (etat.theme ? etat.theme.base : "braise").replace(/^./, c => c.toUpperCase());
        case "accessibilite": return Theme.animations ? "Texte, animations" : "Animations réduites";
        case "confidentialite": return "Fichiers récents, corbeille";
        case "applications": return "Par défaut, démarrage";
        case "agendas": return "Agendas branchés";
        case "systeme": return "Foyer " + (etat.foyer ? etat.foyer.version : "");
        }
        return "";
    }

    // Premier coup d'œil : état Wi-Fi et Bluetooth pour les tuiles
    onActifChanged: if (actif) { lireWifi(); lireBt(false); lireEcrans(); }

    // --- Mise en page -----------------------------------------------------------------
    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(n => n.audio)
    }

    Item {
        id: contenu
        width: parent.width
        height: parent.height
        NumberAnimation {
            id: glisse
            target: contenu
            property: "x"
            from: reglages.versLaDroite ? 36 : -36
            to: 0
            duration: Theme.duree
            easing.type: Easing.OutCubic
        }
        opacity: glisse.running ? 0.35 + 0.65 * (1 - Math.abs(contenu.x) / 36) : 1

        // En-tête
        RowLayout {
            id: entete
            width: parent.width
            spacing: 12
            Bouton {
                visible: reglages.page !== "accueil"
                glyphe: "‹"
                rond: true
                onClic: reglages.retour()
            }
            Text {
                visible: reglages.page !== "accueil"
                text: "Réglages ›"
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 13
            }
            Text {
                text: reglages.titres[reglages.page] || ""
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: reglages.page === "accueil" ? 26 : 22
                font.weight: reglages.page === "accueil" ? Font.Bold : Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: reglages.page === "accueil"
                text: "Tape aussi « wifi », « son »… dans la recherche"
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 12
            }
            Interrupteur {
                visible: reglages.page === "wifi" || reglages.page === "bluetooth"
                actif: reglages.page === "wifi" ? reglages.wifi.actif : reglages.bt.actif
                onBascule: v => {
                    if (reglages.page === "wifi") {
                        reglages.wifi = Object.assign({}, reglages.wifi, { actif: v, reseaux: v ? reglages.wifi.reseaux : [] });
                        reglages.agir(["wifi", v ? "on" : "off"], () => reglages.lireWifi());
                    } else {
                        reglages.bt = Object.assign({}, reglages.bt, { actif: v });
                        reglages.agir(["bt", v ? "on" : "off"], () => reglages.lireBt(false));
                    }
                }
            }
        }

        Text {
            id: bandeau
            visible: reglages.message !== ""
            anchors.top: entete.bottom
            anchors.topMargin: 8
            width: parent.width
            text: reglages.message
            color: Theme.danger
            font.family: Theme.police
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }

        Flickable {
            id: defile
            anchors.top: bandeau.visible ? bandeau.bottom : entete.bottom
            anchors.topMargin: 16
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            contentHeight: chargeur.item ? chargeur.item.implicitHeight + 8 : 0
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: defile.contentHeight > defile.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
            Loader {
                id: chargeur
                width: defile.width
                sourceComponent: reglages.choixImage !== "" ? vueImages : ({
                    accueil: vueAccueil, compte: vueCompte, wifi: vueWifi, bluetooth: vueBt, son: vueSon, ecrans: vueEcrans,
                    energie: vueEnergie, entrees: vueEntrees, notifications: vueNotifications, theme: vueTheme, accessibilite: vueAccessibilite,
                    confidentialite: vueConfidentialite, applications: vueDefauts, agendas: vueAgendas, systeme: vueSysteme
                })[reglages.page] || vueAccueil
                onLoaded: defile.contentY = 0
            }
        }
    }

    // ===================== Accueil =====================
    Component {
        id: vueAccueil
        ColumnLayout {
            spacing: 12
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 82
                radius: Theme.arrondiCarte
                color: zoneCompte.containsMouse ? Theme.carteChoisie : Theme.carte
                border.width: 1
                border.color: Theme.trait
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 16
                    Avatar { taille: 54; nom: reglages.etat.compte ? reglages.etat.compte.nom : ""; photo: reglages.etat.compte && reglages.etat.compte.photo ? reglages.etat.compte.photoChemin : "" }
                    ColumnLayout {
                        spacing: 3
                        Layout.fillWidth: true
                        Text {
                            text: reglages.etat.compte ? reglages.etat.compte.nom : ""
                            color: Theme.texte
                            font.family: Theme.police
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: (reglages.etat.compte ? reglages.etat.compte.utilisateur : "") + " · photo, nom, mot de passe, fond d'écran"
                            color: Theme.discret
                            font.family: Theme.police
                            font.pixelSize: 13
                        }
                    }
                    Text { text: "›"; color: Theme.discret; font.pixelSize: 22 }
                }
                MouseArea {
                    id: zoneCompte
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: reglages.aller("compte", true)
                }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 5
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: ["wifi", "bluetooth", "son", "ecrans", "energie", "entrees", "notifications", "theme", "accessibilite", "confidentialite", "applications", "agendas", "systeme"]
                    delegate: Rectangle {
                        id: tuile
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 98
                        radius: Theme.arrondiCarte
                        color: zoneTuile.containsMouse ? Theme.carteChoisie : Theme.carte
                        border.width: 1
                        border.color: Theme.trait
                        y: zoneTuile.containsMouse ? -2 : 0
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 8
                            Rectangle {
                                implicitWidth: 34
                                implicitHeight: 34
                                radius: 11
                                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                Icone { anchors.centerIn: parent; trace: reglages.icones[tuile.modelData]; taille: 20; couleur: Theme.accentClair }
                            }
                            Item { Layout.fillHeight: true }
                            Text {
                                Layout.fillWidth: true
                                text: reglages.titres[tuile.modelData]
                                color: Theme.texte
                                font.family: Theme.police
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: reglages.etatRubrique(tuile.modelData)
                                color: Theme.discret
                                font.family: Theme.police
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: zoneTuile
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: reglages.aller(tuile.modelData, true)
                        }
                    }
                }
            }
        }
    }

    // ===================== Compte =====================
    Component {
        id: vueCompte
        RowLayout {
            spacing: 22
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 160
                spacing: 10
                Avatar { taille: 112; Layout.alignment: Qt.AlignHCenter; nom: reglages.etat.compte ? reglages.etat.compte.nom : ""; photo: reglages.etat.compte && reglages.etat.compte.photo ? reglages.etat.compte.photoChemin : "" }
                Bouton {
                    Layout.alignment: Qt.AlignHCenter
                    texte: "Changer la photo"
                    onClic: { reglages.choixImage = "photo"; reglages.lireImages(); }
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Aussi sur l'écran de verrouillage"
                    color: Theme.discret
                    font.family: Theme.police
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 10
                Etiquette { texte: "Nom affiché" }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.2)
                    border.width: 1
                    border.color: champNom.activeFocus ? Theme.accent : Theme.trait
                    TextField {
                        id: champNom
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        background: null
                        color: Theme.texte
                        font.family: Theme.police
                        font.pixelSize: 15
                        text: reglages.etat.compte ? reglages.etat.compte.nom : ""
                        onEditingFinished: {
                            if (reglages.etat.compte && text.trim() && text.trim() !== reglages.etat.compte.nom)
                                reglages.agir(["nom", text.trim()], () => reglages.lireEtat());
                        }
                        Keys.onEscapePressed: reglages.retour()
                    }
                }
                Ligne { titre: "Nom d'utilisateur"; valeur: reglages.etat.compte ? reglages.etat.compte.utilisateur : "" }
                Ligne {
                    titre: "Mot de passe"
                    bouton: "Changer…"
                    onAction: reglages.terminal("Mot de passe", ["passwd"])
                }
                Ligne { titre: "Langue et clavier"; valeur: "Français · AZERTY" }
                Ligne {
                    titre: "Fond d'écran"
                    bouton: "Changer"
                    onAction: { reglages.choixImage = "fond"; reglages.lireImages(); }
                }
            }
        }
    }

    // Choix d'une image (photo du compte ou fond d'écran)
    Component {
        id: vueImages
        ColumnLayout {
            spacing: 12
            Text {
                text: reglages.choixImage === "photo" ? "Choisis une photo (elle sera recadrée en carré)" : "Choisis un fond d'écran"
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 13
            }
            Text {
                visible: reglages.images.length === 0
                text: "Aucune image trouvée dans Images, Bureau ou Téléchargements."
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 14
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: reglages.images
                    delegate: Rectangle {
                        id: vignette
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: reglages.choixImage === "photo" ? 130 : 92
                        radius: 14
                        color: Theme.carte
                        clip: true
                        border.width: zoneImg.containsMouse ? 2 : 1
                        border.color: zoneImg.containsMouse ? Theme.accent : Theme.trait
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + vignette.modelData
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 320
                            asynchronous: true
                        }
                        MouseArea {
                            id: zoneImg
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const genre = reglages.choixImage;
                                reglages.choixImage = "";
                                reglages.agir([genre, vignette.modelData], () => reglages.lireEtat(), genre === "photo" ? "La photo n'a pas pu être changée." : "Le fond n'a pas pu être changé.");
                            }
                        }
                    }
                }
            }
        }
    }

    // ===================== Wi-Fi =====================
    Component {
        id: vueWifi
        ColumnLayout {
            spacing: 8
            Carte {
                Layout.fillWidth: true
                LigneInter {
                    titre: "Mode avion"
                    aide: "Coupe le Wi-Fi et le Bluetooth d'un coup"
                    actif: reglages.r("avion", false)
                    onBascule: v => reglages.basculerAvion(v)
                }
            }
            Etiquette { texte: reglages.wifi.actif ? "Réseaux disponibles" : "Wi-Fi désactivé"; Layout.topMargin: 4 }
            Text {
                visible: reglages.wifi.actif && (reglages.wifi.reseaux || []).length === 0
                text: "Recherche des réseaux…"
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 14
            }
            Repeater {
                model: reglages.wifi.actif ? reglages.wifi.reseaux : []
                delegate: Rectangle {
                    id: reseau
                    required property var modelData
                    readonly property bool deplie: reglages.saisieWifi === modelData.nom
                    Layout.fillWidth: true
                    implicitHeight: 48 + (deplie ? 46 : 0)
                    radius: 16
                    color: modelData.connecte || deplie ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.035)
                    border.width: 1
                    border.color: modelData.connecte ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45) : Qt.rgba(1, 1, 1, 0.06)
                    RowLayout {
                        x: 14
                        width: parent.width - 28
                        height: 48
                        spacing: 12
                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 13
                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    required property int index
                                    y: 13 - height
                                    width: 3
                                    height: 4 + index * 3
                                    radius: 1
                                    color: reseau.modelData.force >= (index + 1) * 22 ? Theme.texte : Qt.rgba(Theme.texte.r, Theme.texte.g, Theme.texte.b, 0.2)
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: reseau.modelData.nom
                            color: Theme.texte
                            font.family: Theme.police
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            text: reseau.modelData.connecte ? "Connecté" : (reseau.modelData.connu ? "Enregistré" : "")
                            color: reseau.modelData.connecte ? Theme.accentClair : Theme.discret
                            font.family: Theme.police
                            font.pixelSize: 12
                        }
                        Icone {
                            visible: reseau.modelData.protege
                            nom: "cadenas"
                            taille: 14
                            couleur: Theme.discret
                        }
                        Bouton {
                            visible: reseau.modelData.connu
                            texte: "Oublier"
                            onClic: reglages.agir(["wifi-oublier", reseau.modelData.nom], () => reglages.lireWifi())
                        }
                    }
                    MouseArea {
                        width: parent.width - 100
                        height: 48
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const w = reseau.modelData;
                            if (w.connecte) return;
                            if (w.protege && !w.connu) {
                                reglages.saisieWifi = reseau.deplie ? "" : w.nom;
                                return;
                            }
                            reglages.message = "";
                            reglages.agir(["wifi-connecter", w.nom], () => reglages.lireWifi(), "Connexion à « " + w.nom + " » impossible.", "");
                        }
                    }
                    RowLayout {
                        visible: reseau.deplie
                        x: 33
                        y: 48
                        width: parent.width - 47
                        spacing: 8
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.2)
                            border.width: 1
                            border.color: Theme.trait
                            TextField {
                                id: mdp
                                anchors.fill: parent
                                background: null
                                echoMode: TextInput.Password
                                placeholderText: "Mot de passe"
                                placeholderTextColor: Theme.discret
                                color: Theme.texte
                                font.family: Theme.police
                                font.pixelSize: 13
                                onVisibleChanged: if (visible) forceActiveFocus()
                                Keys.onReturnPressed: connecter.clic()
                                Keys.onEscapePressed: reglages.saisieWifi = ""
                            }
                        }
                        Bouton {
                            id: connecter
                            texte: "Se connecter"
                            plein: true
                            onClic: {
                                const nom = reseau.modelData.nom;
                                reglages.saisieWifi = "";
                                reglages.message = "";
                                reglages.agir(["wifi-connecter", nom], () => reglages.lireWifi(), "Connexion à « " + nom + " » impossible : mot de passe ?", mdp.text);
                            }
                        }
                    }
                }
            }
            Lien {
                texte: "Réglages avancés… (réseau caché, Wi-Fi d'entreprise, IP fixe)"
                onClic: reglages.terminal("Réseau", ["nmtui"])
            }
        }
    }

    // ===================== Bluetooth =====================
    Component {
        id: vueBt
        ColumnLayout {
            spacing: 8
            Carte {
                Layout.fillWidth: true
                LigneInter {
                    titre: "Mode avion"
                    aide: "Coupe le Wi-Fi et le Bluetooth d'un coup"
                    actif: reglages.r("avion", false)
                    onBascule: v => reglages.basculerAvion(v)
                }
            }
            Etiquette { texte: "Mes appareils"; Layout.topMargin: 4 }
            Text {
                visible: reglages.bt.actif && (reglages.bt.appareils || []).filter(a => a.appaire).length === 0
                text: "Aucun appareil appairé."
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 14
            }
            Repeater {
                model: reglages.bt.actif ? (reglages.bt.appareils || []).filter(a => a.appaire) : []
                delegate: Appareil {
                    modele: modelData
                    onAction: act => reglages.actionBt(act, modelData)
                }
            }
            RowLayout {
                visible: reglages.bt.actif
                Layout.topMargin: 8
                Etiquette { texte: "À proximité" }
                Item { Layout.fillWidth: true }
                Bouton {
                    texte: reglages.btRecherche ? "Recherche…" : "Rechercher"
                    actif: !reglages.btRecherche
                    onClic: reglages.lireBt(true)
                }
            }
            Text {
                visible: reglages.bt.actif
                text: reglages.btRecherche ? "Mets ton appareil en mode appairage…" : "Clique sur Rechercher, puis choisis l'appareil."
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 13
            }
            Repeater {
                model: reglages.bt.actif ? (reglages.bt.appareils || []).filter(a => !a.appaire) : []
                delegate: Appareil {
                    modele: modelData
                    onAction: act => reglages.actionBt(act, modelData)
                }
            }
        }
    }
    function basculerAvion(v) {
        const e = Object.assign({}, etat);
        e.reglages = Object.assign({}, e.reglages || {}, { avion: v });
        etat = e;
        agir(["avion", v ? 1 : 0], () => { reglages.lireWifi(); reglages.lireBt(false); });
    }
    function actionBt(act, m) {
        message = "";
        agir(["bt-action", act, m.mac], () => reglages.lireBt(false), act === "appairer" ? "Appairage avec « " + m.nom + " » impossible." : "« " + m.nom + " » ne répond pas.");
    }
    // ===================== Son =====================
    Component {
        id: vueSon
        GridLayout {
            id: grilleSon
            columns: 2
            columnSpacing: 14
            rowSpacing: 14
            readonly property var sorties: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && (n.properties || {})["media.class"] === "Audio/Sink")
            readonly property var entrees: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && (n.properties || {})["media.class"] === "Audio/Source")
            readonly property var applis: Pipewire.nodes.values.filter(n => n.audio && n.isStream && (n.properties || {})["media.class"] === "Stream/Output/Audio" && !String((n.properties || {})["application.name"] || "").toLowerCase().includes("cava"))
            Carte {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                Etiquette { texte: "Sortie" }
                Repeater {
                    model: grilleSon.sorties
                    delegate: ChoixRadio {
                        required property var modelData
                        texte: modelData.description || modelData.nickname || modelData.name
                        pris: Pipewire.defaultAudioSink === modelData
                        onClic: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Text { text: "Volume"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 13; Layout.fillWidth: true }
                    Text {
                        text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + " %" : "—"
                        color: Theme.discret; font.family: Theme.police; font.pixelSize: 13
                    }
                }
                Curseur {
                    Layout.fillWidth: true
                    de: 0; a: 100
                    valeur: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume * 100 : 0
                    onDeplace: v => { if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) Pipewire.defaultAudioSink.audio.volume = v / 100; }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Couper le son"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 13; Layout.fillWidth: true }
                    Interrupteur {
                        actif: !!(Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted)
                        onBascule: v => { if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) Pipewire.defaultAudioSink.audio.muted = v; }
                    }
                }
            }
            Carte {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                Etiquette { texte: "Entrée" }
                Repeater {
                    model: grilleSon.entrees
                    delegate: ChoixRadio {
                        required property var modelData
                        texte: modelData.description || modelData.nickname || modelData.name
                        pris: Pipewire.defaultAudioSource === modelData
                        onClic: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
                Etiquette { texte: "Par application"; Layout.topMargin: 8 }
                Text {
                    visible: grilleSon.applis.length === 0
                    text: "Aucune application ne joue de son."
                    color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                }
                Repeater {
                    model: grilleSon.applis
                    delegate: ColumnLayout {
                        id: fluxAppli
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: (modelData.properties || {})["application.name"] || modelData.description || modelData.name
                            color: Theme.texte; font.family: Theme.police; font.pixelSize: 13
                        }
                        Curseur {
                            Layout.fillWidth: true
                            valeur: fluxAppli.modelData.audio ? fluxAppli.modelData.audio.volume * 100 : 0
                            onDeplace: v => { if (fluxAppli.modelData.audio) fluxAppli.modelData.audio.volume = v / 100; }
                        }
                    }
                }
            }
        }
    }

    // ===================== Écrans =====================
    Component {
        id: vueEcrans
        ColumnLayout {
            spacing: 12
            Carte {
                Layout.fillWidth: true
                visible: reglages.lumDispo
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Luminosité"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                    Text { text: reglages.lum + " %"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 13 }
                }
                Curseur {
                    Layout.fillWidth: true
                    de: 5; a: 100
                    valeur: reglages.lum
                    onDeplace: v => { reglages.lum = v; lumDelai.restart(); }
                    onLache: v => { reglages.lum = v; lumDelai.restart(); }
                    Timer {
                        id: lumDelai
                        interval: 120
                        onTriggered: reglages.agir(["luminosite", reglages.lum])
                    }
                }
            }
            Carte {
                Layout.fillWidth: true
                LigneSegments {
                    titre: "Éclairage nocturne"
                    choix: [{ nom: "Non", valeur: "non" }, { nom: "Le soir", valeur: "soir" }, { nom: "Toujours", valeur: "toujours" }]
                    valeur: reglages.r("nuit.mode", "non")
                    onChoisi: v => reglages.changerNuit("mode", v)
                }
                Text {
                    visible: reglages.r("nuit.mode", "non") === "soir"
                    text: "De " + reglages.r("nuit.debut", "21:00") + " à " + reglages.r("nuit.fin", "07:00")
                    color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                }
                ColumnLayout {
                    visible: reglages.r("nuit.mode", "non") !== "non"
                    Layout.fillWidth: true
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Intensité"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 13; Layout.fillWidth: true }
                        Text { text: reglages.r("nuit.temperature", 4500) + " K"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 12 }
                    }
                    // Curseur inversé : à droite = plus chaud (température plus basse)
                    Curseur {
                        Layout.fillWidth: true
                        de: 0; a: 3500; pas: 100
                        valeur: 6000 - reglages.r("nuit.temperature", 4500)
                        onLache: v => reglages.changerNuit("temperature", 6000 - v)
                    }
                }
            }
            Carte {
                Layout.fillWidth: true
                LigneSegments {
                    titre: "Taille de l'affichage"
                    choix: [{ nom: "100 %", valeur: 1 }, { nom: "125 %", valeur: 1.25 }, { nom: "150 %", valeur: 1.5 }, { nom: "200 %", valeur: 2 }]
                    valeur: reglages.r("ecran.echelle", 1)
                    onChoisi: v => reglages.agir(["entrees", "echelle=" + v], () => reglages.lireEtat())
                }
            }
            Etiquette { texte: reglages.ecrans.length > 1 ? reglages.ecrans.length + " écrans branchés" : "Écran"; Layout.topMargin: 4 }
            Repeater {
                model: reglages.ecrans
                delegate: Carte {
                    id: carteEcran
                    required property var modelData
                    readonly property var reg: modelData.reglage || {}
                    readonly property string principal: (reglages.ecrans.find(e => e.interne) || reglages.ecrans[0] || {}).nom || ""
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: (carteEcran.modelData.interne ? "Écran du portable" : (carteEcran.modelData.description || carteEcran.modelData.nom))
                                color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; font.weight: Font.Medium
                            }
                            Text {
                                text: carteEcran.modelData.nom + " · " + carteEcran.modelData.largeur + "×" + carteEcran.modelData.hauteur + " · " + carteEcran.modelData.frequence + " Hz"
                                color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                            }
                        }
                        Interrupteur {
                            visible: reglages.ecrans.length > 1
                            actif: carteEcran.modelData.actif
                            onBascule: v => reglages.changerEcran(carteEcran.modelData.nom, ["actif=" + (v ? 1 : 0)])
                        }
                    }
                    LigneSegments {
                        visible: !carteEcran.modelData.interne && reglages.ecrans.length > 1
                        titre: "Place"
                        choix: [{ nom: "À gauche", valeur: "auto-left" }, { nom: "À droite", valeur: "auto-right" }, { nom: "Au-dessus", valeur: "auto-up" }, { nom: "Recopie", valeur: "recopie" }]
                        valeur: carteEcran.reg.recopie ? "recopie" : (carteEcran.reg.position || "auto-right")
                        onChoisi: v => reglages.changerEcran(carteEcran.modelData.nom, v === "recopie" ? ["recopie=" + carteEcran.principal] : ["recopie=", "position=" + v])
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: carteEcran.modelData.modes.length > 1
                        Text { text: "Résolution"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                        Bouton {
                            glyphe: "‹"
                            rond: true
                            onClic: reglages.cyclerMode(carteEcran.modelData, 1)
                        }
                        Text {
                            text: (carteEcran.reg.mode || (carteEcran.modelData.largeur + "x" + carteEcran.modelData.hauteur + "@" + carteEcran.modelData.frequence)).replace("x", "×").replace("@", " · ") + " Hz"
                            color: Theme.texte; font.family: Theme.police; font.pixelSize: 13
                        }
                        Bouton {
                            glyphe: "›"
                            rond: true
                            onClic: reglages.cyclerMode(carteEcran.modelData, -1)
                        }
                    }
                    LigneSegments {
                        titre: "Orientation"
                        choix: [{ nom: "Normale", valeur: 0 }, { nom: "90°", valeur: 1 }, { nom: "180°", valeur: 2 }, { nom: "270°", valeur: 3 }]
                        valeur: carteEcran.reg.rotation !== undefined ? carteEcran.reg.rotation : carteEcran.modelData.rotation
                        onChoisi: v => reglages.changerEcran(carteEcran.modelData.nom, ["rotation=" + v])
                    }
                }
            }
            Text {
                visible: reglages.ecrans.length <= 1
                Layout.fillWidth: true
                text: "Branche un vidéoprojecteur ou un second écran : il apparaîtra ici (recopie ou extension)."
                color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }
    function changerNuit(cle, v) {
        const n = Object.assign({ mode: "non", temperature: 4500, debut: "21:00", fin: "07:00" }, r("nuit", {}));
        n[cle] = v;
        const e = Object.assign({}, etat);
        e.reglages = Object.assign({}, e.reglages || {}, { nuit: n });
        etat = e;
        agir(["nuit", cle + "=" + v]);
    }
    function changerEcran(nom, args) {
        agir(["ecran", nom].concat(args), () => { reglages.lireEcrans(); });
    }
    function cyclerMode(m, sens) {
        const actuel = (m.reglage && m.reglage.mode) || (m.largeur + "x" + m.hauteur + "@" + m.frequence);
        let i = m.modes.indexOf(actuel);
        i = (i < 0 ? 0 : i + sens + m.modes.length) % m.modes.length;
        changerEcran(m.nom, ["mode=" + m.modes[i]]);
    }

    // ===================== Énergie =====================
    Component {
        id: vueEnergie
        ColumnLayout {
            spacing: 12
            Carte {
                Layout.fillWidth: true
                LigneSegments {
                    titre: "Éteindre l'écran après"
                    choix: [{ nom: "2 min", valeur: 120 }, { nom: "5 min", valeur: 300 }, { nom: "10 min", valeur: 600 }, { nom: "Jamais", valeur: 0 }]
                    valeur: reglages.r("veille.ecran", 300)
                    onChoisi: v => reglages.changerVeille("ecran", v)
                }
                LigneSegments {
                    titre: "Verrouiller après"
                    choix: [{ nom: "5 min", valeur: 300 }, { nom: "10 min", valeur: 600 }, { nom: "30 min", valeur: 1800 }, { nom: "Jamais", valeur: 0 }]
                    valeur: reglages.r("veille.verrou", 600)
                    onChoisi: v => reglages.changerVeille("verrou", v)
                }
                LigneSegments {
                    titre: "Mise en veille après"
                    choix: [{ nom: "10 min", valeur: 600 }, { nom: "20 min", valeur: 1200 }, { nom: "1 h", valeur: 3600 }, { nom: "Jamais", valeur: 0 }]
                    valeur: reglages.r("veille.suspension", 1200)
                    onChoisi: v => reglages.changerVeille("suspension", v)
                }
            }
            Carte {
                Layout.fillWidth: true
                LigneSegments {
                    titre: "Quand on ferme le capot"
                    choix: [{ nom: "Veille", valeur: "veille" }, { nom: "Verrouiller", valeur: "verrou" }, { nom: "Rien", valeur: "rien" }]
                    valeur: reglages.energieEtat.capot
                    onChoisi: v => reglages.agir(["capot", v], () => reglages.lireEnergie(), "Réglage du capot non appliqué (mot de passe refusé ?).")
                }
                LigneSegments {
                    visible: (reglages.etat.energie || "") !== ""
                    titre: "Mode d'énergie"
                    choix: [{ nom: "Économie", valeur: "power-saver" }, { nom: "Équilibré", valeur: "balanced" }, { nom: "Performance", valeur: "performance" }]
                    valeur: reglages.etat.energie || ""
                    onChoisi: v => reglages.agir(["energie", v], () => reglages.lireEtat(), "Ce mode n'est pas disponible sur cet ordinateur.")
                }
                LigneInter {
                    visible: reglages.energieEtat.limiteDisponible
                    titre: "Préserver la batterie"
                    aide: "Arrête la charge à 80 % (le mot de passe est demandé)"
                    actif: reglages.energieEtat.limite !== null && reglages.energieEtat.limite < 100
                    onBascule: v => reglages.agir(["limite-charge", v ? 80 : 100], () => reglages.lireEnergie(), "Limite de charge non appliquée.")
                }
            }
            Carte {
                Layout.fillWidth: true
                visible: reglages.batterie && reglages.batterie.isLaptopBattery
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        readonly property var b: reglages.batterie
                        text: b ? "Batterie · " + Math.round(b.percentage * 100) + " %" + (b.timeToEmpty > 0 ? " · environ " + Math.floor(b.timeToEmpty / 3600) + " h " + String(Math.floor((b.timeToEmpty % 3600) / 60)).padStart(2, "0") : (b.timeToFull > 0 ? " · en charge" : "")) : ""
                        color: Theme.texte; font.family: Theme.police; font.pixelSize: 14
                    }
                    Rectangle {
                        implicitWidth: 120
                        implicitHeight: 8
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.12)
                        Rectangle {
                            width: parent.width * (reglages.batterie ? reglages.batterie.percentage : 0)
                            height: parent.height
                            radius: 4
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }
    function changerVeille(cle, v) {
        const ve = Object.assign({ ecran: 300, verrou: 600, suspension: 1200 }, r("veille", {}));
        ve[cle] = v;
        const e = Object.assign({}, etat);
        e.reglages = Object.assign({}, e.reglages || {}, { veille: ve });
        etat = e;
        agir(["veille", ve.ecran, ve.verrou, ve.suspension]);
    }

    // ===================== Souris et clavier =====================
    Component {
        id: vueEntrees
        ColumnLayout {
            spacing: 12
            Carte {
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Vitesse du pointeur"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                    Text {
                        readonly property real s: reglages.r("entrees.sensibilite", 0)
                        text: s === 0 ? "normale" : (s < 0 ? "plus lente" : "plus rapide")
                        color: Theme.discret; font.family: Theme.police; font.pixelSize: 13
                    }
                }
                Curseur {
                    Layout.fillWidth: true
                    de: -1; a: 1; pas: 0.1
                    valeur: reglages.r("entrees.sensibilite", 0)
                    onLache: v => reglages.changerEntree("sensibilite", Math.round(v * 10) / 10)
                }
                LigneInter {
                    titre: "Défilement naturel"
                    aide: "Le contenu suit les doigts, comme sur un téléphone"
                    actif: reglages.r("entrees.defilementNaturel", true)
                    onBascule: v => reglages.changerEntree("defilementNaturel", v)
                }
                LigneInter {
                    titre: "Toucher pour cliquer"
                    aide: "Une tape sur le pavé tactile vaut un clic"
                    actif: reglages.r("entrees.tapClic", true)
                    onBascule: v => reglages.changerEntree("tapClic", v)
                }
            }
            Carte {
                Layout.fillWidth: true
                LigneSegments {
                    titre: "Répétition des touches"
                    choix: [{ nom: "Lente", valeur: 25 }, { nom: "Normale", valeur: 35 }, { nom: "Rapide", valeur: 50 }]
                    valeur: reglages.r("entrees.vitesseRepetition", 35)
                    onChoisi: v => reglages.changerEntree("vitesseRepetition", v)
                }
                ColumnLayout {
                    id: colClavier
                    Layout.fillWidth: true
                    spacing: 8
                    property bool ajout: false
                    readonly property var noms: ({ "fr": "Français (AZERTY)", "fr(bepo)": "Français (BÉPO)", "fr(oss)": "Français (variante)", "us": "Anglais (QWERTY)", "us(intl)": "Anglais international", "gb": "Anglais (Royaume-Uni)", "de": "Allemand", "es": "Espagnol", "it": "Italien", "ch(fr)": "Suisse romand", "be": "Belge", "ca(fr)": "Canadien français", "ar": "Arabe", "ru": "Russe" })
                    readonly property var actives: (reglages.r("entrees.dispositions", [{ code: "fr", variante: "" }])).map(d => d.code + (d.variante ? "(" + d.variante + ")" : ""))
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Dispositions du clavier"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                        Text { visible: colClavier.actives.length > 1; text: "Alt + Maj pour changer"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 12 }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: colClavier.actives
                            delegate: Bouton {
                                required property var modelData
                                required property int index
                                texte: (colClavier.noms[modelData] || modelData) + (colClavier.actives.length > 1 ? "  ×" : "")
                                onClic: if (colClavier.actives.length > 1) reglages.changerClavier(colClavier.actives.filter((x, i) => i !== index))
                            }
                        }
                        Bouton { texte: "+ Ajouter"; onClic: colClavier.ajout = !colClavier.ajout }
                    }
                    Flow {
                        visible: colClavier.ajout
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: Object.keys(colClavier.noms).filter(k => !colClavier.actives.includes(k))
                            delegate: Bouton {
                                required property var modelData
                                texte: colClavier.noms[modelData]
                                onClic: { colClavier.ajout = false; reglages.changerClavier(colClavier.actives.concat([modelData])); }
                            }
                        }
                    }
                }
                Ligne { titre: "Raccourcis"; valeur: "Super : hub · Super+Entrée : terminal · Super+Q : fermer" }
            }
        }
    }
    function changerClavier(liste) {
        const en = Object.assign({}, r("entrees", {}));
        en.dispositions = liste.map(x => { const m = x.match(/^([a-z]+)(?:\(([\w-]+)\))?$/); return { code: m[1], variante: m[2] || "" }; });
        const e = Object.assign({}, etat);
        e.reglages = Object.assign({}, e.reglages || {}, { entrees: en });
        etat = e;
        agir(["entrees", "dispositions=" + liste.join(",")]);
    }
    function changerEntree(cle, v) {
        const en = Object.assign({}, r("entrees", {}));
        en[cle] = v;
        const e = Object.assign({}, etat);
        e.reglages = Object.assign({}, e.reglages || {}, { entrees: en });
        etat = e;
        agir(["entrees", cle + "=" + (typeof v === "boolean" ? (v ? 1 : 0) : v)]);
    }

    // ===================== Notifications =====================
    Component {
        id: vueNotifications
        ColumnLayout {
            spacing: 12
            Carte {
                Layout.fillWidth: true
                LigneInter {
                    titre: "Ne pas déranger"
                    aide: "Les notifications arrivent dans l'historique sans s'afficher (sauf les urgentes)"
                    actif: !!(reglages.pastille && reglages.pastille.nePasDeranger)
                    onBascule: v => { if (reglages.pastille) reglages.pastille.nePasDeranger = v; }
                }
                Ligne {
                    titre: "Historique"
                    valeur: reglages.pastille ? (reglages.pastille.nonLues + " non lue" + (reglages.pastille.nonLues > 1 ? "s" : "")) : ""
                    bouton: "Ouvrir"
                    onAction: {
                        reglages.fermer();
                        Quickshell.execDetached(["qs", "-c", "foyer", "ipc", "call", "pastille", "historique"]);
                    }
                }
                Ligne { titre: "Durée d'affichage"; valeur: "5 secondes" }
                Ligne { titre: "Rappels de l'agenda"; valeur: "15 minutes avant" }
            }
        }
    }

    // ===================== Thème =====================
    Component {
        id: vueTheme
        ColumnLayout {
            id: colTheme
            spacing: 12
            readonly property var liste: reglages.etat.theme ? reglages.etat.theme.liste : []
            readonly property string base: reglages.etat.theme ? reglages.etat.theme.base : "braise"
            Carte {
                Layout.fillWidth: true
                Etiquette { texte: "Thème" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: colTheme.liste
                        delegate: Rectangle {
                            id: carteTheme
                            required property var modelData
                            readonly property bool pris: modelData.id === colTheme.base
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 76
                            radius: 14
                            color: pris ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            border.width: pris ? 2 : 1
                            border.color: pris ? modelData.accent : Theme.trait
                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 34; height: 34; radius: 17
                                    color: carteTheme.modelData.panneau
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.12)
                                    Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: carteTheme.modelData.accent }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: carteTheme.modelData.nom
                                    color: Theme.texte; font.family: Theme.police; font.pixelSize: 12; font.weight: Font.Medium
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: reglages.changerTheme(["base=" + carteTheme.modelData.id])
                            }
                        }
                    }
                }
                Etiquette { texte: "Couleur d'accent"; Layout.topMargin: 4 }
                Row {
                    spacing: 8
                    Repeater {
                        model: {
                            const a = String(Theme.v("couleurs.accent", "#e8875a"));
                            const t = (colTheme.liste || []).find(x => x.id === colTheme.base);
                            const ref = t ? t.accent : a;
                            const melange = (h, c, k) => {
                                const n = parseInt(h.slice(1), 16), m = parseInt(c.slice(1), 16);
                                const f = (s) => Math.round(((n >> s) & 255) * (1 - k) + ((m >> s) & 255) * k);
                                return "#" + [16, 8, 0].map(s => f(s).toString(16).padStart(2, "0")).join("");
                            };
                            return [ref, melange(ref, "#ffffff", 0.25), melange(ref, "#000000", 0.18), melange(ref, "#ffcc66", 0.35), melange(ref, "#ff5a7a", 0.3), melange(ref, "#5aa0ff", 0.3)];
                        }
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool pris: String(Theme.accent).toLowerCase().slice(-6) === String(modelData).slice(-6)
                            width: 30; height: 30; radius: 15
                            color: modelData
                            border.width: pris ? 3 : 0
                            border.color: Theme.texte
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: reglages.changerTheme([parent.index === 0 ? "couleurs.accent=null" : "couleurs.accent=" + JSON.stringify(parent.modelData)])
                            }
                        }
                    }
                }
            }
            Carte {
                Layout.fillWidth: true
                Etiquette { texte: "Apparence" }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Transparence du panneau"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                    Text { text: Math.round((1 - Theme.v("transparence.panneau", 0.86)) * 100) + " %"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 13 }
                }
                Curseur {
                    Layout.fillWidth: true
                    de: 0; a: 40
                    valeur: Math.round((1 - Theme.v("transparence.panneau", 0.86)) * 100)
                    onLache: v => reglages.changerTheme(["transparence.panneau=" + (1 - v / 100).toFixed(2)])
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Arrondi"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                    Text { text: Theme.arrondiPanneau + " px"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 13 }
                }
                Curseur {
                    Layout.fillWidth: true
                    de: 8; a: 36
                    valeur: Theme.arrondiPanneau
                    onLache: v => {
                        const k = v / 30;
                        reglages.changerTheme(["arrondis.panneau=" + Math.round(v), "arrondis.carte=" + Math.round(20 * k), "arrondis.ligne=" + Math.round(12 * k), "arrondis.fenetre=" + Math.round(12 * k)]);
                    }
                }
                LigneInter {
                    titre: "Animations"
                    aide: "Pastille, calendrier, transitions"
                    actif: Theme.animations
                    onBascule: v => reglages.changerTheme(["animations.actives=" + v])
                }
                LigneInter {
                    titre: "Profil économe"
                    aide: "Moins d'effets, pour les ordinateurs modestes"
                    actif: Theme.eco
                    onBascule: v => reglages.changerTheme(["eco=" + (v ? 1 : 0)])
                }
            }
            Carte {
                Layout.fillWidth: true
                Ligne { titre: "Disposition du hub"; valeur: "Tape « personnaliser » dans la recherche" }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Bouton { texte: "Revenir au thème d'origine"; onClic: reglages.changerTheme(["reinitialiser=1", "eco=0"]) }
                }
            }
        }
    }
    function changerTheme(args) {
        agir(["theme"].concat(args), () => reglages.lireEtat(), "Le thème n'a pas pu être appliqué.");
    }

    // ===================== Accessibilité =====================
    Component {
        id: vueAccessibilite
        ColumnLayout {
            spacing: 12
            Carte {
                Layout.fillWidth: true
                LigneSegments {
                    titre: "Taille du texte des applications"
                    choix: [{ nom: "Petit", valeur: 10 }, { nom: "Normal", valeur: 11 }, { nom: "Grand", valeur: 13 }, { nom: "Très grand", valeur: 15 }]
                    valeur: Theme.v("police.taille", 11)
                    onChoisi: v => reglages.changerTheme(["police.taille=" + v])
                }
                LigneSegments {
                    titre: "Taille de tout l'affichage"
                    choix: [{ nom: "100 %", valeur: 1 }, { nom: "125 %", valeur: 1.25 }, { nom: "150 %", valeur: 1.5 }, { nom: "200 %", valeur: 2 }]
                    valeur: reglages.r("ecran.echelle", 1)
                    onChoisi: v => reglages.agir(["entrees", "echelle=" + v], () => reglages.lireEtat())
                }
                LigneInter {
                    titre: "Réduire les animations"
                    aide: "Tout apparaît sans mouvement"
                    actif: !Theme.animations
                    onBascule: v => reglages.changerTheme(["animations.actives=" + !v])
                }
                LigneInter {
                    titre: "Panneaux opaques"
                    aide: "Plus de contraste : le fond ne transparaît plus"
                    actif: Theme.v("transparence.panneau", 0.86) >= 0.99
                    onBascule: v => reglages.changerTheme(["transparence.panneau=" + (v ? "1" : "null")])
                }
            }
        }
    }

    // ===================== Confidentialité =====================
    Component {
        id: vueConfidentialite
        ColumnLayout {
            spacing: 12
            Carte {
                Layout.fillWidth: true
                LigneInter {
                    titre: "Se souvenir des fichiers récents"
                    aide: "Liste des derniers fichiers ouverts dans les applications"
                    actif: reglages.etat.confidentialite ? reglages.etat.confidentialite.recents : true
                    onBascule: v => reglages.agir(["confidentialite", "recents=" + (v ? 1 : 0)], () => reglages.lireEtat())
                }
                LigneInter {
                    titre: "Vider la corbeille automatiquement"
                    aide: "Les fichiers de plus de 30 jours sont supprimés"
                    actif: reglages.etat.confidentialite ? reglages.etat.confidentialite.corbeille : false
                    onBascule: v => reglages.agir(["confidentialite", "corbeille=" + (v ? 1 : 0)], () => reglages.lireEtat())
                }
                Ligne {
                    titre: "Historique du presse-papier"
                    valeur: "Vidé à chaque ouverture de session"
                    bouton: "Vider maintenant"
                    onAction: reglages.agir(["confidentialite", "presse-papier=1"])
                }
                Ligne {
                    titre: "Micro, caméra, partage d'écran"
                    valeur: "Signalés par la pastille dès qu'ils servent"
                }
            }
        }
    }

    // ===================== Applications par défaut =====================
    Component {
        id: vueDefauts
        ColumnLayout {
            id: colDefauts
            spacing: 6
            property string ouvert: ""
            readonly property var genres: [
                { cle: "navigateur", nom: "Navigateur web", cat: ["WebBrowser"] },
                { cle: "courriel", nom: "Courriel", cat: ["Email"] },
                { cle: "fichiers", nom: "Fichiers", cat: ["FileManager"] },
                { cle: "pdf", nom: "Documents PDF", cat: ["Viewer", "Office"] },
                { cle: "images", nom: "Images", cat: ["Graphics", "Viewer"] },
                { cle: "musique", nom: "Musique", cat: ["Audio", "Music"] },
                { cle: "video", nom: "Vidéos", cat: ["Video"] }
            ]
            Etiquette { texte: "Par défaut" }
            Repeater {
                model: colDefauts.genres
                delegate: Rectangle {
                    id: genre
                    required property var modelData
                    readonly property bool deplie: colDefauts.ouvert === modelData.cle
                    readonly property var candidats: DesktopEntries.applications.values.filter(e => !e.noDisplay && (e.categories || []).some(c => genre.modelData.cat.includes(c)))
                    Layout.fillWidth: true
                    implicitHeight: 46 + (deplie ? choixApps.implicitHeight + 8 : 0)
                    radius: 14
                    color: deplie ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.045)
                    RowLayout {
                        x: 14; width: parent.width - 28; height: 46
                        Text { text: genre.modelData.nom; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                        Text {
                            text: reglages.nomAppli(reglages.etat.defauts ? reglages.etat.defauts[genre.modelData.cle] : "")
                            color: Theme.discret; font.family: Theme.police; font.pixelSize: 13
                        }
                        Text { text: genre.deplie ? "⌃" : "⌄"; color: Theme.discret; font.pixelSize: 13 }
                    }
                    MouseArea {
                        width: parent.width; height: 46
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colDefauts.ouvert = genre.deplie ? "" : genre.modelData.cle
                    }
                    Flow {
                        id: choixApps
                        visible: genre.deplie
                        x: 14; y: 46; width: parent.width - 28
                        spacing: 6
                        Repeater {
                            model: genre.candidats
                            delegate: Bouton {
                                required property var modelData
                                texte: modelData.name
                                onClic: {
                                    colDefauts.ouvert = "";
                                    reglages.agir(["defaut", genre.modelData.cle, modelData.id + ".desktop"], () => reglages.lireEtat());
                                }
                            }
                        }
                        Text {
                            visible: genre.candidats.length === 0
                            text: "Aucune application installée pour ça."
                            color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                        }
                    }
                }
            }

            Etiquette { texte: "Au démarrage de la session"; Layout.topMargin: 10 }
            Text {
                visible: reglages.demarrage.length === 0
                text: "Aucune application ne s'ouvre toute seule."
                color: Theme.discret; font.family: Theme.police; font.pixelSize: 13
            }
            Repeater {
                model: reglages.demarrage
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.045)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 8
                        Text { text: parent.parent.modelData.nom; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                        Bouton {
                            texte: "Retirer"
                            onClic: reglages.agir(["demarrage", "retirer", parent.parent.modelData.id], () => reglages.lireDemarrage())
                        }
                    }
                }
            }
            ColumnLayout {
                id: ajoutDemarrage
                Layout.fillWidth: true
                spacing: 6
                property bool ouvert: false
                Bouton { texte: ajoutDemarrage.ouvert ? "Fermer la liste" : "+ Ouvrir une application au démarrage"; onClic: ajoutDemarrage.ouvert = !ajoutDemarrage.ouvert }
                Flow {
                    visible: ajoutDemarrage.ouvert
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ajoutDemarrage.ouvert ? DesktopEntries.applications.values.filter(e => !e.noDisplay && !reglages.demarrage.some(d => d.id === e.id)).sort((x, y) => x.name.localeCompare(y.name)) : []
                        delegate: Bouton {
                            required property var modelData
                            texte: modelData.name
                            onClic: { ajoutDemarrage.ouvert = false; reglages.agir(["demarrage", "ajouter", modelData.id], () => reglages.lireDemarrage(), "Impossible d'ajouter cette application."); }
                        }
                    }
                }
            }
        }
    }

    // ===================== Agendas =====================
    Component {
        id: vueAgendas
        ColumnLayout {
            spacing: 8
            Repeater {
                model: reglages.agendas
                delegate: Rectangle {
                    id: ligneAg
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 16
                    color: Qt.rgba(1, 1, 1, 0.045)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 12
                        Rectangle { implicitWidth: 12; implicitHeight: 12; radius: 6; color: ligneAg.modelData.couleur || Theme.accent }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: ligneAg.modelData.nom; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; font.weight: Font.Medium }
                            Text {
                                readonly property var m: ligneAg.modelData
                                text: m.source + (m.modifiable ? "" : " · lecture seule")
                                color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                            }
                        }
                        Bouton {
                            visible: !!ligneAg.modelData.branchement
                            texte: "Débrancher"
                            onClic: reglages.agirCmd([reglages.outilAgenda, "retirer", ligneAg.modelData.branchement], () => reglages.lireAgendas())
                        }
                    }
                }
            }
            RowLayout {
                Layout.topMargin: 4
                Bouton {
                    texte: "Brancher un agenda"
                    plein: true
                    onClic: reglages.terminal("Brancher un agenda", ["foyer", "agenda", "brancher"])
                }
                Bouton {
                    texte: "Synchroniser maintenant"
                    onClic: reglages.agirCmd([reglages.outilAgenda, "synchroniser", "--silencieux"], () => reglages.lireAgendas())
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Lien iCal (Pronote, ENT, agenda Proton partagé) : lecture seule. Compte CalDAV (Nextcloud, Google, iCloud, Infomaniak…) : lecture et écriture. Mise à jour toutes les 15 minutes."
                color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }

    // ===================== Système =====================
    Component {
        id: vueSysteme
        ColumnLayout {
            spacing: 10
            Carte {
                Layout.fillWidth: true
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Foyer " + (reglages.etat.foyer ? reglages.etat.foyer.version : ""); color: Theme.texte; font.family: Theme.police; font.pixelSize: 16; font.weight: Font.DemiBold }
                        Text { text: "Mises à jour avec instantané Btrfs avant chaque changement"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 12 }
                    }
                    Bouton { texte: "Version précédente"; onClic: reglages.terminal("Foyer", ["foyer", "rollback"]) }
                    Bouton { texte: "Mettre à jour"; plein: true; onClic: reglages.terminal("Foyer", ["foyer", "update"]) }
                }
            }
            Carte {
                id: carteDisque
                Layout.fillWidth: true
                readonly property var d: reglages.etat.disque || { utilise: 0, total: 1 }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Espace disque"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; Layout.fillWidth: true }
                    Text { text: reglages.octets(carteDisque.d.utilise) + " sur " + reglages.octets(carteDisque.d.total); color: Theme.discret; font.family: Theme.police; font.pixelSize: 13 }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.12)
                    Rectangle { width: parent.width * Math.min(1, carteDisque.d.utilise / Math.max(1, carteDisque.d.total)); height: 8; radius: 4; color: Theme.accent }
                }
            }
            Carte {
                Layout.fillWidth: true
                LigneInter {
                    titre: "Date et heure automatiques"
                    aide: "Fuseau : " + (reglages.etat.heure ? reglages.etat.heure.fuseau : "")
                    actif: reglages.etat.heure ? reglages.etat.heure.auto : true
                    onBascule: v => reglages.agir(["heure", v ? 1 : 0], () => reglages.lireEtat())
                }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: {
                        const p = reglages.etat.pc || {};
                        return [["Ordinateur", ((p.fabricant || "") + " " + (p.modele || "")).trim() || "—"], ["Processeur", p.processeur || "—"],
                                ["Mémoire", reglages.octets(p.memoire)], ["Graphismes", Theme.eco ? "Profil économe" : "Profil normal"], ["Noyau Linux", p.noyau || "—"]];
                    }
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 58
                        radius: 14
                        color: Qt.rgba(1, 1, 1, 0.045)
                        Column {
                            x: 14; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 28
                            spacing: 2
                            Text { text: parent.parent.modelData[0]; color: Theme.discret; font.family: Theme.police; font.pixelSize: 12 }
                            Text { width: parent.width; text: parent.parent.modelData[1]; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; elide: Text.ElideRight }
                        }
                    }
                }
            }
            Etiquette { texte: "Instantanés Btrfs"; Layout.topMargin: 6 }
            Carte {
                Layout.fillWidth: true
                Text {
                    visible: !reglages.instantanes.disponible
                    Layout.fillWidth: true
                    text: "Instantanés non disponibles (système de fichiers autre que Btrfs, ou accès pas encore donné : lance foyer update)."
                    color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
                Text {
                    visible: reglages.instantanes.disponible
                    Layout.fillWidth: true
                    text: "Un état du système est gardé avant et après chaque installation. Pour revenir en arrière, redémarre et choisis l'instantané dans le menu de démarrage ; pour récupérer un fichier, parcours-le."
                    color: Theme.discret; font.family: Theme.police; font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
                Repeater {
                    model: reglages.instantanes.liste.slice(0, 8)
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "n° " + modelData.numero; color: Theme.discret; font.family: Theme.police; font.pixelSize: 12; Layout.preferredWidth: 44 }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { Layout.fillWidth: true; text: modelData.description || "Instantané"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 13; elide: Text.ElideRight }
                            Text { text: modelData.date; color: Theme.discret; font.family: Theme.police; font.pixelSize: 11 }
                        }
                        Bouton {
                            texte: "Parcourir"
                            onClic: { Quickshell.execDetached(["xdg-open", "/.snapshots/" + parent.modelData.numero + "/snapshot"]); reglages.fermer(); }
                        }
                    }
                }
                RowLayout {
                    visible: reglages.instantanes.disponible
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Bouton { texte: "Créer un instantané maintenant"; onClic: reglages.agir(["instantanes", "creer"], () => reglages.lireInstantanes(), "Instantané non créé.") }
                }
            }
            Lien {
                texte: "Imprimantes…"
                onClic: { Qt.openUrlExternally("http://localhost:631"); reglages.fermer(); }
            }
        }
    }

    // --- Petits éléments réutilisés ----------------------------------------------------
    component Etiquette: Text {
        property string texte
        text: texte.toUpperCase()
        color: Theme.discret
        font.family: Theme.police
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1.8
    }
    component Carte: Rectangle {
        default property alias contenu: colonne.data
        implicitHeight: colonne.implicitHeight + 28
        radius: 18
        color: Qt.rgba(1, 1, 1, 0.045)
        ColumnLayout {
            id: colonne
            x: 14
            y: 14
            width: parent.width - 28
            spacing: 10
        }
    }
    component Ligne: RowLayout {
        id: ligne
        property string titre
        property string valeur
        property string bouton
        signal action
        Layout.fillWidth: true
        implicitHeight: 34
        spacing: 12
        Text { text: ligne.titre; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14 }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: ligne.valeur
            color: Theme.discret
            font.family: Theme.police
            font.pixelSize: 13
            elide: Text.ElideRight
        }
        Bouton {
            visible: ligne.bouton !== ""
            texte: ligne.bouton
            onClic: ligne.action()
        }
    }
    component LigneInter: RowLayout {
        id: li
        property string titre
        property string aide
        property bool actif
        signal bascule(bool valeur)
        Layout.fillWidth: true
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: li.titre; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14 }
            Text { visible: li.aide !== ""; Layout.fillWidth: true; text: li.aide; color: Theme.discret; font.family: Theme.police; font.pixelSize: 12; wrapMode: Text.Wrap }
        }
        Interrupteur { actif: li.actif; onBascule: v => li.bascule(v) }
    }
    component LigneSegments: RowLayout {
        id: ls
        property string titre
        property var choix: []
        property var valeur
        signal choisi(var valeur)
        Layout.fillWidth: true
        spacing: 12
        Text { Layout.fillWidth: true; text: ls.titre; color: Theme.texte; font.family: Theme.police; font.pixelSize: 14; wrapMode: Text.Wrap }
        Segments { choix: ls.choix; valeur: ls.valeur; onChoisi: v => ls.choisi(v) }
    }
    component ChoixRadio: Rectangle {
        id: radio
        property string texte
        property bool pris
        signal clic
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 10
        color: pris ? Qt.rgba(1, 1, 1, 0.07) : (zoneRadio.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent")
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            Rectangle {
                implicitWidth: 14; implicitHeight: 14; radius: 7
                color: radio.pris ? Theme.accent : "transparent"
                border.width: 2
                border.color: radio.pris ? Theme.accent : Qt.rgba(Theme.texte.r, Theme.texte.g, Theme.texte.b, 0.35)
            }
            Text { Layout.fillWidth: true; text: radio.texte; color: Theme.texte; font.family: Theme.police; font.pixelSize: 13; elide: Text.ElideRight }
        }
        MouseArea { id: zoneRadio; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: radio.clic() }
    }
    component Lien: Text {
        id: lien
        property string texte
        signal clic
        text: texte
        color: Theme.accent
        font.family: Theme.police
        font.pixelSize: 13
        font.weight: Font.Medium
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: lien.clic() }
    }
}
