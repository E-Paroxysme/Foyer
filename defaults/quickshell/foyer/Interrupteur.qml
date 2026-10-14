// Géré par Foyer. Interrupteur (switch) aux couleurs du thème.
import QtQuick

Rectangle {
    id: inter
    property bool actif: false
    signal bascule(bool valeur)
    implicitWidth: 44
    implicitHeight: 24
    radius: 12
    color: actif ? Theme.accent : Qt.rgba(1, 1, 1, 0.18)
    Behavior on color {
        ColorAnimation { duration: 160 }
    }
    Rectangle {
        y: 3
        x: inter.actif ? inter.width - width - 3 : 3
        width: 18
        height: 18
        radius: 9
        color: Theme.texte
        Behavior on x {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: inter.bascule(!inter.actif)
    }
}
