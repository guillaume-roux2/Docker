#!/bin/bash
# =============================================================================
# Job 10b - Installation automatique de Docker sur Debian
#   Dépôt officiel Docker, Engine + CLI + Buildx + Compose, service activé,
#   utilisateur ajouté au groupe docker, test avec hello-world.
#
# Usage : sudo bash install_docker.sh [utilisateur]
#         (sans argument : l'utilisateur qui a lancé sudo)
# =============================================================================
set -euo pipefail

UTIL="${1:-${SUDO_USER:-}}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Lance ce script avec sudo ou en root." >&2
    exit 1
fi

if [ ! -f /etc/debian_version ]; then
    echo "Ce script est prévu pour Debian." >&2
    exit 1
fi

. /etc/os-release
if [ "${ID:-}" != "debian" ]; then
    echo "Ce script est prévu pour Debian (détecté : ${PRETTY_NAME:-inconnu})." >&2
    exit 1
fi
CODENAME="$VERSION_CODENAME"
ARCH=$(dpkg --print-architecture)
echo "==> Système détecté : $PRETTY_NAME ($ARCH)"

if command -v docker &>/dev/null; then
    echo "Docker est déjà installé : $(docker --version)"
    echo "Pour réinstaller proprement : sudo bash desinstall_docker.sh"
    exit 0
fi

echo "==> Vérification de la connexion Internet"
curl -fsS --max-time 5 https://download.docker.com >/dev/null 2>&1 || \
  ping -c1 -W3 deb.debian.org >/dev/null || { echo "Pas d'accès Internet." >&2; exit 1; }

# Une source cdrom bloque apt update (cas d'une install sans réseau)
if grep -qs '^deb cdrom' /etc/apt/sources.list; then
    echo "==> Désactivation de la source APT cdrom"
    sed -i 's/^deb cdrom/# deb cdrom/' /etc/apt/sources.list
    grep -q '^deb http' /etc/apt/sources.list || cat >> /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian $CODENAME main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $CODENAME-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $CODENAME-security main contrib non-free non-free-firmware
EOF
fi

echo "==> Suppression des paquets en conflit (versions Debian non officielles)"
for p in docker.io docker-doc docker-compose podman-docker containerd runc; do
    dpkg -s "$p" &>/dev/null && apt-get remove -y "$p"
done

echo "==> Installation des prérequis"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg

echo "==> Ajout de la clé GPG et du dépôt Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian $CODENAME stable" > /etc/apt/sources.list.d/docker.list

echo "==> Installation de Docker"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> Activation du service au démarrage"
systemctl enable --now docker containerd

if [ -n "$UTIL" ] && [ "$UTIL" != "root" ] && id "$UTIL" &>/dev/null; then
    echo "==> Ajout de $UTIL au groupe docker"
    usermod -aG docker "$UTIL"
fi

echo "==> Test avec hello-world"
docker run --rm hello-world | grep "Hello from Docker"
docker rmi hello-world >/dev/null

echo
echo "==================== Installation terminée ===================="
docker --version
docker compose version
systemctl is-active docker
if [ -n "$UTIL" ] && [ "$UTIL" != "root" ]; then
    echo "Reconnecte-toi en $UTIL (ou tape : newgrp docker) pour utiliser docker sans sudo."
fi
