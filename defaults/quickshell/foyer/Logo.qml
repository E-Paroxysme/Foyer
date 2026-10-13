// Géré par Foyer. Le logo, dessiné aux couleurs du thème.
// allume : flamme pleine (accent) ; sinon simple contour discret.
import QtQuick
import QtQuick.Shapes

Item {
    id: logo
    property bool allume: true
    property color couleur: allume ? Theme.accent : Theme.discret
    property real taille: 18
    implicitWidth: taille
    implicitHeight: taille

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: logo.taille / 24
        preferredRendererType: Theme.eco ? Shape.GeometryRenderer : Shape.CurveRenderer
        ShapePath {
            fillColor: logo.allume ? logo.couleur : "transparent"
            strokeColor: logo.allume ? "transparent" : logo.couleur
            strokeWidth: logo.allume ? 0 : 1.8
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Theme.logoTrace }
        }
        ShapePath {
            fillColor: logo.allume && Theme.logoCoeur !== "" ? Theme.accentClair : "transparent"
            strokeColor: "transparent"
            strokeWidth: 0
            PathSvg { path: Theme.logoCoeur !== "" ? Theme.logoCoeur : "M0 0" }
        }
    }
}
