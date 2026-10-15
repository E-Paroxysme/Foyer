// Géré par Foyer. Toutes les applications installées, en grille, avec un filtre.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: applis
    property bool actif: false
    signal lancer(var entree)
    signal fermer

    readonly property var liste: DesktopEntries.applications.values
        .filter(e => !e.noDisplay && e.name)
        .filter(e => filtre.text.trim() === "" || normaliser(e.name + " " + (e.genericName || "") + " " + (e.keywords || []).join(" ")).includes(normaliser(filtre.text)))
        .sort((a, b) => a.name.localeCompare(b.name, "fr"))

    function normaliser(t) {
        return String(t || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }
    function ouvrir() {
        filtre.text = "";
        grille.positionViewAtBeginning();
        filtre.forceActiveFocus();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Bouton {
                glyphe: "‹"
                rond: true
                onClic: applis.fermer()
            }
            Text {
                text: "Applications"
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
            Text {
                text: applis.liste.length + (applis.liste.length > 1 ? " applications" : " application")
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 13
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.preferredWidth: 220
                implicitHeight: 36
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.2)
                border.width: 1
                border.color: filtre.activeFocus ? Theme.accent : Theme.trait
                TextField {
                    id: filtre
                    anchors.fill: parent
                    background: null
                    placeholderText: "Filtrer…"
                    placeholderTextColor: Theme.discret
                    color: Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 14
                    Keys.onEscapePressed: applis.fermer()
                    Keys.onReturnPressed: if (applis.liste.length > 0) applis.lancer(applis.liste[0])
                    Keys.onEnterPressed: if (applis.liste.length > 0) applis.lancer(applis.liste[0])
                }
            }
        }

        GridView {
            id: grille
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Math.floor(width / 6)
            cellHeight: 104
            boundsBehavior: Flickable.StopAtBounds
            model: applis.actif ? applis.liste : []
            ScrollBar.vertical: ScrollBar { policy: grille.contentHeight > grille.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
            delegate: Item {
                id: case_
                required property var modelData
                width: grille.cellWidth
                height: grille.cellHeight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.arrondiCarte
                    color: zone.containsMouse ? Theme.carteChoisie : "transparent"
                    border.width: zone.containsMouse ? 1 : 0
                    border.color: Theme.trait
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Item {
                        width: 44
                        height: 44
                        anchors.horizontalCenter: parent.horizontalCenter
                        Image {
                            id: image
                            anchors.fill: parent
                            source: Quickshell.iconPath(case_.modelData.icon || "", true)
                            sourceSize.width: 44
                            sourceSize.height: 44
                            asynchronous: true
                        }
                        // Pas d'icône trouvée : initiale dans un rond aux couleurs du thème
                        Rectangle {
                            anchors.fill: parent
                            visible: image.status !== Image.Ready
                            radius: 12
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                            Text {
                                anchors.centerIn: parent
                                text: (case_.modelData.name || "?").charAt(0).toUpperCase()
                                color: Theme.accentClair
                                font.family: Theme.police
                                font.pixelSize: 20
                                font.weight: Font.Bold
                            }
                        }
                    }
                    Text {
                        width: grille.cellWidth - 14
                        horizontalAlignment: Text.AlignHCenter
                        text: case_.modelData.name
                        color: Theme.texte
                        font.family: Theme.police
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: zone
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: applis.lancer(case_.modelData)
                }
            }
        }
    }
}
