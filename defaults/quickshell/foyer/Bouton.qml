// Géré par Foyer. Petit bouton aux couleurs du thème.
// rond : entièrement arrondi ; plein : fond accent (bouton principal).
import QtQuick

Rectangle {
    id: bouton
    property string glyphe
    property string texte                 // bouton avec un mot (« Ajouter ») plutôt qu'un symbole
    property bool actif: true
    property bool rond: false
    property bool plein: false
    property color survol: Theme.carteChoisie
    signal clic

    implicitWidth: texte ? libelle.implicitWidth + 28 : (plein ? 44 : 36)
    implicitHeight: texte ? 32 : (plein ? 44 : 36)
    border.width: texte && !plein ? 1 : 0
    border.color: Theme.trait
    radius: rond || plein ? height / 2 : 10
    opacity: actif ? 1 : 0.35
    color: plein ? Theme.accent : (zone.containsMouse && actif ? survol : "transparent")
    scale: zone.pressed ? 0.94 : 1
    Behavior on scale {
        NumberAnimation { duration: 90 }
    }

    Text {
        id: libelle
        anchors.centerIn: parent
        text: bouton.texte || bouton.glyphe
        font.family: Theme.police
        font.weight: bouton.texte ? Font.DemiBold : Font.Normal
        color: bouton.plein ? Theme.surAccent : (zone.containsMouse && bouton.actif ? Theme.accentClair : Theme.texte)
        font.pixelSize: bouton.texte ? 13 : 16
    }
    MouseArea {
        id: zone
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (bouton.actif) bouton.clic()
    }
}
