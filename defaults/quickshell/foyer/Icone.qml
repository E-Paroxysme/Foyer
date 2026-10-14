// Géré par Foyer. Petites icônes au trait, aux couleurs du thème (24×24).
import QtQuick
import QtQuick.Shapes

Item {
    id: icone
    property string nom: "volume"
    property string trace: ""           // tracé SVG libre (prioritaire sur nom)
    property color couleur: Theme.texte
    property real taille: 20
    implicitWidth: taille
    implicitHeight: taille

    readonly property var traces: ({
        "volume": "M4 9h4l5-4v14l-5-4H4z M16.5 8.5a5 5 0 0 1 0 7 M19 6a8.5 8.5 0 0 1 0 12",
        "muet": "M4 9h4l5-4v14l-5-4H4z M17 9l5 6 M22 9l-5 6",
        "luminosite": "M12 8a4 4 0 1 1 0 8a4 4 0 1 1 0-8z M12 2v2 M12 20v2 M2 12h2 M20 12h2 M4.9 4.9l1.4 1.4 M17.7 17.7l1.4 1.4 M4.9 19.1l1.4-1.4 M17.7 6.3l1.4-1.4",
        "batterie": "M3 8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M22 10.5v3 M6 9.5v5",
        "visio": "M6 6h7a3 3 0 0 1 3 3v6a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V9a3 3 0 0 1 3-3z M16 10l5-3v10l-5-3",
        "note": "M5 4h14v16H5z M9 9h6 M9 13h6 M9 17h3",
        "cadenas": "M5 11h14v10H5z M8 11V8a4 4 0 0 1 8 0v3"
    })

    Shape {
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: icone.taille / 24
        preferredRendererType: Theme.eco ? Shape.GeometryRenderer : Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: icone.couleur
            strokeWidth: 1.9
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icone.trace || icone.traces[icone.nom] || "" }
        }
    }
}
