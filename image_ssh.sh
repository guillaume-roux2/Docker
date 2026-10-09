#!/bin/bash
# =============================================================================
# Job 04 - Image SSH faite maison (root / root123), port redirigé 2222 -> 22
# Usage : bash image_ssh.sh [port]     (port par défaut : 2222)
# =============================================================================
set -euo pipefail

DOSSIER=~/ssh-docker
IMAGE=ssh-debian
CONTENEUR=serveur-ssh
PORT="${1:-2222}"

mkdir -p "$DOSSIER"
cd "$DOSSIER"

echo "==> Création du Dockerfile"
cat > Dockerfile <<'EOF'
FROM debian:trixie-slim

# Installation du serveur SSH
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-server && \
    rm -rf /var/lib/apt/lists/*

# Dossier requis par sshd (pas de systemd dans un conteneur)
RUN mkdir -p /run/sshd

# Mot de passe root
RUN echo 'root:root123' | chpasswd

# Autoriser la connexion root par mot de passe
RUN printf 'PermitRootLogin yes\nPasswordAuthentication yes\n' \
    > /etc/ssh/sshd_config.d/root.conf

EXPOSE 22

# sshd au premier plan (-D), sinon le conteneur s'arrête
CMD ["/usr/sbin/sshd", "-D"]
EOF

echo "==> Construction de l'image $IMAGE"
docker build -t "$IMAGE" .

echo "==> (Re)création du conteneur $CONTENEUR sur le port $PORT"
docker rm -f "$CONTENEUR" &>/dev/null || true
docker run -d --name "$CONTENEUR" --restart unless-stopped -p "$PORT":22 "$IMAGE"

# Nouvelles clés à chaque conteneur : on efface l'ancienne empreinte
ssh-keygen -R "[localhost]:$PORT" &>/dev/null || true

sleep 2
docker ps --filter "name=$CONTENEUR"

echo
echo "==> Test du port"
if timeout 3 bash -c "exec 3<>/dev/tcp/127.0.0.1/$PORT && head -c 20 <&3"; then
    echo "  <- bannière SSH reçue, le serveur répond."
else
    echo "  Le serveur ne répond pas. Logs :"; docker logs "$CONTENEUR"
fi

IP=$(ip -4 route get 1.1.1.1 | grep -oP 'src \K\S+')
echo
echo "Connexion (mot de passe : root123) :"
echo "  depuis la VM : ssh root@localhost -p $PORT"
echo "  depuis le PC : ssh root@$IP -p $PORT"
