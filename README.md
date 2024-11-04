# Distro_images_sync

Ce script permet de télécharger différentes distributions Linux/Unix ou autre image système automatiquement en tentant de façon générique d'avoir toujours la dernière version de l'image.

Le script a été pensé pour être exécuté périodiquement via une tâche Cron ou une unité de service Systemd, ainsi nous pouvons avoir les dernières versions des principales images système Linux et autre en local.

Le script ne fournit pas de système de vérification de l'intégrité et de l'authenticité de l'image téléchargée !

Script non interactif, permettant:

- Télécharger des images systèmes via http et torrent.
- Tester et valider l'accessibilité au serveur distant.
- Mettre à jour quand une nouvelle image système est disponible.
- Supprime les anciennes versions, garde toujours la version là plus à jour.
- Journalisation des erreurs.
- Historique des téléchargements et des suppressions de fichiers.

## Liste des distributions Linux/Unix et autre configurées

* Rocky Linux
* Alma Linux
* Fedora
* FreeBSD
* Ubuntu/Ubuntu Server
* OpenSUSE
* Proxmox
* LinuxMint
* Debian
* ArchLinux
* Kali Linux
* Alpine
* Netboot.xyz
* AntiX
* DR parted live
* HBCD PE
* Ikki Boot
* Ploplinux
* Redorescue
* SyslinuxOS
* Systemrescuecd
* Tails
* Ipfire
* Opnsense
* Q4OS
* Medicat
* TrueNAS

## Types d'images systèmes compatibles

* iso
* img
* dmg
* vmdk
* vhd
* vhdx
* qcow
* qcow2
* wim
* ova
* ovf
* tar
* bz2
* lzma
* 7z

## Méthode de récupération des images systèmes

Voici deux exemples utilisés dans ce script. 

* Exemple 1
  
  ```bash
  # Rocky Linux
  rocky_ver="$(curl -sL https://download.rockylinux.org/pub/rocky | grep -oP '(?<=href=")[0-9]*\.*[0-9]*\.*[0-9]*(?=/">)' | sort -Vr | head -n 1)"
  rocky_url="https://download.rockylinux.org/pub/rocky/${rocky_ver}/isos/x86_64/Rocky-${rocky_ver}-x86_64-dvd.torrent"
  ```
  
  Dans cet exemple la variable rocky_ver récupère la version la plus à jour de la distribution Rocky Linux.
  
  La variable rocky_url récupère l'URL de téléchargement complète.

* Exemple 2
  
  ```bash
  # AntiX
  antix_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/antix-linux/files/latest/download')"
  antix_url="${antix_ver%%\?*}"
  ```
  
  La variable antix_ver récupère l’URL définitive de la dernière version d'AntiX, en suivant les redirections de SourceForge.
- L'option `-w '%{url_effective}'`, permet la récupération de l'URL après redirection.
- La variable `${antix_ver%%\?*}` supprime les arguments de requête HTTP qui suivent l'URL.

## Dépendances logiciel
| Outil  | Description                                                                                                               |
| ------ | ------------------------------------------------------------------------------------------------------------------------- |
| wget   | Permet le téléchargement des fichiers via HTTP, HTTPS, et FTP.                                                            |
| curl   | Utilisé pour récupérer des URLs et autres informations sur les serveurs web distants.                                     |
| cksum  | Génére des sommes de contrôle de fichiers, permet de garder une trace des fichiers téléchargés.                           |
| aria2c | Gestionnaire de téléchargement, supportant HTTP, FTP, SFTP, et BitTorrent, permet de télécharger le fichiers via torrent. |

## Historique et journalisation des actions
Le fichier `.distro_images_sync.log` qui se trouve dans le dossier de téléchargement des images systèmes(/home/$USER/ImagesSys), permet de garder une vue d'ensemble sur l'activité du script(Erreurs et historique de téléchargements).

## Reste à faire
- [ ] Permettre d'indiquer le nombre tolérable d'anciennes versions (par défaut chaque ancienne version est supprimée).
- [ ] Fournir un système de vérification de l'intégrité/l'authenticité de chaque image téléchargée !

