// Géré par Foyer. La pastille, en bas au centre : notifications (elle remplace
// mako), historique, témoins micro / caméra / partage d'écran, et affichages
// système (volume, luminosité, batterie faible). Tout naît de la même pilule,
// avec la même animation : elle s'étire, montre l'information, se replie.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: pastille

    property bool historique: false
    property bool nePasDeranger: false
    property string mode: ""            // "" | notif | volume | luminosite | batterie
    property var notifCourante: null
    property int nonLues: 0
    property int niveauLum: 0
    property var arrivees: ({})
    property bool serveurPret: false
    property bool osdPret: false

    anchors.bottom: true
    implicitWidth: 560
    implicitHeight: 600
    color: "transparent"
    WlrLayershell.namespace: "foyer-pastille"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: historique ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // Seule la pilule (et l'historique ouvert) reçoit la souris : le reste de la
    // fenêtre est transparent aux clics.
    mask: Region {
        item: zone
    }

    // --- Démarrage : mako s'arrête, la pastille prend les notifications --------
    Component.onCompleted: Quickshell.execDetached(["pkill", "-x", "mako"])
    Timer {
        interval: 900
        running: true
        onTriggered: pastille.serveurPret = true
    }
    Timer {
        interval: 4000
        running: true
        onTriggered: pastille.osdPret = true
    }

    LazyLoader {
        id: chargeurServeur
        active: pastille.serveurPret

        NotificationServer {
            keepOnReload: true
            bodySupported: true
            actionsSupported: true
            imageSupported: true
            onNotification: n => {
                n.tracked = true;
                const a = Object.assign({}, pastille.arrivees);
                a[n.id] = new Date();
                pastille.arrivees = a;
                if (!pastille.historique)
                    pastille.nonLues++;
                if (!pastille.nePasDeranger || Number(n.urgency) === 2)
                    pastille.montrerNotif(n);
            }
        }
    }

    readonly property var notifications: chargeurServeur.item ? chargeurServeur.item.trackedNotifications.values.slice().reverse() : []

    function montrerNotif(n) {
        notifCourante = n;
        mode = "notif";
        minuteur.interval = 8000;
        minuteur.restart();
    }

    function montrerOsd(m) {
        if (!osdPret)
            return;
        if (mode === "notif" && minuteur.running && m !== "batterie")
            return;  // une notification en cours garde la priorité
        mode = m;
        minuteur.interval = m === "batterie" ? 9000 : 2600;
        minuteur.restart();
    }

    Timer {
        id: minuteur
        onTriggered: pastille.mode = ""
    }

    function basculerHistorique() {
        historique = !historique;
        if (historique) {
            nonLues = 0;
            mode = "";
        }
    }

    function heure(n) {
        const d = arrivees[n.id];
        return d ? Qt.formatDateTime(d, "HH:mm") : "";
    }

    function icone(n) {
        if (!n)
            return "";
        if (n.image)
            return n.image.startsWith("/") ? "file://" + n.image : n.image;
        if (n.appIcon)
            return n.appIcon.startsWith("/") ? "file://" + n.appIcon : Quickshell.iconPath(n.appIcon, true);
        return "";
    }

    function ouvrirNotif(n) {
        const defaut = (n.actions || []).find(a => a.identifier === "default");
        if (defaut)
            defaut.invoke();
        n.dismiss();
    }

    // --- Volume (PipeWire) ------------------------------------------------------
    readonly property var sortie: Pipewire.defaultAudioSink
    PwObjectTracker {
        objects: [pastille.sortie]
    }
    readonly property real volume: sortie && sortie.audio ? sortie.audio.volume : 0
    readonly property bool muet: sortie && sortie.audio ? sortie.audio.muted : false
    onVolumeChanged: montrerOsd("volume")
    onMuetChanged: montrerOsd("volume")

    // --- Luminosité (appelée par les touches, via IPC) --------------------------
    Process {
        id: lireLum
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: data => {
                const champs = data.split(",");
                if (champs.length >= 4)
                    pastille.niveauLum = parseInt(champs[3]);
            }
        }
        onExited: pastille.montrerOsd("luminosite")
    }
    function luminosite() {
        lireLum.running = false;
        lireLum.running = true;
    }

    // --- Batterie faible ---------------------------------------------------------
    readonly property var batt: UPower.displayDevice
    readonly property real pctBatt: batt ? batt.percentage : 1
    property bool alerteBatterie: false
    onPctBattChanged: verifierBatterie()
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            pastille.verifierBatterie();
        }
    }
    function verifierBatterie() {
        if (!batt || !batt.isLaptopBattery)
            return;
        if (!UPower.onBattery) {
            alerteBatterie = false;
            return;
        }
        if (pctBatt <= 0.10 && !alerteBatterie) {
            alerteBatterie = true;
            montrerOsd("batterie");
        }
    }

    // --- Témoins vie privée (flux PipeWire qui enregistrent) ---------------------
    readonly property var flux: Pipewire.nodes.values.filter(n => n.isStream)
    PwObjectTracker {
        objects: pastille.flux
    }
    function proprietes(n) {
        return n.properties || {};
    }
    function ignore(n) {
        const p = proprietes(n);
        const app = String(p["application.name"] || "").toLowerCase();
        return p["stream.capture.sink"] === "true" || app.includes("cava") || app.includes("quickshell") || app.includes("pavucontrol");
    }
    readonly property var micros: flux.filter(n => proprietes(n)["media.class"] === "Stream/Input/Audio" && !ignore(n))
    readonly property var videos: flux.filter(n => proprietes(n)["media.class"] === "Stream/Input/Video" && !ignore(n))
    function nomsApplis(liste) {
        return liste.map(n => proprietes(n)["application.name"] || n.description || n.name).filter((x, i, t) => x && t.indexOf(x) === i).join(", ");
    }
    readonly property bool temoins: micros.length > 0 || videos.length > 0

    // Au repos (rien à montrer), la pastille disparaît. Elle revient pour une
    // notification, un affichage, un témoin, des notifications non lues, ou quand
    // la souris passe tout en bas au centre de l'écran.
    property bool survolBas: false
    readonly property bool active: mode !== "" || historique || temoins || nonLues > 0 || survolBas
    readonly property int dureeAnim: Math.round(Theme.duree * 1.5)
    Timer {
        id: delaiDisparition
        interval: 700
        onTriggered: pastille.survolBas = false
    }

    // --- Taille de la pilule selon ce qu'elle montre -----------------------------
    readonly property size taille: {
        switch (mode) {
        case "notif":
            return Qt.size(460, 64);
        case "volume":
        case "luminosite":
            return Qt.size(348, 52);
        case "batterie":
            return Qt.size(440, 60);
        }
        return Qt.size(52 + (temoins ? rangTemoins.implicitWidth + 12 : 0) + (nonLues > 0 ? 22 : 0), 36);
    }

    // Zone qui reçoit la souris : la pilule, plus l'historique s'il est ouvert.
    Item {
        id: zone
        readonly property real largeur: pastille.active ? Math.max(pilule.width, panneau.visible ? panneau.width : 0) : 280
        x: (pastille.width - largeur) / 2
        y: !pastille.active ? pastille.height - 8 : (panneau.visible ? panneau.y : pilule.y)
        width: largeur
        height: pastille.height - y
        // Survol : fait apparaître la pastille (bande fine tout en bas quand elle est cachée)
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onContainsMouseChanged: {
                if (containsMouse) {
                    delaiDisparition.stop();
                    pastille.survolBas = true;
                } else {
                    delaiDisparition.restart();
                }
            }
        }
    }

    // ===================== La pilule =====================
    Rectangle {
        id: pilule
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: pastille.taille.width
        height: pastille.taille.height
        radius: height / 2
        opacity: pastille.active ? 1 : 0
        scale: pastille.active ? 1 : 0.6
        transformOrigin: Item.Bottom
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: pastille.dureeAnim * 0.6 }
        }
        Behavior on scale {
            NumberAnimation {
                duration: pastille.dureeAnim
                easing.type: Easing.OutBack
            }
        }
        color: Theme.panneau
        border.width: 1
        border.color: pastille.mode === "notif" || pastille.mode === "batterie" || pastille.historique ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55) : Theme.trait
        clip: true
        Behavior on width {
            NumberAnimation {
                duration: pastille.dureeAnim
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: pastille.dureeAnim
                easing.type: Easing.OutBack
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (pastille.mode === "notif" && pastille.notifCourante) {
                    pastille.ouvrirNotif(pastille.notifCourante);
                    pastille.mode = "";
                } else {
                    pastille.basculerHistorique();
                }
            }
        }

        // Repos : le logo (éteint, ou allumé s'il y a des notifications non lues),
        // et les témoins vie privée s'ils sont actifs.
        Row {
            anchors.centerIn: parent
            spacing: 8
            opacity: pastille.mode === "" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: 160 }
            }
            Logo {
                anchors.verticalCenter: parent.verticalCenter
                allume: pastille.nonLues > 0
                taille: 18
            }
            Text {
                visible: pastille.nonLues > 0
                anchors.verticalCenter: parent.verticalCenter
                text: pastille.nonLues
                color: Theme.accentClair
                font.family: Theme.police
                font.pixelSize: 13
                font.weight: Font.Bold
            }
            Rectangle {
                visible: pastille.temoins
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: Theme.trait
            }
            Row {
                id: rangTemoins
                visible: pastille.temoins
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Temoin {
                    visible: pastille.micros.length > 0
                    libelle: "Micro"
                    couleur: Theme.accent
                    applis: pastille.nomsApplis(pastille.micros)
                }
                Temoin {
                    visible: pastille.videos.length > 0
                    libelle: "Caméra / écran"
                    couleur: Theme.accentClair
                    applis: pastille.nomsApplis(pastille.videos)
                }
            }
        }

        // Notification
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 20
            spacing: 12
            opacity: pastille.mode === "notif" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                Logo {
                    anchors.centerIn: parent
                    taille: 22
                    SequentialAnimation on scale {
                        running: pastille.mode === "notif" && !Theme.eco
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.08; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.96; duration: 500; easing.type: Easing.InOutSine }
                    }
                }
            }
            Image {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                source: pastille.icone(pastille.notifCourante)
                sourceSize.width: 28
                sourceSize.height: 28
                visible: source != ""
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: pastille.notifCourante ? (pastille.notifCourante.appName || pastille.notifCourante.summary) : ""
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: pastille.notifCourante ? [pastille.notifCourante.appName ? pastille.notifCourante.summary : "", pastille.notifCourante.body].filter(s => s).join(" — ") : ""
                    color: Theme.discret
                    font.family: Theme.police
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }
            }
            Text {
                text: "maintenant"
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 12
            }
        }

        // Volume et luminosité
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14
            opacity: pastille.mode === "volume" || pastille.mode === "luminosite" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            Icone {
                nom: pastille.mode === "luminosite" ? "luminosite" : (pastille.muet ? "muet" : "volume")
                taille: 20
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.14)
                Rectangle {
                    readonly property real niveau: pastille.mode === "luminosite" ? pastille.niveauLum / 100 : (pastille.muet ? 0 : Math.min(1, pastille.volume))
                    width: parent.width * niveau
                    height: parent.height
                    radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.accentFonce }
                        GradientStop { position: 0.6; color: Theme.accent }
                        GradientStop { position: 1; color: Theme.accentClair }
                    }
                    Behavior on width {
                        NumberAnimation { duration: 120 }
                    }
                }
            }
            Text {
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
                text: pastille.mode === "luminosite" ? pastille.niveauLum : (pastille.muet ? "—" : Math.round(pastille.volume * 100))
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        // Batterie faible
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 8
            spacing: 14
            opacity: pastille.mode === "batterie" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            Icone {
                nom: "batterie"
                couleur: Theme.accent
                taille: 22
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text {
                    text: "Batterie faible — " + Math.round(pastille.pctBatt * 100) + " %"
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Branche le chargeur"
                    color: Theme.discret
                    font.family: Theme.police
                    font.pixelSize: 12
                }
            }
            Rectangle {
                Layout.preferredHeight: 44
                Layout.preferredWidth: texteEco.implicitWidth + 32
                radius: 22
                color: Theme.accent
                Text {
                    id: texteEco
                    anchors.centerIn: parent
                    text: "Économie d'énergie"
                    color: Theme.surAccent
                    font.family: Theme.police
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Quickshell.execDetached(["powerprofilesctl", "set", "power-saver"]);
                        pastille.mode = "";
                    }
                }
            }
        }
    }

    // ===================== L'historique =====================
    Rectangle {
        id: panneau
        visible: pastille.historique
        width: 420
        height: Math.min(470, entetePanneau.height + 36 + (pastille.notifications.length === 0 ? 60 : listeNotifs.contentHeight))
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: pilule.top
        anchors.bottomMargin: 12
        radius: 26
        color: Theme.panneau
        border.width: 1
        border.color: Theme.trait
        focus: visible
        Keys.onEscapePressed: pastille.historique = false

        RowLayout {
            id: entetePanneau
            x: 18
            y: 16
            width: parent.width - 36
            height: 32
            spacing: 6
            Text {
                text: "Notifications"
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Pilule {
                libelle: pastille.nePasDeranger ? "Ne pas déranger : oui" : "Ne pas déranger"
                actif: pastille.nePasDeranger
                onClic: pastille.nePasDeranger = !pastille.nePasDeranger
            }
            Pilule {
                libelle: "Tout effacer"
                onClic: {
                    for (const n of pastille.notifications.slice())
                        n.dismiss();
                }
            }
        }

        Text {
            visible: pastille.notifications.length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: entetePanneau.y + entetePanneau.height + 22
            text: "Aucune notification"
            color: Theme.discret
            font.family: Theme.police
            font.pixelSize: 13
        }

        ListView {
            id: listeNotifs
            x: 18
            y: entetePanneau.y + entetePanneau.height + 12
            width: parent.width - 36
            height: parent.height - y - 18
            clip: true
            spacing: 8
            model: pastille.notifications
            delegate: Rectangle {
                id: carteNotif
                required property var modelData
                width: listeNotifs.width
                height: contenuNotif.implicitHeight + 24
                radius: 16
                color: zoneNotif.containsMouse ? Theme.carteChoisie : Theme.carte

                RowLayout {
                    id: contenuNotif
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 12
                    Image {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignTop
                        source: pastille.icone(carteNotif.modelData)
                        sourceSize.width: 32
                        sourceSize.height: 32
                    }
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: carteNotif.modelData.appName || carteNotif.modelData.summary
                                color: Theme.texte
                                font.family: Theme.police
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: pastille.heure(carteNotif.modelData)
                                color: Theme.discret
                                font.family: Theme.police
                                font.pixelSize: 11
                            }
                        }
                        Text {
                            text: [carteNotif.modelData.appName ? carteNotif.modelData.summary : "", carteNotif.modelData.body].filter(s => s).join(" — ")
                            color: Theme.discret
                            font.family: Theme.police
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    Bouton {
                        glyphe: "✕"
                        rond: true
                        Layout.alignment: Qt.AlignTop
                        onClic: carteNotif.modelData.dismiss()
                    }
                }
                MouseArea {
                    id: zoneNotif
                    anchors.fill: parent
                    anchors.rightMargin: 48
                    hoverEnabled: true
                    onClicked: pastille.ouvrirNotif(carteNotif.modelData)
                }
            }
        }
    }

    component Temoin: Rectangle {
        property string libelle
        property color couleur
        property string applis
        implicitWidth: texteTemoin.implicitWidth + 18
        implicitHeight: 22
        radius: 11
        color: couleur
        Text {
            id: texteTemoin
            anchors.centerIn: parent
            text: "● " + parent.libelle
            color: "#1a1210"
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    component Pilule: Rectangle {
        property string libelle
        property bool actif: false
        signal clic
        implicitWidth: textePilule.implicitWidth + 24
        implicitHeight: 30
        radius: 15
        color: actif ? Theme.accent : Theme.bouton
        Text {
            id: textePilule
            anchors.centerIn: parent
            text: parent.libelle
            color: parent.actif ? Theme.surAccent : Theme.texte
            font.family: Theme.police
            font.pixelSize: 12
            font.weight: Font.Medium
        }
        MouseArea {
            anchors.fill: parent
            onClicked: parent.clic()
        }
    }
}
