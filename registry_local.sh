#!/bin/bash
# =============================================================================
# Job 09 - Registry local (port 5000) + interface web (port 8082)
# Pousse automatiquement les images du TP (helloworld, ssh-debian,
# nginx-debian) si elles existent, puis teste un pull.
# Usage : bash registry_local.sh
# =============================================================================
set -euo pipefail

DOSSIER=~/registry
REG=localhost:5000
IP=$(hostname -I | awk '{print $1}')

mkdir -p "$DOSSIER"
cd "$DOSSIER"

echo "==> Création de docker-compose.yml"
cat > docker-compose.yml <<'EOF'
services:

  registry:
    image: registry:2
    container_name: registry
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_DELETE_ENABLED: "true"
    volumes:
      - registry-data:/var/lib/registry
    networks:
      - reseau-registry
    restart: unless-stopped

  registry-ui:
    image: joxit/docker-registry-ui:latest
    container_name: registry-ui
    ports:
      - "8082:80"
    environment:
      REGISTRY_TITLE: "Registry de guidoc"
      NGINX_PROXY_PASS_URL: "http://registry:5000"
      SINGLE_REGISTRY: "true"
      DELETE_IMAGES: "true"
      SHOW_CONTENT_DIGEST: "true"
    networks:
      - reseau-registry
    depends_on:
      - registry
    restart: unless-stopped

volumes:
  registry-data:

networks:
  reseau-registry:
EOF

echo "==> Lancement du registry et de l'UI"
docker compose up -d

echo -n "Attente du registry"
for _ in $(seq 1 20); do
    curl -sf "http://$REG/v2/" >/dev/null && break
    echo -n "."; sleep 1
done
echo

echo "==> Envoi des images du TP"
for img in helloworld ssh-debian nginx-debian; do
    if docker image inspect "$img" &>/dev/null; then
        docker tag "$img" "$REG/$img:1.0"
        docker push "$REG/$img:1.0"
    else
        echo "  (image $img absente, ignorée - lance le job correspondant)"
    fi
done

# Si aucune image du TP, on pousse au moins hello-world
if ! curl -s "http://$REG/v2/_catalog" | grep -q '"[a-z]'; then
    docker pull hello-world
    docker tag hello-world "$REG/hello-world:1.0"
    docker push "$REG/hello-world:1.0"
fi

echo
echo "==> Contenu du registry"
curl -s "http://$REG/v2/_catalog"; echo

echo
echo "==> Test : suppression locale puis pull depuis le registry"
TEST=$(curl -s "http://$REG/v2/_catalog" | sed -E 's/.*\["([^"]+)".*/\1/')
docker rmi "$REG/$TEST:1.0" >/dev/null
docker pull "$REG/$TEST:1.0"

cat <<EOF

Interface web : http://$IP:8082
Commandes utiles :
  docker tag IMAGE $REG/NOM:TAG && docker push $REG/NOM:TAG
  docker pull $REG/NOM:TAG
  curl $REG/v2/_catalog
  curl $REG/v2/NOM/tags/list
Libérer l'espace après suppression dans l'UI :
  docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml
EOF
