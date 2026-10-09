#!/bin/bash
# =============================================================================
# Job 06 - Volumes : partage entre deux conteneurs et gestion des volumes
# Démonstration automatique : création, écriture, lecture croisée,
# persistance après suppression, lecture seule, sauvegarde, nettoyage.
# Usage : bash demo_volumes.sh
# =============================================================================
set -euo pipefail

VOLUME=partage
IMAGE=debian:trixie-slim

etape() { echo; echo "==================== $1 ===================="; }

nettoyer() { docker rm -f c1 c2 &>/dev/null || true; }
nettoyer
docker volume rm "$VOLUME" &>/dev/null || true

etape "1. Création du volume '$VOLUME'"
docker volume create "$VOLUME"
docker volume ls

etape "2. Deux conteneurs actifs montent le même volume dans /data"
docker run -dit --name c1 -v "$VOLUME":/data "$IMAGE" >/dev/null
docker run -dit --name c2 -v "$VOLUME":/data "$IMAGE" >/dev/null
docker ps --filter name=c1 --filter name=c2

etape "3. c1 écrit, c2 lit"
docker exec c1 sh -c 'echo "Bonjour depuis c1" > /data/message.txt'
echo -n "c2 lit : "; docker exec c2 cat /data/message.txt

etape "4. c2 répond, c1 lit"
docker exec c2 sh -c 'echo "Réponse de c2" >> /data/message.txt'
echo "c1 lit :"; docker exec c1 cat /data/message.txt

etape "5. Persistance : suppression des deux conteneurs"
nettoyer
echo "Lecture depuis un conteneur neuf :"
docker run --rm -v "$VOLUME":/data "$IMAGE" cat /data/message.txt

etape "6. Montage en lecture seule (:ro)"
docker run --rm -v "$VOLUME":/data:ro "$IMAGE" \
    sh -c 'echo test > /data/x.txt' 2>&1 || echo "-> écriture refusée, comme prévu"

etape "7. Emplacement réel du volume sur la VM"
docker volume inspect "$VOLUME" --format 'Mountpoint : {{.Mountpoint}}'

etape "8. Sauvegarde du volume dans $(pwd)/sauvegarde-$VOLUME.tar.gz"
docker run --rm -v "$VOLUME":/data:ro -v "$(pwd)":/backup "$IMAGE" \
    tar czf /backup/sauvegarde-"$VOLUME".tar.gz -C /data .
ls -lh sauvegarde-"$VOLUME".tar.gz

etape "9. Gestion"
echo "docker volume ls | inspect | rm | prune"
read -rp "Supprimer le volume '$VOLUME' ? (o/N) " rep
if [[ "$rep" =~ ^[oO]$ ]]; then
    docker volume rm "$VOLUME" && echo "Volume supprimé."
else
    echo "Volume conservé."
fi
