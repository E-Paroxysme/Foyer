// Géré par Foyer. Niveau de batterie (visible seulement sur un portable).
import QtQuick
import Quickshell.Services.UPower

Rectangle {
    id: racine
    readonly property var batt: UPower.displayDevice
    visible: !!(batt && batt.isLaptopBattery)
    implicitWidth: texte.implicitWidth + 20
    implicitHeight: 24
    radius: 12
    color: Theme.bouton

    Text {
        id: texte
        anchors.centerIn: parent
        text: racine.visible ? (UPower.onBattery ? "" : "⚡ ") + Math.round(racine.batt.percentage * 100) + " %" : ""
        color: Theme.discret
        font.family: Theme.police
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }
}
