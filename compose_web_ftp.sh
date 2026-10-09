#!/bin/bash
# =============================================================================
# Job 07 - Docker Compose : nginx + FTP liés, volume commun pour le site web
# Ensuite : envoyer index.html depuis le PC avec FileZilla.
# Usage : bash compose_web_ftp.sh [utilisateur_ftp] [mot_de_passe]
# =============================================================================
set -euo pipefail

DOSSIER=~/web-ftp
FTP_USER="${1:-$USER}"
FTP_PASS="${2:-ftp123}"
IP=$(ip -4 route get 1.1.1.1 | grep -oP 'src \K\S+')

# Ports nécessaires : 80, 21, 21000-21010
for p in 80 21; do
    if docker ps --format '{{.Names}} {{.Ports}}' | grep -q "0.0.0.0:$p->"; then
        echo "Le port $p est déjà utilisé par :"
        docker ps --format '  {{.Names}} -> {{.Ports}}' | grep "0.0.0.0:$p->"
        echo "Supprime ce conteneur (docker rm -f NOM) puis relance." >&2
        exit 1
    fi
done

mkdir -p "$DOSSIER"
cd "$DOSSIER"

echo "==> Création de docker-compose.yml"
cat > docker-compose.yml <<EOF
services:

  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
    volumes:
      - web:/usr/share/nginx/html:ro
    networks:
      - reseau-web
    restart: unless-stopped

  ftp:
    image: delfer/alpine-ftp-server
    container_name: ftp
    ports:
      - "21:21"
      - "21000-21010:21000-21010"
    environment:
      USERS: "$FTP_USER|$FTP_PASS|/ftp/$FTP_USER"
      ADDRESS: "$IP"
      MIN_PORT: "21000"
      MAX_PORT: "21010"
    volumes:
      - web:/ftp/$FTP_USER
    networks:
      - reseau-web
    depends_on:
      - nginx
    restart: unless-stopped

volumes:
  web:

networks:
  reseau-web:
EOF
cat docker-compose.yml

echo "==> Lancement"
docker compose up -d
sleep 3

# L'utilisateur FTP doit pouvoir écrire dans le volume
docker compose exec -T ftp chown -R "$FTP_USER" "/ftp/$FTP_USER"

docker compose ps

echo
echo "==> Vérification du volume commun"
docker compose exec -T ftp sh -c "echo ok > /ftp/$FTP_USER/test.txt"
echo -n "nginx lit le fichier écrit par ftp : "
docker compose exec -T nginx cat /usr/share/nginx/html/test.txt
docker compose exec -T ftp rm "/ftp/$FTP_USER/test.txt"

cat <<EOF

================ Étape suivante sur ton PC ================
1. Crée index.html (avec ton prénom et ton nom) dans le Bloc-notes,
   "Type : Tous les fichiers", encodage UTF-8.
2. FileZilla > Gestionnaire de sites > Nouveau site :
     Protocole       : FTP
     Hôte            : $IP      Port : 21
     Chiffrement     : Connexion FTP simple (non sécurisée)
     Identifiant     : $FTP_USER
     Mot de passe    : $FTP_PASS
3. Glisse index.html dans le panneau de droite (accepte "Écraser").
4. Ouvre http://$IP  (Ctrl+F5 pour vider le cache)
===========================================================
EOF
