# TP Docker - Scripts par job

Copier le dossier sur la VM (depuis le PC, PowerShell) :

    scp -r tp-docker guidoc@172.16.0.138:~

Puis sur la VM : `cd ~/tp-docker && chmod +x *.sh`

| Job | Script | Lancer en |
|---|---|---|
| 01 | `preparation_vm.sh [user]` - dépôts APT, sudo, open-vm-tools, SSH, Docker CLI | root (`su -`) |
| 02 | `test_hello_world.sh` - hello-world + tour des commandes | guidoc |
| 03 | `image_helloworld.sh` - image helloworld depuis debian:trixie-slim | guidoc |
| 04 | `image_ssh.sh [port]` - image SSH root/root123, port 2222 | guidoc |
| 05 | `ajout_alias.sh` - alias dans ~/.bashrc, puis `source ~/.bashrc` | guidoc |
| 06 | `demo_volumes.sh` - volume partagé entre 2 conteneurs, persistance, :ro, sauvegarde | guidoc |
| 07 | `compose_web_ftp.sh [user] [mdp]` - compose nginx + FTP, volume commun (port 80/21) | guidoc |
| 08 | `image_nginx.sh [port]` - nginx fait maison, port 8081 | guidoc |
| 09 | `registry_local.sh` - registry :5000 + UI :8082, push des images du TP | guidoc |
| 10 | `desinstall_docker.sh [-y] [--tp]` - suppression totale de Docker | sudo |
| 10 | `install_docker.sh [user]` - installation automatique de Docker | sudo |

`index.html` : page à envoyer avec FileZilla au job 07.

Ports utilisés : 80 (nginx compose), 21 + 21000-21010 (FTP), 2222 (SSH), 8081 (nginx maison), 5000 (registry), 8082 (UI registry).
