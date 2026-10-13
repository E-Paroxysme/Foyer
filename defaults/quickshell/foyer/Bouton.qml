// Géré par Foyer. Petit bouton aux couleurs du thème.
// rond : entièrement arrondi ; plein : fond accent (bouton principal).
import QtQuick

Rectangle {
    id: bouton
    property string glyphe
    property bool actif: true
    property bool rond: false
    property bool plein: false
    property color survol: Theme.carteChoisie
    signal clic

    implicitWidth: plein ? 44 : 36
    implicitHeight: plein ? 44 : 36
    radius: rond || plein ? height / 2 : 10
    opacity: actif ? 1 : 0.35
    color: plein ? Theme.accent : (zone.containsMouse && actif ? survol : "transparent")
    scale: zone.pressed ? 0.94 : 1
    Behavior on scale {
        NumberAnimation { duration: 90 }
    }

    Text {
        anchors.centerIn: parent
        text: bouton.glyphe
        color: bouton.plein ? Theme.surAccent : (zone.containsMouse && bouton.actif ? Theme.accentClair : Theme.texte)
        font.pixelSize: 16
    }
    MouseArea {
        id: zone
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (bouton.actif) bouton.clic()
    }
}
