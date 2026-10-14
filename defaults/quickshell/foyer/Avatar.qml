// Géré par Foyer. Photo du compte (~/.face) ou rond aux couleurs du thème avec l'initiale.
import QtQuick
import QtQuick.Effects

Item {
    id: avatar
    property string nom: ""
    property string photo: ""
    property real taille: 54
    implicitWidth: taille
    implicitHeight: taille

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.accent
        visible: image.status !== Image.Ready
        Text {
            anchors.centerIn: parent
            text: (avatar.nom || "?").charAt(0).toUpperCase()
            color: Theme.surAccent
            font.family: Theme.police
            font.pixelSize: avatar.taille * 0.42
            font.weight: Font.Bold
        }
    }
    Image {
        id: image
        anchors.fill: parent
        visible: false
        // Paramètre changeant : relit la photo quand elle vient d'être remplacée.
        source: avatar.photo ? "file://" + avatar.photo + "?" + Date.now() : ""
        cache: false
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: avatar.taille * 2
    }
    Rectangle {
        id: masque
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        visible: image.status === Image.Ready
        source: image
        maskEnabled: true
        maskSource: masque
    }
}
