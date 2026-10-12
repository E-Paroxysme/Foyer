# Foyer

Un bureau Arch Linux + Hyprland installé en une commande, pensé autour d'un point
d'entrée unique (la touche Super) et du respect de la vie privée.

**Version 0.1** : système de base, pilotes, logiciels, réglages de vie privée,
Hyprland configuré, instantanés Btrfs. Le hub et la pastille arriveront ensuite ;
en attendant, fuzzel (lanceur) et mako (notifications) tiennent leur place.

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

Compte 20 à 60 minutes selon la connexion. Redémarre à la fin : Hyprland se
lance tout seul après la connexion.

## Utilisation

| Raccourci | Action |
| --- | --- |
| Super (seul) | Lanceur |
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
```

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
