#!/bin/bash
# =============================================================================
# Job 01 - Préparer la VM Debian (console) et installer Docker (CLI seulement)
# -----------------------------------------------------------------------------
# La VM elle-même (8 Go disque / 1 Go RAM / 1 vCPU, sans environnement
# graphique) se crée dans VMware. Ce script fait tout le reste :
#   - remplace la source APT "cdrom" par les dépôts Debian en ligne
#   - installe sudo et ajoute l'utilisateur au groupe sudo
#   - installe open-vm-tools et openssh-server
#   - installe Docker Engine + CLI depuis le dépôt officiel (pas Docker Desktop)
#
# Usage (en root) : bash preparation_vm.sh [utilisateur]
# Exemple         : bash preparation_vm.sh guidoc
# =============================================================================
set -euo pipefail

UTILISATEUR="${1:-guidoc}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être lancé en root (utilise : su -)" >&2
    exit 1
fi

if ! id "$UTILISATEUR" &>/dev/null; then
    echo "L'utilisateur '$UTILISATEUR' n'existe pas." >&2
    exit 1
fi

echo "==> Vérification du réseau"
if ! ping -c 1 -W 3 deb.debian.org &>/dev/null; then
    echo "Pas d'accès à Internet. Configure le réseau (/etc/network/interfaces) puis relance." >&2
    exit 1
fi

# --- Sources APT : on retire le cdrom et on met les dépôts en ligne ----------
. /etc/os-release
CODENAME="${VERSION_CODENAME:-trixie}"
echo "==> Configuration des dépôts Debian ($CODENAME)"
cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian $CODENAME main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $CODENAME-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
EOF
# Commenter d'éventuelles lignes cdrom dans sources.list.d
grep -rl '^deb cdrom' /etc/apt/sources.list.d/ 2>/dev/null | xargs -r sed -i 's/^deb cdrom/# deb cdrom/' || true

echo "==> Mise à jour du système"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y

echo "==> Installation des outils de base"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo open-vm-tools openssh-server curl ca-certificates gnupg

echo "==> Ajout de $UTILISATEUR au groupe sudo"
usermod -aG sudo "$UTILISATEUR"

# --- Installation de Docker (dépôt officiel) ---------------------------------
echo "==> Ajout du dépôt officiel Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian $CODENAME stable" > /etc/apt/sources.list.d/docker.list

apt-get update
echo "==> Installation de Docker Engine et du client en ligne de commande"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

echo "==> Ajout de $UTILISATEUR au groupe docker"
usermod -aG docker "$UTILISATEUR"

echo
echo "==================== Terminé ===================="
docker --version
docker compose version
echo "IP de la VM : $(hostname -I | awk '{print $1}')"
echo "Déconnecte-toi puis reconnecte-toi en $UTILISATEUR pour utiliser sudo et docker."
