// Géré par Foyer. Point d'entrée de l'interface Foyer (Quickshell).
// Lancement : qs -c foyer        Ouvrir/fermer le hub : qs -c foyer ipc call hub basculer
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: racine

    Hub {
        id: hub
    }

    IpcHandler {
        target: "hub"

        function basculer(): void {
            hub.ouvert = !hub.ouvert;
        }
        function ouvrir(): void {
            hub.ouvert = true;
        }
        function fermer(): void {
            hub.ouvert = false;
        }
    }
}
