// Géré par Foyer. Petit bouton (lecteur de musique, fermeture de fenêtre).
import QtQuick

Rectangle {
    id: bouton
    property string glyphe
    property bool actif: true
    property color survol: "#2a2a34"
    property color couleurTexte: "#f0ece6"
    property color couleurAccent: "#e8875a"
    signal clic

    implicitWidth: 32
    implicitHeight: 32
    radius: 8
    opacity: actif ? 1 : 0.35
    color: zone.containsMouse && actif ? survol : "transparent"

    Text {
        anchors.centerIn: parent
        text: bouton.glyphe
        color: zone.containsMouse && bouton.actif ? bouton.couleurAccent : bouton.couleurTexte
        font.pixelSize: 16
    }
    MouseArea {
        id: zone
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (bouton.actif) bouton.clic()
    }
}
