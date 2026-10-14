# Foyer

Un bureau Arch Linux + Hyprland installé en une commande, pensé autour d'un point
d'entrée unique (la touche Super) et du respect de la vie privée.

**Version 0.5** : système de base, pilotes, logiciels, réglages de vie privée,
instantanés Btrfs, et la nouvelle identité visuelle « braise » :

- **hub v3** (touche Super) : panneau flottant, recherche qui ouvre ses résultats
  (calcul, applications, tuiles, fenêtres, fichiers, web), tuiles, lecteur de
  musique avec égaliseur, fenêtres par bureau, calendrier (clic sur la date) ;
- **pastille** en bas au centre : notifications et historique, témoins micro /
  caméra / partage d'écran, volume, luminosité, batterie faible ;
- **thème unique** pour tout le bureau (fenêtres, terminal, lanceur, écran de
  verrouillage, applications GTK) ;
- écran de verrouillage avec ton fond d'écran et l'icône du compte.

Si le hub ou la pastille rencontrent une erreur, une version de secours prend
le relais (hub simple, notifications par mako).

## Installation

### 1. Préparer la clé USB

Télécharge l'ISO officielle sur <https://archlinux.org/download/> et copie-la sur
une clé USB (par exemple avec Fedora Media Writer, Ventoy, ou
`sudo dd if=archlinux.iso of=/dev/sdX bs=4M status=progress`).

### 2. Démarrer sur la clé

ThinkPad L520 : **F12** au démarrage pour choisir la clé. Dans la configuration
du BIOS (**F1**), mode de démarrage « UEFI » si l'option existe, sinon « Legacy » :
les deux fonctionnent.

### 3. Se connecter à Internet

Câble Ethernet : rien à faire, c'est le plus simple. Wi-Fi : vérifie d'abord que
l'**interrupteur sans fil** du ThinkPad (sur la tranche) est sur « marche »,
puis vérifie que la carte n'est pas bloquée avec `rfkill list` (sinon :
`rfkill unblock wifi`). Ensuite :

```
iwctl
station wlan0 connect "NomDuReseau"
exit
```

### 4. Installer Arch avec archinstall

```
archinstall
```

Choix à faire :

