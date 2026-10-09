#!/bin/bash
# =============================================================================
# Job 10a - Effacer totalement Docker et rendre le système propre
#   conteneurs, images, volumes, réseaux, cache de build, paquets,
#   dépôt APT, clé GPG, fichiers de config, données et groupe docker.
#
# Usage (en root ou avec sudo) :
#   sudo bash desinstall_docker.sh            # demande confirmation
#   sudo bash desinstall_docker.sh -y         # sans confirmation
#   sudo bash desinstall_docker.sh -y --tp    # + dossiers du TP dans ~
# =============================================================================
set -uo pipefail   # pas de -e : on continue même si un élément est déjà absent

CONFIRMER=1
SUPPR_TP=0
for arg in "$@"; do
    case "$arg" in
        -y) CONFIRMER=0 ;;
        --tp) SUPPR_TP=1 ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    echo "Lance ce script avec sudo." >&2
    exit 1
fi

# Utilisateur réel (celui qui a lancé sudo)
UTIL="${SUDO_USER:-root}"
HOME_UTIL=$(getent passwd "$UTIL" | cut -d: -f6)

if [ "$CONFIRMER" -eq 1 ]; then
    echo "ATTENTION : tous les conteneurs, images et volumes Docker seront DÉFINITIVEMENT supprimés."
    read -rp "Tape 'oui' pour continuer : " rep
    [ "$rep" = "oui" ] || { echo "Annulé."; exit 0; }
fi

etape() { echo; echo "==> $1"; }

if command -v docker &>/dev/null && systemctl is-active --quiet docker; then
    etape "Arrêt et suppression des conteneurs"
    docker ps -q | xargs -r docker stop
    docker ps -aq | xargs -r docker rm -f

    etape "Suppression des images"
    docker images -aq | sort -u | xargs -r docker rmi -f

    etape "Suppression des volumes"
    docker volume ls -q | xargs -r docker volume rm -f

    etape "Suppression des réseaux personnalisés"
    docker network ls --filter type=custom -q | xargs -r docker network rm

    etape "Nettoyage du cache de build"
    docker builder prune -af &>/dev/null
    docker system prune -af --volumes &>/dev/null
else
    echo "Docker n'est pas actif : on passe directement à la suppression des fichiers."
fi

etape "Arrêt des services"
systemctl stop docker.socket docker.service containerd.service &>/dev/null
systemctl disable docker.socket docker.service containerd.service &>/dev/null

etape "Désinstallation des paquets"
PAQUETS="docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
docker-compose-plugin docker-ce-rootless-extras docker-model-plugin \
docker.io docker-compose docker-doc podman-docker containerd runc"
INSTALLES=$(dpkg-query -W -f='${Package} ${Status}\n' $PAQUETS 2>/dev/null \
            | awk '/install ok installed/ {print $1}')
if [ -n "$INSTALLES" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get purge -y $INSTALLES
else
    echo "Aucun paquet Docker installé."
fi
DEBIAN_FRONTEND=noninteractive apt-get autoremove -y --purge

etape "Suppression des données et de la configuration"
rm -rf /var/lib/docker /var/lib/containerd /etc/docker /run/docker* /var/run/docker.sock
rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources
rm -f /etc/apt/keyrings/docker.asc /etc/apt/keyrings/docker.gpg
rm -rf "$HOME_UTIL/.docker" /root/.docker

etape "Suppression du groupe docker"
getent group docker &>/dev/null && groupdel docker

# Alias du job 05
if [ -f "$HOME_UTIL/.bashrc" ]; then
    sed -i '/^# >>> ALIAS DOCKER >>>$/,/^# <<< ALIAS DOCKER <<<$/d' "$HOME_UTIL/.bashrc"
    echo "Alias Docker retirés de $HOME_UTIL/.bashrc"
fi

if [ "$SUPPR_TP" -eq 1 ]; then
    etape "Suppression des dossiers du TP"
    for d in helloworld ssh-docker web-ftp nginx-debian registry; do
        rm -rf "${HOME_UTIL:?}/$d" && echo "  $HOME_UTIL/$d"
    done
fi

etape "Mise à jour de la liste des paquets"
apt-get update -qq

echo
echo "==================== Vérification ===================="
hash -r
if [ -x /usr/bin/docker ] || [ -x /usr/local/bin/docker ]; then echo "docker est encore présent !"; else echo "Commande docker : absente"; fi
[ -d /var/lib/docker ] && echo "/var/lib/docker existe encore !" || echo "/var/lib/docker : supprimé"
dpkg -l | grep -Ei 'docker|containerd' || echo "Aucun paquet Docker restant"
echo "Système propre."
