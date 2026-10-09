#!/bin/bash
# =============================================================================
# Job 08 - Image nginx faite maison depuis Debian, port redirigé 8081 -> 80
# Usage : bash image_nginx.sh [port]     (port par défaut : 8081)
# =============================================================================
set -euo pipefail

DOSSIER=~/nginx-debian
IMAGE=nginx-debian
CONTENEUR=mon-nginx
PORT="${1:-8081}"

mkdir -p "$DOSSIER"
cd "$DOSSIER"

echo "==> Création de la page d'accueil"
cat > index.html <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><title>Mon nginx</title></head>
<body>
    <h1>Nginx fait maison</h1>
    <p>Image construite depuis Debian avec un Dockerfile.</p>
</body>
</html>
EOF

echo "==> Création du Dockerfile"
cat > Dockerfile <<'EOF'
FROM debian:trixie-slim

# Installation de nginx
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    rm -rf /var/lib/apt/lists/*

# Logs visibles avec "docker logs"
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Notre page remplace celle par défaut
COPY index.html /var/www/html/index.html

EXPOSE 80

# nginx au premier plan, sinon le conteneur s'arrête
CMD ["nginx", "-g", "daemon off;"]
EOF

echo "==> Construction de l'image $IMAGE"
docker build -t "$IMAGE" .

echo "==> (Re)création du conteneur $CONTENEUR sur le port $PORT"
docker rm -f "$CONTENEUR" &>/dev/null || true
docker run -d --name "$CONTENEUR" --restart unless-stopped -p "$PORT":80 "$IMAGE"

sleep 2
docker ps --filter "name=$CONTENEUR"

echo
echo "==> Test avec curl"
curl -s "localhost:$PORT" | grep -o '<h1>.*</h1>' || { echo "Pas de réponse :"; docker logs "$CONTENEUR"; }

echo
echo "Ouvre depuis le PC : http://$(ip -4 route get 1.1.1.1 | grep -oP 'src \K\S+'):$PORT"
echo "Logs en direct     : docker logs -f $CONTENEUR"
