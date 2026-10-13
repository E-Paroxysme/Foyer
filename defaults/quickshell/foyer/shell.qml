// Géré par Foyer. Point d'entrée de l'interface Foyer (Quickshell).
// Lancement : qs -c foyer        Ouvrir/fermer le hub : qs -c foyer ipc call hub basculer
//
// Chaque élément est chargé séparément : si l'un contient une erreur, les autres
// fonctionnent quand même. Le hub retombe alors sur sa version de secours, et
// les notifications sur mako.
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: racine

    property var hub: null
    property var pastille: null

    function creer(fichier, siEchec) {
        const composant = Qt.createComponent(fichier);
        const fin = () => {
            if (composant.status === Component.Ready) {
                const objet = composant.createObject(racine);
                if (objet) {
                    siEchec(objet);
                    return;
                }
                console.warn("Foyer : impossible de créer " + fichier);
            } else {
                console.warn("Foyer : erreur dans " + fichier + " :\n" + composant.errorString());
            }
            siEchec(null);
        };
        if (composant.status === Component.Loading)
            composant.statusChanged.connect(() => {
                if (composant.status !== Component.Loading)
                    fin();
            });
        else
            fin();
    }

    Component.onCompleted: {
        creer("Hub.qml", objet => {
            if (objet) {
                racine.hub = objet;
            } else {
                creer("HubSecours.qml", secours => racine.hub = secours);
                Quickshell.execDetached(["notify-send", "Foyer", "Le hub principal n'a pas pu démarrer : version de secours. Détails : qs -c foyer"]);
            }
        });
        creer("Pastille.qml", objet => {
            if (objet)
                racine.pastille = objet;
            else
                Quickshell.execDetached(["uwsm", "app", "-s", "b", "--", "mako"]);
        });
    }

    IpcHandler {
        target: "hub"

        function basculer(): void {
            if (racine.hub)
                racine.hub.ouvert = !racine.hub.ouvert;
            if (racine.pastille)
                racine.pastille.historique = false;
        }
        function ouvrir(): void {
            if (racine.hub)
                racine.hub.ouvert = true;
        }
        function fermer(): void {
            if (racine.hub)
                racine.hub.ouvert = false;
        }
    }

    IpcHandler {
        target: "pastille"

        function luminosite(): void {
            if (racine.pastille)
                racine.pastille.luminosite();
        }
        function historique(): void {
            if (racine.pastille)
                racine.pastille.basculerHistorique();
        }
    }
}