| Rubrique | Choix |
| --- | --- |
| Langue / clavier | `fr` |
| Disque | Effacer tout le disque, partitionnement par défaut |
| Système de fichiers | **btrfs**, avec les sous-volumes par défaut (nécessaire aux instantanés) |
| Chiffrement | **Oui** (mot de passe demandé à chaque démarrage) |
| Chargeur de démarrage | **GRUB** (fonctionne en UEFI comme en Legacy, permet de démarrer sur un instantané) |
| Nom de machine | neutre, par exemple `foyer` |
| Utilisateur | ton utilisateur, avec les droits sudo |
| Profil | **Minimal** (pas de bureau : Foyer s'en charge) |
| Audio | PipeWire |
| Réseau | **NetworkManager** (« Use NetworkManager ») : sans ça, pas de réseau après le redémarrage |
| Fuseau horaire | Europe/Paris |

Lance l'installation, puis redémarre et retire la clé.

### 5. Installer Foyer

Connecte-toi avec ton utilisateur. Si tu es en Wi-Fi : `nmtui`. Puis :

```
curl -fsSL https://raw.githubusercontent.com/E-Paroxysme/Foyer/main/install.sh | bash
```

Le script te demande d'abord quels **groupes de logiciels optionnels** installer
(bureautique, création, SI, SNT, développement). Une barre de progression
globale indique ensuite l'avancement. Compte 15 à 60 minutes selon la connexion
et les groupes choisis. Redémarre à la fin : Hyprland se
lance tout seul après la connexion.

## Utilisation

| Raccourci | Action |
| --- | --- |
| Super (seul) | Hub : recherche, tuiles, musique, fenêtres ouvertes par bureau (✕ pour fermer d'un clic) |
| Dans le hub | Flèches pour naviguer, Entrée pour ouvrir, Suppr pour fermer la fenêtre choisie, Échap |
| Clic sur la date du hub | Calendrier (← → pour changer de mois, Échap pour revenir) |
| Clic sur la pastille | Historique des notifications |
| Super + Espace | Lanceur de secours (fuzzel) |
| Super + Entrée | Terminal |
| Super + B | Navigateur (LibreWolf) |
| Super + E | Fichiers |
| Super + Q | Fermer la fenêtre |
| Super + F | Fenêtre flottante |
| Super + L | Verrouiller |
| Super + V | Historique du presse-papier |
| Super + & é " ' … | Aller au bureau 1, 2, 3… |
| Super + Maj + & é " ' … | Envoyer la fenêtre au bureau 1, 2, 3… |
| Impr. écran / Super + Maj + S | Capture plein écran / d'une zone |

## Mettre à jour

```
foyer update             # tout
foyer update vie-privee  # un seul module
foyer modules            # liste des modules
foyer groupes            # groupes de logiciels optionnels (✔ = installé)
foyer installer si       # ajoute un groupe plus tard
foyer theme liste        # thèmes disponibles (braise, ocean, foret, aube, ardoise)
foyer theme ocean        # choisit un thème
foyer theme              # réapplique après avoir modifié ~/.config/foyer/theme.json
foyer version            # version installée
foyer history            # versions installées sur cet ordinateur
foyer rollback           # revient à la version précédente de Foyer
foyer rollback 2d72f49   # revient à une version précise
```

`foyer rollback` (ou la tuile « Version précédente ») remet Foyer et ses fichiers
de config sur la version d'avant ; tes fichiers de `~/.config/foyer` ne sont pas
touchés. Plusieurs `rollback` d'affilée remontent pas à pas ; `foyer update`
revient à la dernière version. Les logiciels d'Arch, eux, se restaurent avec les
instantanés Btrfs (voir plus bas).

La mise à jour se répare seule : le dossier `~/.local/share/foyer` est toujours
réaligné sur la version publiée (une modification faite à la main dedans est
sauvegardée dans `~/.local/state/foyer/` puis remplacée), et la commande
`foyer` restaure son propre programme s'il a été abîmé. En dernier recours :
`bash ~/.local/share/foyer/bin/foyer update`.

Tuiles du hub : modifie `~/.config/foyer/tuiles.json` (jamais écrasé) ; le hub
relit le fichier tout seul.

Disposition du hub : `~/.config/foyer/disposition.json` (jamais écrasé, relu tout
seul) : en-tête `compacte`, `ligne` ou `centree` ; bureaux `titres`, `segments`
ou `badges` ; égaliseur `colonnes` ou `aucun` ; widgets à afficher.

Thème : `foyer theme <nom>` choisit un thème tout prêt. Pour l'ajuster,
`~/.config/foyer/theme.json` (jamais écrasé, il retient le thème choisi dans
`base`) : mets-y seulement ce que tu veux changer, avec les noms du thème par défaut
(`~/.local/share/foyer/defaults/foyer/theme.json`), puis `foyer theme`. Exemple :

```json
{ "couleurs": { "accent": "#5aa0e8" } }
```

Le thème colore aussi les dossiers de l'explorateur de fichiers (icônes Papirus,
clé `icones.dossiers` : orange, blue, green, pink, bluegrey…) ; les icônes des
applications restent les officielles.

Icône du compte (écran de verrouillage) : une image carrée dans `~/.face`, puis
`foyer theme`. Sans elle, un rond aux couleurs du thème.

Réglages : tape « réglages » (ou « wifi », « son », « thème », « batterie »…) dans
la recherche du hub, ou `qs -c foyer ipc call hub reglages wifi`. Rubriques : compte
(photo, nom, mot de passe, fond d'écran), Wi-Fi, Bluetooth, son, écran et énergie,
souris et clavier, notifications, thème, accessibilité, confidentialité,
applications par défaut, agendas, système. Ce qui est réglé ici est rangé dans
`~/.config/foyer/reglages.json` et survit aux mises à jour.

Agenda : clic sur la date du hub. Ajoute un événement en une phrase
(« lundi de 14h à 15h réunion https://… // salle B12 » : la date, les heures, le
lien de visio et la note après `//` sont reconnus). Les événements sont des
fichiers `.ics` dans `~/.local/share/foyer/agenda/personnel`. Pour brancher un
agenda extérieur : `foyer agenda brancher` (ou le lien en bas du calendrier).
Lien iCal (Pronote, ENT, agenda Proton partagé) = lecture seule ; compte CalDAV
(Nextcloud, Google, iCloud, Infomaniak…) = lecture et écriture. Synchronisation
toutes les 15 minutes, rappel dans la pastille 15 minutes avant chaque événement.
Autres commandes : `foyer agenda liste`, `foyer agenda retirer <nom>`,
`foyer agenda synchroniser`. Le mot de passe CalDAV est rangé dans
`~/.config/foyer/agendas/` (lisible par toi seul).

Barres de titre : toutes les fenêtres reçoivent réduire / agrandir / fermer grâce à
l'extension officielle hyprbars, compilée par `hyprpm` (module `barres`, à lancer
depuis la session : `foyer update barres`). Une fenêtre réduite se retrouve dans
le hub (« Fenêtres réduites ») ; un clic la ramène. Après une mise à jour
d'Hyprland, `foyer update` recompile l'extension ; tant que ce n'est pas fait,
Hyprland démarre normalement, sans barres. Journal : `~/.local/state/foyer/hyprpm.log`.

Fond d'écran : remplace `~/.config/foyer/fond.jpg` par l'image de ton choix.

Tes réglages personnels vont dans `~/.config/foyer/perso.lua` : ce fichier n'est
jamais écrasé. Les autres fichiers de config marqués « Géré par Foyer » sont
remplacés à chaque mise à jour.

## Vie privée, réglages par défaut

- Disque chiffré (choisi dans archinstall).
- Pare-feu : toutes les connexions entrantes bloquées.
- DNS chiffré (DNS-over-TLS vers Quad9). Si un Wi-Fi public n'affiche pas sa page
  de connexion : `sudo rm /etc/systemd/resolved.conf.d/foyer-dns.conf && sudo systemctl restart systemd-resolved`.
- Adresse MAC différente par réseau et par démarrage.
- Avahi désactivé, Bluetooth éteint au démarrage.
- Télémétrie de VS Code désactivée.
- Historique du presse-papier vidé à chaque session.
- LibreWolf, suite Proton, Flatseal, Metadata Cleaner installés.

## Revenir en arrière

Un instantané du système est pris avant et après chaque installation de paquets.
Si une mise à jour casse le démarrage : au menu GRUB, choisis « Arch Linux
snapshots » et démarre sur l'instantané précédent. La restauration définitive
depuis cet instantané reste à valider sur la machine (la procédure dépend de
la disposition des sous-volumes créée par archinstall).

## Journal

En cas de problème : `~/.local/state/foyer/journal.log`.
