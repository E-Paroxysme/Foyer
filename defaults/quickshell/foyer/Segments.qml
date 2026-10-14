// Géré par Foyer. Choix exclusif en pilules (ex. 5 min · 10 min · Jamais).
import QtQuick

Rectangle {
    id: seg
    property var choix: []          // [{ nom, valeur }]
    property var valeur
    signal choisi(var valeur)
    implicitWidth: rang.implicitWidth + 8
    implicitHeight: 36
    radius: 18
    color: Qt.rgba(0, 0, 0, 0.22)
    Row {
        id: rang
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: seg.choix
            delegate: Rectangle {
                required property var modelData
                readonly property bool pris: String(modelData.valeur) === String(seg.valeur)
                width: libelle.implicitWidth + 26
                height: 28
                radius: 14
                color: pris ? Theme.accent : (zone.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                Text {
                    id: libelle
                    anchors.centerIn: parent
                    text: parent.modelData.nom
                    color: parent.pris ? Theme.surAccent : Theme.texte
                    font.family: Theme.police
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: zone
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.choisi(parent.modelData.valeur)
                }
            }
        }
    }
}
