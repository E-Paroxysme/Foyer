// Géré par Foyer. Vue calendrier du hub (maquette Q validée) : grille du mois avec
// un point par agenda, liste du jour, détails (visio, notes), ajout en une phrase
// (« réunion de 14h à 15h // salle B12 »), agendas affichables ou masquables.
// Les données viennent de bin/foyer-agenda (khal + vdirsyncer).
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: agenda

    property bool actif: false
    property real hauteurMax: 560
    signal fermer

    property date dateRef: new Date()
    property int moisDecalage: 0
    property int jourChoisi: 0
    property var agendas: []
    property var evenements: []
    property string ouvert: ""           // uid + date de l'événement déplié
    property string message: ""
    property var edition: null           // événement en cours de modification

    readonly property string script: Quickshell.env("HOME") + "/.local/share/foyer/bin/foyer-agenda"
    readonly property date moisAffiche: new Date(dateRef.getFullYear(), dateRef.getMonth() + moisDecalage, 1)
    readonly property int jourAffiche: jourChoisi > 0 ? jourChoisi : (moisDecalage === 0 ? dateRef.getDate() : 1)
    readonly property string cleMois: moisAffiche.getFullYear() + "-" + String(moisAffiche.getMonth() + 1).padStart(2, "0")
    readonly property var apercu: champ.text.trim().length > 0 ? analyser(champ.text, new Date(moisAffiche.getFullYear(), moisAffiche.getMonth(), jourAffiche)) : null
    readonly property var nomsMois: ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    readonly property var nomsJours: ["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."]

    implicitHeight: hauteurMax

    function ouvrir() {
        dateRef = new Date();
        moisDecalage = 0;
        jourChoisi = 0;
        ouvert = "";
        champ.text = "";
        message = "";
        edition = null;
        charger();
        champ.forceActiveFocus();
    }

    function decaler(sens) {
        moisDecalage += sens;
        jourChoisi = 0;
        ouvert = "";
    }
    onCleMoisChanged: if (actif) charger()

    // --- Données --------------------------------------------------------------
    function charger() {
        lecture.running = false;
        lecture.command = [script, "mois", cleMois];
        lecture.running = true;
    }
    Process {
        id: lecture
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    agenda.agendas = d.agendas || [];
                    agenda.evenements = d.evenements || [];
                } catch (e) {
                    console.warn("agenda illisible : " + e);
                }
            }
        }
    }
    Process {
        id: action
        stderr: StdioCollector { id: erreurAction }
        onExited: code => {
            if (code !== 0)
                agenda.message = erreurAction.text.trim() || "L'agenda n'a pas pu être modifié.";
            agenda.charger();
        }
    }
    function lancer(commande) {
        action.running = false;
        action.command = commande;
        action.running = true;
    }

    function infoAgenda(id) {
        for (const a of agendas)
            if (a.id === id)
                return a;
        return { id: id, nom: id, couleur: "", modifiable: false, visible: true };
    }
    function couleur(id) {
        const a = infoAgenda(id);
        return a.couleur ? a.couleur : Theme.accent;
    }
    function visibles() {
        return evenements.filter(e => infoAgenda(e.agenda).visible !== false);
    }
    function iso(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }
    function duJour(j) {
        const cle = iso(new Date(moisAffiche.getFullYear(), moisAffiche.getMonth(), j));
        return visibles().filter(e => e.date <= cle && (e.dateFin || e.date) >= cle).sort((a, b) => (a.journee ? "" : a.debut).localeCompare(b.journee ? "" : b.debut));
    }

    function cases() {
        const an = moisAffiche.getFullYear(), m = moisAffiche.getMonth();
        const premier = (new Date(an, m, 1).getDay() + 6) % 7;
        const nb = new Date(an, m + 1, 0).getDate();
        const auj = new Date(dateRef.getFullYear(), dateRef.getMonth(), dateRef.getDate()).getTime();
        const res = [];
        for (let i = 0; i < premier; i++)
            res.push({ jour: 0, points: [] });
        for (let j = 1; j <= nb; j++) {
            const t = new Date(an, m, j).getTime();
            const coul = [];
            for (const e of duJour(j)) {
                const c = String(couleur(e.agenda));
                if (!coul.includes(c) && coul.length < 3)
                    coul.push(c);
            }
            res.push({ jour: j, passe: t < auj, aujourdhui: t === auj, points: coul });
        }
        return res;
    }

    // --- Lecture d'une phrase : date, horaires, lien, notes, titre ------------
    function analyser(texte, base) {
        let t = " " + texte + " ";
        const r = { date: new Date(base), debut: null, fin: null, lien: "", note: "", titre: "" };
        const lien = t.match(/https?:\/\/\S+/i);
        if (lien) { r.lien = lien[0]; t = t.replace(lien[0], " "); }
        const morceaux = t.split("//");
        if (morceaux.length > 1) { r.note = morceaux.slice(1).join("//").trim(); t = morceaux[0] + " "; }
        const h = s => { const m = s.match(/(\d{1,2})\s*(?:h|:)\s*(\d{2})?/i); return m ? [Number(m[1]), Number(m[2] || 0)] : null; };
        const plage = t.match(/\s(?:de\s+)?(\d{1,2}\s*(?:h|:)\s*\d{0,2})\s*(?:à|a|-|–|jusqu'à)\s*(\d{1,2}\s*(?:h|:)\s*\d{0,2})/i);
        if (plage) { r.debut = h(plage[1]); r.fin = h(plage[2]); t = t.replace(plage[0], " "); }
        else {
            const seul = t.match(/\s(?:à\s+)?(\d{1,2}\s*(?:h|:)\s*\d{0,2})(?=\s)/i);
            if (seul) { r.debut = h(seul[1]); r.fin = [Math.min(23, r.debut[0] + 1), r.debut[1]]; t = t.replace(seul[0], " "); }
        }
        const jours = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"];
        const auj = new Date(); auj.setHours(0, 0, 0, 0);
        let m;
        if ((m = t.match(/\s(après-demain)\s/i))) { r.date = new Date(auj.getFullYear(), auj.getMonth(), auj.getDate() + 2); t = t.replace(m[1], " "); }
        else if ((m = t.match(/\s(demain)\s/i))) { r.date = new Date(auj.getFullYear(), auj.getMonth(), auj.getDate() + 1); t = t.replace(m[1], " "); }
        else if ((m = t.match(/\s(aujourd'hui|aujourd’hui)\s/i))) { r.date = auj; t = t.replace(m[1], " "); }
        else if ((m = t.match(new RegExp("\\s(?:le\\s+)?(\\d{1,2})\\s+(" + nomsMois.join("|") + ")(?:\\s+(\\d{4}))?\\s", "i")))) { r.date = new Date(m[3] ? Number(m[3]) : auj.getFullYear(), nomsMois.indexOf(m[2].toLowerCase()), Number(m[1])); t = t.replace(m[0], " "); }
        else if ((m = t.match(/\s(?:le\s+)?(\d{1,2})\/(\d{1,2})\s/))) { r.date = new Date(auj.getFullYear(), Number(m[2]) - 1, Number(m[1])); t = t.replace(m[0], " "); }
        else if ((m = t.match(new RegExp("\\s(" + jours.join("|") + ")(?:\\s+prochain)?\\s", "i")))) { const cible = jours.indexOf(m[1].toLowerCase()); const d = new Date(auj); d.setDate(d.getDate() + ((cible - d.getDay() + 7) % 7 || 7)); r.date = d; t = t.replace(m[0], " "); }
        else if ((m = t.match(/\sle\s+(\d{1,2})\s/i))) { r.date = new Date(base.getFullYear(), base.getMonth(), Number(m[1])); t = t.replace(m[0], " "); }
        r.titre = t.replace(/\s+/g, " ").trim();
        r.titre = r.titre.charAt(0).toUpperCase() + r.titre.slice(1);
        return r;
    }
    function hh(x) {
        return String(x[0]).padStart(2, "0") + ":" + String(x[1]).padStart(2, "0");
    }
    // Phrase équivalente à un événement existant : on la remet dans le champ
    // pour la modifier, puis « Enregistrer » remplace l'événement.
    function phrase(e) {
        const d = new Date(e.date + "T00:00:00");
        let t = "le " + d.getDate() + " " + nomsMois[d.getMonth()];
        if (d.getFullYear() !== new Date().getFullYear())
            t += " " + d.getFullYear();
        if (e.debut)
            t += " de " + e.debut.replace(":", "h") + " à " + (e.fin || e.debut).replace(":", "h");
        t += " " + e.titre;
        if (e.lien)
            t += " " + e.lien;
        if (e.note)
            t += " // " + e.note.replace(/\s*\n\s*/g, " ");
        return t;
    }
    function modifier(e) {
        edition = e;
        ouvert = "";
        message = "";
        champ.text = phrase(e);
        champ.forceActiveFocus();
        champ.cursorPosition = champ.text.length;
    }
    function annulerEdition() {
        edition = null;
        champ.text = "";
        message = "";
    }
    function ajouter() {
        const p = apercu;
        if (!p || !p.titre)
            return;
        const cmd = [script, "ajouter", "--date", iso(p.date), "--titre", p.titre];
        if (edition)
            cmd.push("--remplace", edition.uid);
        if (p.debut) cmd.push("--debut", hh(p.debut), "--fin", hh(p.fin));
        if (p.lien) cmd.push("--lien", p.lien);
        if (p.note) cmd.push("--note", p.note);
        lancer(cmd);
        // Aller au jour de l'événement ajouté
        moisDecalage = (p.date.getFullYear() - dateRef.getFullYear()) * 12 + p.date.getMonth() - dateRef.getMonth();
        jourChoisi = p.date.getDate();
        champ.text = "";
        message = "";
        edition = null;
    }

    // --- Interface ------------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Text {
                text: agenda.jourAffiche
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: 72
                font.weight: Font.ExtraBold
                font.letterSpacing: -4
                Layout.preferredHeight: 62
                verticalAlignment: Text.AlignBottom
            }
            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignBottom
                Text {
                    text: agenda.nomsMois[agenda.moisAffiche.getMonth()].toUpperCase()
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    font.letterSpacing: 0.5
                }
                Text {
                    text: agenda.moisAffiche.getFullYear() + " · " + agenda.nomsJours[new Date(agenda.moisAffiche.getFullYear(), agenda.moisAffiche.getMonth(), agenda.jourAffiche).getDay()]
                    color: Theme.discret
                    font.family: Theme.police
                    font.pixelSize: 18
                    font.weight: Font.Light
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Bouton {
                glyphe: "‹"
                rond: true
                onClic: agenda.decaler(-1)
            }
            Bouton {
                glyphe: "›"
                rond: true
                onClic: agenda.decaler(1)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 22

            // Colonne de gauche : grille et agendas
            ColumnLayout {
                Layout.preferredWidth: 292
                Layout.maximumWidth: 292
                Layout.fillHeight: true
                spacing: 12

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 6
                    Repeater {
                        model: ["L", "M", "M", "J", "V", "S", "D"]
                        delegate: Text {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.discret
                            font.family: Theme.police
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                    Repeater {
                        model: agenda.actif ? agenda.cases() : []
                        delegate: Item {
                            id: caseJour
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 36
                            Rectangle {
                                id: rond
                                visible: caseJour.modelData.jour > 0
                                anchors.centerIn: parent
                                width: 34
                                height: 34
                                radius: 17
                                color: caseJour.modelData.aujourdhui ? Theme.accent : (caseJour.modelData.passe ? Theme.texte : "transparent")
                                border.width: caseJour.modelData.aujourdhui || caseJour.modelData.passe ? 0 : 1.5
                                border.color: Qt.rgba(Theme.texte.r, Theme.texte.g, Theme.texte.b, 0.22)
                                opacity: 0
                                scale: 0.4
                                SequentialAnimation {
                                    id: apparition
                                    PauseAnimation { duration: Theme.duree * 0.3 + caseJour.index * (Theme.eco ? 0 : 8) }
                                    ParallelAnimation {
                                        NumberAnimation { target: rond; property: "opacity"; to: 1; duration: 200 }
                                        NumberAnimation { target: rond; property: "scale"; to: 1; duration: 240; easing.type: Easing.OutBack }
                                    }
                                }
                                Component.onCompleted: apparition.start()
                                Rectangle {
                                    anchors.centerIn: parent
                                    visible: caseJour.modelData.jour === agenda.jourAffiche && !caseJour.modelData.aujourdhui
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: "transparent"
                                    border.width: 2
                                    border.color: Theme.accent
                                }
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 5
                                    spacing: 2
                                    Repeater {
                                        model: caseJour.modelData.points
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 4
                                            height: 4
                                            radius: 2
                                            // Sur un rond plein (aujourd'hui, jours passés), un point sombre reste lisible.
                                            color: caseJour.modelData.aujourdhui || caseJour.modelData.passe ? Theme.panneau : modelData
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        agenda.jourChoisi = caseJour.modelData.jour;
                                        agenda.ouvert = "";
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.trait
                }
                Text {
                    text: "AGENDAS"
                    color: Theme.discret
                    font.family: Theme.police
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.8
                }
                Repeater {
                    model: agenda.agendas
                    delegate: Item {
                        id: ligneAgenda
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 26
                        opacity: modelData.visible === false ? 0.4 : 1
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 10
                                height: 10
                                radius: 5
                                color: ligneAgenda.modelData.couleur || Theme.accent
                            }
                            Text {
                                text: ligneAgenda.modelData.nom
                                color: Theme.texte
                                font.family: Theme.police
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: 170
                            }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: ligneAgenda.modelData.source
                            color: Theme.discret
                            font.family: Theme.police
                            font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const liste = agenda.agendas.slice();
                                for (let i = 0; i < liste.length; i++)
                                    if (liste[i].id === ligneAgenda.modelData.id)
                                        liste[i] = Object.assign({}, liste[i], { visible: liste[i].visible === false });
                                agenda.agendas = liste;
                                agenda.lancer([agenda.script, "masquer", ligneAgenda.modelData.id]);
                            }
                        }
                    }
                }
                Text {
                    text: "+  Brancher un agenda (CalDAV ou lien iCal)"
                    color: Theme.accent
                    font.family: Theme.police
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["uwsm", "app", "--", "foot", "-T", "Brancher un agenda", "foyer", "agenda", "brancher"]);
                            agenda.fermer();
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }

            // Colonne de droite : le jour choisi et l'ajout
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Text {
                    readonly property date d: new Date(agenda.moisAffiche.getFullYear(), agenda.moisAffiche.getMonth(), agenda.jourAffiche)
                    readonly property bool estAujourdhui: agenda.iso(d) === agenda.iso(new Date())
                    text: ((estAujourdhui ? "Aujourd’hui · " : "") + agenda.nomsJours[d.getDay()] + " " + agenda.jourAffiche + " " + agenda.nomsMois[d.getMonth()]).toUpperCase()
                    color: Theme.discret
                    font.family: Theme.police
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.8
                }

                ListView {
                    id: liste
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: agenda.actif ? agenda.duJour(agenda.jourAffiche) : []
                    boundsBehavior: Flickable.StopAtBounds

                    Text {
                        visible: liste.count === 0
                        y: 14
                        text: "Rien de prévu. Ajoute quelque chose en dessous."
                        color: Theme.discret
                        font.family: Theme.police
                        font.pixelSize: 14
                    }

                    delegate: Rectangle {
                        id: carte
                        required property var modelData
                        readonly property string cle: modelData.uid + modelData.date
                        readonly property bool deplie: agenda.ouvert === cle
                        readonly property var info: agenda.infoAgenda(modelData.agenda)
                        width: liste.width
                        implicitHeight: contenu.implicitHeight + 20
                        radius: 16
                        color: deplie ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.035)
                        border.width: 1
                        border.color: deplie ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45) : Qt.rgba(1, 1, 1, 0.06)
                        Behavior on implicitHeight {
                            NumberAnimation { duration: Theme.duree * 0.6; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            x: 12
                            y: 10
                            width: 4
                            height: 34
                            radius: 2
                            color: agenda.couleur(carte.modelData.agenda)
                        }
                        ColumnLayout {
                            id: contenu
                            x: 28
                            y: 10
                            width: carte.width - 40
                            spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: carte.modelData.titre
                                        color: Theme.texte
                                        font.family: Theme.police
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: (carte.modelData.journee ? "Toute la journée" : carte.modelData.debut + " – " + carte.modelData.fin) + " · " + carte.info.nom
                                        color: Theme.discret
                                        font.family: Theme.police
                                        font.pixelSize: 12
                                    }
                                }
                                Icone {
                                    visible: carte.modelData.visio
                                    nom: "visio"
                                    taille: 16
                                    couleur: Theme.accentClair
                                }
                                Icone {
                                    visible: carte.modelData.note.length > 0
                                    nom: "note"
                                    taille: 16
                                    couleur: Theme.discret
                                }
                            }
                            Text {
                                visible: carte.deplie && carte.modelData.note.length > 0
                                Layout.fillWidth: true
                                text: carte.modelData.note
                                color: Qt.rgba(Theme.texte.r, Theme.texte.g, Theme.texte.b, 0.75)
                                font.family: Theme.police
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                lineHeight: 1.15
                            }
                            Row {
                                visible: carte.deplie
                                spacing: 8
                                Bouton {
                                    visible: carte.modelData.lien.length > 0
                                    texte: carte.modelData.visio ? "Rejoindre la visio" : "Ouvrir le lien"
                                    plein: true
                                    onClic: {
                                        Qt.openUrlExternally(carte.modelData.lien);
                                        agenda.fermer();
                                    }
                                }
                                Bouton {
                                    visible: carte.info.modifiable
                                    texte: "Modifier"
                                    onClic: agenda.modifier(carte.modelData)
                                }
                                Bouton {
                                    visible: carte.info.modifiable
                                    texte: "Supprimer"
                                    onClic: {
                                        agenda.ouvert = "";
                                        agenda.lancer([agenda.script, "supprimer", carte.modelData.uid]);
                                    }
                                }
                                Text {
                                    visible: !carte.info.modifiable
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Lecture seule : vient de " + carte.info.nom
                                    color: Theme.discret
                                    font.family: Theme.police
                                    font.pixelSize: 12
                                }
                            }
                        }
                        MouseArea {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 54
                            cursorShape: Qt.PointingHandCursor
                            onClicked: agenda.ouvert = carte.deplie ? "" : carte.cle
                        }
                    }
                }

                // Champ d'ajout
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1.5
                    border.color: agenda.apercu ? Theme.accent : Theme.trait
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 6
                        spacing: 8
                        Text {
                            text: agenda.edition ? "✎" : "+"
                            color: Theme.accent
                            font.family: Theme.police
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        TextField {
                            id: champ
                            Layout.fillWidth: true
                            background: null
                            color: Theme.texte
                            font.family: Theme.police
                            font.pixelSize: 14
                            placeholderText: "Réunion parents de 14h à 15h // salle B12"
                            placeholderTextColor: Theme.discret
                            Keys.onEscapePressed: agenda.edition ? agenda.annulerEdition() : agenda.fermer()
                            Keys.onReturnPressed: agenda.ajouter()
                            Keys.onEnterPressed: agenda.ajouter()
                            // Champ vide : ← → changent de mois, comme avant.
                            Keys.onLeftPressed: event => {
                                if (text.length === 0) agenda.decaler(-1);
                                else event.accepted = false;
                            }
                            Keys.onRightPressed: event => {
                                if (text.length === 0) agenda.decaler(1);
                                else event.accepted = false;
                            }
                        }
                        Bouton {
                            visible: agenda.edition !== null
                            texte: "Annuler"
                            onClic: agenda.annulerEdition()
                        }
                        Bouton {
                            texte: agenda.edition ? "Enregistrer" : "Ajouter"
                            plein: agenda.apercu !== null && agenda.apercu.titre.length > 0
                            onClic: agenda.ajouter()
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: {
                            const p = agenda.apercu;
                            if (!p)
                                return [];
                            const l = [["Quand", agenda.nomsJours[p.date.getDay()] + " " + p.date.getDate() + " " + agenda.nomsMois[p.date.getMonth()]], ["Heure", p.debut ? agenda.hh(p.debut) + " – " + agenda.hh(p.fin) : "toute la journée"], ["Quoi", p.titre || "…"]];
                            if (p.lien) l.push(["Lien", p.lien.replace(/^https?:\/\//, "")]);
                            if (p.note) l.push(["Note", p.note]);
                            return l;
                        }
                        delegate: Rectangle {
                            required property var modelData
                            implicitWidth: Math.min(220, etiquette.implicitWidth + 20)
                            implicitHeight: 24
                            radius: 12
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                            Text {
                                id: etiquette
                                anchors.centerIn: parent
                                width: Math.min(implicitWidth, 200)
                                elide: Text.ElideRight
                                textFormat: Text.StyledText
                                text: "<font color='" + Theme.discret + "'>" + parent.modelData[0] + "</font>  " + parent.modelData[1].replace(/&/g, "&amp;").replace(/</g, "&lt;")
                                color: Theme.accentClair
                                font.family: Theme.police
                                font.pixelSize: 12
                            }
                        }
                    }
                    Text {
                        visible: agenda.apercu === null
                        width: parent.width
                        text: agenda.message || "Exemples : « demain 17h30 conseil de classe », « lundi 9h-10h visio https://… », « le 20 de 14h à 16h formation // apporter le PC »"
                        color: Theme.discret
                        font.family: Theme.police
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
