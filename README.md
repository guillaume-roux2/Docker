# TP Docker - Scripts par job

Récupérer les scripts sur une Debian 12 ou 13 (amd64 / arm64) :

    git clone https://github.com/guillaume-roux2/Docker.git

Puis sur la VM : `cd Docker && chmod +x *.sh`

| Job | Script | Lancer en |
|---|---|---|
| 01 | `preparation_vm.sh [user]` (défaut : premier utilisateur créé) - dépôts APT, sudo, open-vm-tools, SSH, Docker CLI | root (`su -`) |
| 02 | `test_hello_world.sh` - lance le conteneur hello-world | utilisateur (groupe docker) |
| 03 | `image_helloworld.sh` - image helloworld depuis debian:trixie-slim | utilisateur (groupe docker) |
| 04 | `image_ssh.sh [port]` - image SSH root/root123, port 2222 | utilisateur (groupe docker) |
| 05 | `ajout_alias.sh` - alias dans ~/.bashrc, puis `source ~/.bashrc` | utilisateur (groupe docker) |
| 06 | `demo_volumes.sh` - volume partagé entre 2 conteneurs, persistance, :ro, sauvegarde | utilisateur (groupe docker) |
| 07 | `compose_web_ftp.sh [user] [mdp]` - compose nginx + FTP, volume commun (port 80/21) | utilisateur (groupe docker) |
| 08 | `image_nginx.sh [port]` - nginx fait maison, port 8081 | utilisateur (groupe docker) |
| 09 | `registry_local.sh` - registry :5000 + UI :8082, push des images du TP | utilisateur (groupe docker) |
| 10 | `desinstall_docker.sh [-y] [--tp]` - suppression totale de Docker | sudo |
| 10 | `install_docker.sh [user]` - installation automatique de Docker | sudo |

`index.html` : page à envoyer avec FileZilla au job 07.

Ports utilisés : 80 (nginx compose), 21 + 21000-21010 (FTP), 2222 (SSH), 8081 (nginx maison), 5000 (registry), 8082 (UI registry).
