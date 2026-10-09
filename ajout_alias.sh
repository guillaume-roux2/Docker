#!/bin/bash
# =============================================================================
# Job 05 - Ajouter des alias Docker dans ~/.bashrc
# Le bloc est délimité par des marqueurs : relancer le script le remplace
# au lieu de le dupliquer.
# Usage : bash ajout_alias.sh   puis   source ~/.bashrc
# =============================================================================
set -euo pipefail

BASHRC=~/.bashrc
DEBUT="# >>> ALIAS DOCKER >>>"
FIN="# <<< ALIAS DOCKER <<<"

touch "$BASHRC"
cp "$BASHRC" "$BASHRC.bak"

# Supprime un ancien bloc s'il existe
sed -i "/^$DEBUT\$/,/^$FIN\$/d" "$BASHRC"

cat >> "$BASHRC" <<'EOF'
# >>> ALIAS DOCKER >>>
# --- Images ---
alias di='docker images'
alias dpull='docker pull'
alias drmi='docker rmi'
alias db='docker build -t'                 # db monimage .
# --- Conteneurs ---
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dr='docker run'
alias drd='docker run -d'
alias dstart='docker start'
alias dstop='docker stop'
alias drs='docker restart'
alias drm='docker rm'
alias drmf='docker rm -f'
alias dl='docker logs'
alias dlf='docker logs -f'
alias dst='docker stats'
# --- Volumes / réseaux ---
alias dvl='docker volume ls'
alias dvi='docker volume inspect'
alias dvrm='docker volume rm'
alias dnl='docker network ls'
# --- Compose ---
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcps='docker compose ps'
alias dcl='docker compose logs -f'
# --- Nettoyage ---
alias dstopall='docker stop $(docker ps -q)'
alias drmall='docker container prune -f'
alias dprune='docker system prune -f'
# --- Fonctions (argument au milieu de la commande) ---
dsh()  { docker exec -it "$1" sh -c 'command -v bash >/dev/null && exec bash || exec sh'; }
dip()  { docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"; }
drmimg() { docker rm -f $(docker ps -aq --filter ancestor="$1") 2>/dev/null; docker rmi "$1"; }
dhelp() { grep -E "^alias d|^d[a-z]+\(\)" ~/.bashrc; }
# <<< ALIAS DOCKER <<<
EOF

echo "Alias ajoutés dans $BASHRC (sauvegarde : $BASHRC.bak)."
echo "Active-les avec :  source ~/.bashrc   puis tape  dhelp"
