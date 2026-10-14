// Géré par Foyer. Une ligne d'appareil Bluetooth dans les Réglages.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: appareil
    property var modele: ({})
    signal action(string act)
    Layout.fillWidth: true
    implicitHeight: 52
    radius: 16
    color: Qt.rgba(1, 1, 1, 0.045)
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: appareil.modele.nom || ""
                color: Theme.texte
                font.family: Theme.police
                font.pixelSize: 14
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                text: appareil.modele.connecte ? "Connecté" + (appareil.modele.batterie >= 0 ? " · batterie " + appareil.modele.batterie + " %" : "") : (appareil.modele.appaire ? "Appairé" : "Disponible")
                color: appareil.modele.connecte ? Theme.accentClair : Theme.discret
                font.family: Theme.police
                font.pixelSize: 12
            }
        }
        Bouton {
            visible: !!appareil.modele.appaire
            texte: "Oublier"
            onClic: appareil.action("oublier")
        }
        Bouton {
            texte: !appareil.modele.appaire ? "Appairer" : (appareil.modele.connecte ? "Déconnecter" : "Connecter")
            plein: !appareil.modele.appaire
            onClic: appareil.action(!appareil.modele.appaire ? "appairer" : (appareil.modele.connecte ? "deconnecter" : "connecter"))
        }
    }
}
