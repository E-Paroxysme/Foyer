// Géré par Foyer. Point d'entrée de l'interface Foyer (Quickshell).
// Lancement : qs -c foyer        Ouvrir/fermer le hub : qs -c foyer ipc call hub basculer
//
// Chaque élément est chargé séparément : si l'un contient une erreur, les autres
// fonctionnent quand même. Le hub retombe alors sur sa version de secours, et
// les notifications sur mako.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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
                if (racine.pastille)
                    objet.pastille = racine.pastille;
            } else {
                creer("HubSecours.qml", secours => racine.hub = secours);
                Quickshell.execDetached(["notify-send", "Foyer", "Le hub principal n'a pas pu démarrer : version de secours. Détails : qs -c foyer"]);
            }
        });
        creer("Pastille.qml", objet => {
            if (objet) {
                racine.pastille = objet;
                if (racine.hub && "pastille" in racine.hub)
                    racine.hub.pastille = objet;
            }
            else
                Quickshell.execDetached(["uwsm", "app", "-s", "b", "--", "mako"]);
        });
    }

    // Bouton « réduire » dessiné par l'application elle-même (LibreWolf, GTK…) :
    // Hyprland ne réduit pas, il signale seulement la demande. On envoie alors la
    // fenêtre sur le bureau caché des fenêtres réduites, comme le bouton des barres.
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name !== "minimized")
                return;
            const morceaux = String(ev.data).split(",");
            if (morceaux.length < 2 || morceaux[1] !== "1")
                return;
            const adresse = morceaux[0].startsWith("0x") ? morceaux[0] : "0x" + morceaux[0];
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = \"special:reduites\", follow = false, window = \"address:" + adresse + "\" })"]);
        }
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
        // qs -c foyer ipc call hub reglages wifi
        function reglages(rubrique: string): void {
            if (racine.hub && racine.hub.ouvrirReglages) {
                racine.hub.ouvert = true;
                racine.hub.ouvrirReglages(rubrique);
            }
        }
        // Super+. : emojis et caractères spéciaux
        function caracteres(): void {
            if (racine.hub && racine.hub.ouvrirCaracteres) {
                racine.hub.ouvert = true;
                racine.hub.ouvrirCaracteres();
            }
        }
        // qs -c foyer ipc call hub personnaliser
        function personnaliser(): void {
            if (racine.hub && racine.hub.ouvrirPersonnaliser) {
                racine.hub.ouvert = true;
                racine.hub.ouvrirPersonnaliser();
            }
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
        // Super+P : écran du PC, dupliquer, étendre, projecteur seul
        function projection(): void {
            if (racine.pastille)
                racine.pastille.projection();
        }
        // Super+Alt+R (écran entier) ou Super+Alt+Maj+R (zone) ; rappuyer arrête.
        function enregistrer(): void {
            if (racine.pastille)
                racine.pastille.enregistrer(false);
        }
        function enregistrerZone(): void {
            if (racine.pastille)
                racine.pastille.enregistrer(true);
        }
        function eveille(): void {
            if (racine.pastille)
                racine.pastille.eveille = !racine.pastille.eveille;
        }
    }
}
