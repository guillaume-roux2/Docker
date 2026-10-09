#!/bin/bash
# =============================================================================
# Job 02 - Tester Docker avec "hello-world" et découvrir les commandes de base
# Usage : bash test_hello_world.sh   (en guidoc, membre du groupe docker)
# =============================================================================
set -euo pipefail

etape() { echo; echo "==================== $1 ===================="; }
pause() { read -rp "Appuie sur Entrée pour continuer..." _; }

etape "Version de Docker"
docker --version

etape "Lancement de hello-world"
docker run --name test-hello hello-world
pause

etape "Images présentes (docker images)"
docker images
pause

etape "Conteneurs actifs (docker ps)"
docker ps
echo "-> hello-world n'apparaît pas : il s'est arrêté après avoir affiché son message."

etape "Tous les conteneurs (docker ps -a)"
docker ps -a
pause

etape "Lancement d'un nginx en arrière-plan (port 8080)"
docker rm -f web &>/dev/null || true
docker run -d --name web -p 8080:80 nginx
sleep 2
docker ps
echo
echo "Test avec curl :"
curl -s localhost:8080 | grep -o '<title>.*</title>' || echo "nginx ne répond pas"
echo "Depuis le PC : http://$(hostname -I | awk '{print $1}'):8080"
pause

etape "Logs du conteneur web (docker logs)"
docker logs web

etape "Commande dans le conteneur (docker exec)"
docker exec web nginx -v

etape "Arrêt et suppression (docker stop / rm)"
docker stop web
docker rm web test-hello

etape "Suppression de l'image hello-world (docker rmi)"
docker rmi hello-world

etape "État final"
docker ps -a
docker images
echo
echo "Récapitulatif :"
echo "  docker run / ps / ps -a / images / logs / exec / stop / start / rm / rmi"
