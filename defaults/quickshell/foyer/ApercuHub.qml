// Géré par Foyer. Miniature du hub (planche P) : montre la disposition choisie
// dans les Réglages sans quitter la page.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: apercu
    property string entete: "compacte"
    property string bureaux: "titres"
    property bool egaliseur: true
    property bool musique: true
    property bool fenetres: true

    implicitWidth: 220
    implicitHeight: colonne.implicitHeight + 20
    radius: 16
    color: Theme.panneau
    border.width: 1
    border.color: Theme.trait
    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.duree * 0.6; easing.type: Easing.OutCubic }
    }

    readonly property color trait: Qt.rgba(Theme.texte.r, Theme.texte.g, Theme.texte.b, 0.45)

    ColumnLayout {
        id: colonne
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 6

        // En-tête
        Item {
            Layout.fillWidth: true
            implicitHeight: apercu.entete === "compacte" ? 20 : 28
            Row {
                visible: apercu.entete === "compacte"
                anchors.bottom: parent.bottom
                spacing: 5
                Text { text: "09:41"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 16; font.weight: Font.Bold }
                Text { anchors.bottom: parent.bottom; anchors.bottomMargin: 2; text: "mercredi 14 octobre"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 7 }
            }
            // « Ligne » : date à gauche, heure au centre, batterie à droite (comme le vrai hub)
            Text {
                visible: apercu.entete === "ligne"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                text: "mercredi 14 oct."
                color: Theme.discret; font.family: Theme.police; font.pixelSize: 7
            }
            Text {
                visible: apercu.entete === "ligne"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                text: "09:41"
                color: Theme.texte; font.family: Theme.police; font.pixelSize: 18; font.weight: Font.Bold
            }
            Column {
                visible: apercu.entete === "centree"
                anchors.horizontalCenter: parent.horizontalCenter
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "09:41"; color: Theme.texte; font.family: Theme.police; font.pixelSize: 20; font.weight: Font.Bold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "MERCREDI 14 OCTOBRE · 82 %"; color: Theme.discret; font.family: Theme.police; font.pixelSize: 6 }
            }
            Rectangle {
                visible: apercu.entete !== "centree"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 22; height: 9; radius: 5
                color: Qt.rgba(1, 1, 1, 0.12)
            }
        }

        // Recherche et tuiles
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 14
            radius: 6
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Theme.accent
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 3
            Repeater {
                model: 7
                delegate: Rectangle { Layout.fillWidth: true; implicitHeight: 18; radius: 5; color: Qt.rgba(1, 1, 1, 0.07) }
            }
        }

        // Lecteur de musique
        Rectangle {
            visible: apercu.musique
            Layout.fillWidth: true
            implicitHeight: apercu.egaliseur ? 38 : 24
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.06)
            Row {
                x: 6
                y: 5
                spacing: 5
                Rectangle { width: 14; height: 14; radius: 4; color: Qt.rgba(1, 1, 1, 0.12) }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 60; height: 4; radius: 2; color: apercu.trait }
            }
            Rectangle { x: parent.width - 18; y: 6; width: 12; height: 12; radius: 6; color: Theme.accent }
            Row {
                visible: apercu.egaliseur
                x: 6
                y: parent.height - 15
                width: parent.width - 12
                height: 11
                spacing: 2
                Repeater {
                    model: [5, 9, 7, 11, 6, 10, 4, 8, 11, 6, 9, 5, 7, 10, 4, 8, 6, 9]
                    delegate: Rectangle {
                        required property var modelData
                        y: 11 - height
                        width: (parent.width - 17 * 2) / 18
                        height: modelData
                        radius: 1
                        color: Theme.accent
                    }
                }
            }
        }

        // Fenêtres ouvertes
        ColumnLayout {
            visible: apercu.fenetres
            Layout.fillWidth: true
            spacing: 4
            Text {
                visible: apercu.bureaux === "titres"
                text: "Bureau 1 · actuel"
                color: Theme.discret
                font.family: Theme.police
                font.pixelSize: 7
                font.weight: Font.DemiBold
            }
            Row {
                visible: apercu.bureaux === "segments"
                spacing: 3
                Repeater {
                    model: ["Tous", "1", "2"]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: etiquette.implicitWidth + 12
                        height: 11
                        radius: 6
                        color: index === 0 ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
                        Text {
                            id: etiquette
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: parent.index === 0 ? Theme.surAccent : Theme.texte
                            font.family: Theme.police
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
            Repeater {
                model: [{ b: "1", l: 70 }, { b: "2", l: 46 }]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 14
                    radius: 5
                    color: Qt.rgba(1, 1, 1, 0.04)
                    Row {
                        x: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Rectangle {
                            visible: apercu.bureaux === "badges"
                            width: 10; height: 10; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.14)
                            Text { anchors.centerIn: parent; text: parent.parent.parent.modelData.b; color: Theme.texte; font.pixelSize: 6 }
                        }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 2; color: Qt.rgba(1, 1, 1, 0.2) }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.parent.modelData.l; height: 3; radius: 2; color: apercu.trait }
                    }
                }
            }
        }
    }
}
