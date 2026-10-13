// Géré par Foyer. La date de l'en-tête du hub : un clic ouvre le calendrier.
import QtQuick

Text {
    id: racine
    property date date: new Date()
    property bool majuscules: false
    signal clic

    readonly property string libelle: date.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
    text: majuscules ? libelle.toUpperCase() : libelle
    color: zone.containsMouse ? Theme.accentClair : Theme.discret
    font.family: Theme.police
    font.pixelSize: majuscules ? 12 : 14
    font.weight: Font.Medium
    font.letterSpacing: majuscules ? 2 : 0

    MouseArea {
        id: zone
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: racine.clic()
    }
}
