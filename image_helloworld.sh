#!/bin/bash
# =============================================================================
# Job 03 - Recréer "helloworld" avec un Dockerfile depuis une Debian minimale
# Usage : bash image_helloworld.sh
# =============================================================================
set -euo pipefail

DOSSIER=~/helloworld
IMAGE=helloworld

mkdir -p "$DOSSIER"
cd "$DOSSIER"

echo "==> Création du Dockerfile dans $DOSSIER"
cat > Dockerfile <<'EOF'
# Image de départ : Debian 13 minimale
FROM debian:trixie-slim

LABEL maintainer="guidoc"

# Commande exécutée au lancement du conteneur
CMD ["echo", "Hello from Debian ! Mon conteneur helloworld fonctionne."]
EOF
cat Dockerfile

echo
echo "==> Construction de l'image $IMAGE"
docker build -t "$IMAGE" .

echo
echo "==> Images disponibles"
docker images | grep -E "REPOSITORY|IMAGE|$IMAGE|debian"

echo
echo "==> Lancement du conteneur (--rm : supprimé automatiquement après)"
docker run --rm "$IMAGE"
