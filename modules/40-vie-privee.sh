#!/usr/bin/env bash
# Réglages de vie privée appliqués par défaut.
set -euo pipefail
source "$FOYER_DIR/modules/commun.sh"

pacman_installer ufw

# --- Pare-feu : tout bloquer en entrée, tout autoriser en sortie -----------
info "Pare-feu (ufw) : entrées bloquées par défaut"
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
sudo ufw --force enable >/dev/null
activer_service ufw

# --- DNS chiffré (DNS-over-TLS vers Quad9) ----------------------------------
# Attention : certains Wi-Fi publics à page de connexion (hôtels, gares) peuvent
# ne pas s'afficher avec un DNS imposé. Désactivation : supprimer le fichier
# /etc/systemd/resolved.conf.d/foyer-dns.conf puis : sudo systemctl restart systemd-resolved
info "DNS chiffré (systemd-resolved, DNS-over-TLS, Quad9)"
ecrire_systeme /etc/systemd/resolved.conf.d/foyer-dns.conf <<'EOF' || true
# Géré par Foyer
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
FallbackDNS=
DNSOverTLS=yes
Domains=~.
EOF
activer_service systemd-resolved
sudo systemctl restart systemd-resolved || true
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# --- Adresse MAC aléatoire --------------------------------------------------
# Une adresse différente par réseau et par démarrage : les réseaux publics ne
# peuvent pas suivre la machine d'un lieu à l'autre.
info "Adresse MAC aléatoire (Wi-Fi et Ethernet)"
ecrire_systeme /etc/NetworkManager/conf.d/foyer-confidentialite.conf <<'EOF' || true
# Géré par Foyer
[main]
dns=systemd-resolved

[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
ethernet.cloned-mac-address=stable
connection.stable-id=${CONNECTION}/${BOOT}
EOF

# --- Annonce de la machine sur le réseau local ------------------------------
if systemctl list-unit-files avahi-daemon.service >/dev/null 2>&1; then
  info "Avahi désactivé (n'annonce plus la machine sur le réseau local)"
  sudo systemctl disable --now avahi-daemon.service avahi-daemon.socket >/dev/null 2>&1 || true
fi

# --- Bluetooth éteint au démarrage ------------------------------------------
if [[ -f /etc/bluetooth/main.conf ]]; then
  info "Bluetooth éteint au démarrage (allumage à la demande)"
  if grep -q '^#\?AutoEnable' /etc/bluetooth/main.conf; then
    sudo sed -i 's/^#\?AutoEnable.*/AutoEnable=false/' /etc/bluetooth/main.conf
  else
    printf '\n[Policy]\nAutoEnable=false\n' | sudo tee -a /etc/bluetooth/main.conf >/dev/null
  fi
fi

# --- Télémétrie de VS Code --------------------------------------------------
info "Télémétrie de VS Code désactivée"
vscode="$FOYER_CONFIG/Code/User/settings.json"
mkdir -p "$(dirname "$vscode")"
if [[ ! -f "$vscode" ]]; then
  cat >"$vscode" <<'EOF'
{
  "telemetry.telemetryLevel": "off",
  "workbench.enableExperiments": false,
  "update.mode": "none"
}
EOF
elif ! grep -q '"telemetry.telemetryLevel"' "$vscode"; then
  avertir "settings.json de VS Code existe déjà : ajoute toi-même \"telemetry.telemetryLevel\": \"off\""
fi

# --- Journal système limité --------------------------------------------------
info "Journal système limité à 200 Mo"
ecrire_systeme /etc/systemd/journald.conf.d/foyer.conf <<'EOF' || true
# Géré par Foyer
[Journal]
SystemMaxUse=200M
EOF
