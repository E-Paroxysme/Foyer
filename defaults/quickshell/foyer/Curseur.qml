// Géré par Foyer. Curseur (slider) fin aux couleurs du thème.
import QtQuick

Item {
    id: curseur
    property real de: 0
    property real a: 100
    property real valeur: 50
    property real pas: 1
    signal deplace(real valeur)      // pendant le glissement
    signal lache(real valeur)        // au relâchement
    implicitWidth: 200
    implicitHeight: 22
    readonly property real ratio: Math.max(0, Math.min(1, (valeur - de) / (a - de)))
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Qt.rgba(Theme.texte.r, Theme.texte.g, Theme.texte.b, 0.16)
        Rectangle {
            width: parent.width * curseur.ratio
            height: parent.height
            radius: 2
            color: Theme.accent
        }
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: (parent.width - width) * curseur.ratio
        width: 18
        height: 18
        radius: 9
        color: Theme.texte
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function calcul(mx) {
            const r = Math.max(0, Math.min(1, mx / width));
            return Math.round((curseur.de + r * (curseur.a - curseur.de)) / curseur.pas) * curseur.pas;
        }
        onPressed: m => curseur.deplace(calcul(m.x))
        onPositionChanged: m => { if (pressed) curseur.deplace(calcul(m.x)); }
        onReleased: m => curseur.lache(calcul(m.x))
    }
}
