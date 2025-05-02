#!/usr/bin/env bash

#--------------------------------------------------#
# Script_Name: distro_images_sync.sh
#
# Author:  'dossantosjdf@gmail.com'
#
# Date: 02/05/2025
# Version: 3.0
# Bash_Version: 5.1.16
#--------------------------------------------------#
# Description:
#
# Script non interactif, permettant:
# - Télécharger des images système des principales distributions Linux/Unix via http et torrent.
# - Tester et valider l'accessibilité au site de téléchargement.
# - Mettre à jour quand une nouvelle image ISO est disponible.
# - Supprime les anciennes versions, garde toujours la version là plus à jour.
# - Journalisation des erreurs.
# - Historique des téléchargements et des suppressions de fichiers.
#

# Variables
# Dossier de stockage des fichiers image
images_dir="$HOME/ImagesSys"

# Fichier où seront stockées les empreintes de chaque iso
init_sum="/tmp/.init_imgs_sum"
final_sum="$images_dir/.imgs_sum"

# Fichier de logs
script_file="$(basename "${0##\.\/}")"
script_name="${script_file%%\.sh}"
log_date="$(date '+%Y_%m_%d_%H%M%S')"
log_file="$images_dir/.${script_name}.log"

# Limite de la bande passante
# Bande passante WAN 581 Mbits/sec
# Conversion Mbits/sec → MBytes/sec ou MO/s
# 581/8 = 72.625 MB ou MO
limit_download_bandwidth='50m'

# Limite du nombre de tentatives de téléchargements en cas d'échec
limit_download_tries='3'

# Options Wget
# --tries : Tentatives en cas d'échec
wget_tries="$limit_download_tries"
# --timeout : Délai d'attente max pour la réponse d'un serveur
wget_timeout='60'
# --limit-rate : Limite la bande passante sur wget
wget_limit_rate="$limit_download_bandwidth"
# --wait : Attendre entre chaque téléchargement
wget_wait='3'

# Options aria2c
# --max-download-limit : Limite la bande passante.
aria_max_download_limit="$limit_download_bandwidth"
# --max-tries : Limite le nombre de tentatives en cas d'échec.
aria_max_tries="$limit_download_tries"
# --retry-wait : Attente en secondes entre chaque nouvelle tentative.
aria_retry_wait='10' 

# Dépendances nécessaire au bon fonctionnement du script
dependencies=('curl' 'aria2c' 'wget' 'cksum')

# URLs des différentes images systèmes a télécharger
# Rocky Linux
rocky_ver="$(curl -sL https://download.rockylinux.org/pub/rocky | grep -oP '(?<=href=")[0-9]+(\.?[0-9]*)*(?=/">)' | sort -Vr | head -n 1)"
rocky_url="https://download.rockylinux.org/pub/rocky/${rocky_ver}/isos/x86_64/Rocky-${rocky_ver}-x86_64-dvd.torrent"

# Alma Linux
alma_ver="$(curl -sL https://repo.almalinux.org/almalinux/ | grep -oP '(?<=href=")[0-9]+(\.?[0-9]*)*(?=/">)' | sort -Vr | head -n 1)"
alma_url="https://raw.repo.almalinux.org/almalinux/${alma_ver}/isos/x86_64/AlmaLinux-${alma_ver}-x86_64.torrent"

# Fedora
fedora_ver="$(curl -sL https://torrent.fedoraproject.org/torrents/ | grep -oP '(?<=href=")Fedora-Workstation-Live-x86_64-[0-9]+(\.?[0-9]*)*\.torrent(?=">)' | sort -Vr | head -n 1)"
fedora_url="https://torrent.fedoraproject.org/torrents/${fedora_ver}"

# FreeBSD
freebsd_ver="$(curl -sL https://www.freebsd.org/ | grep -A 1 'Production:' | tr -d '\n' | grep -oP 'releases/\K[0-9]+(\.?[0-9]*)*')"
freebsd_url="https://download.freebsd.org/releases/ISO-IMAGES/${freebsd_ver}/FreeBSD-${freebsd_ver}-RELEASE-amd64-dvd1.iso"

# Ubuntu Server
ubuntu_ver="$(curl -sL https://releases.ubuntu.com/ | grep -oP '(?<=href=")[0-9]+\.04\.?[0-9]*(?=/">)' | sort -Vr | head -n 1)"
ubuntusrv_url="https://releases.ubuntu.com/${ubuntu_ver}/ubuntu-${ubuntu_ver}-live-server-amd64.iso.torrent"

# Ubuntu
ubuntu_url="https://releases.ubuntu.com/${ubuntu_ver}/ubuntu-${ubuntu_ver}-desktop-amd64.iso.torrent"

# OpenSUSE
opensuse_ver="$(curl -sL https://get.opensuse.org/leap | grep -oP '(?<=href="/leap/)[0-9]+(\.?[0-9]*)*(?=/">)')"
opensuse_url="https://download.opensuse.org/distribution/leap/${opensuse_ver}/iso/openSUSE-Leap-${opensuse_ver}-DVD-x86_64-Current.iso"

# Proxmox
proxmox_ver="$(curl -sL https://enterprise.proxmox.com/iso/ | grep -oP '(?<=href=")proxmox-ve_[0-9]+(\.?[0-9]*)*-[0-9]*\.iso(?=">)' | sort -Vr | head -1)"
proxmox_url="https://enterprise.proxmox.com/iso/${proxmox_ver}"

# LinuxMint
mint_ver="$(curl -sL https://www.linuxmint.com/download.php | grep -oP 'Linux Mint \K[0-9]+\.[0-9]+' | sort -Vr | head -n 1)"
mint_url="https://www.linuxmint.com/torrents/linuxmint-${mint_ver}-cinnamon-64bit.iso.torrent"

# Debian
debian_ver="$(curl -sL https://cdimage.debian.org/debian-cd/current/amd64/bt-dvd/ | grep -oP '(?<=href=")debian-[0-9]+(\.?[0-9]*)*-amd64-DVD-1\.iso\.torrent(?=">)' | sort -Vr | head -n 1)"
debian_url="https://cdimage.debian.org/debian-cd/current/amd64/bt-dvd/${debian_ver}"

# ArchLinux
arch_url="https://archlinux.mirrors.ovh.net/archlinux/iso/latest/archlinux-x86_64.iso"

# Kali Linux live
kali_ver="$(curl -sL https://kali.download/base-images/current/ | grep -oP '(?<=href=")kali-linux-[0-9]+(\.?[0-9]*)*[a-z]*-live-amd64\.iso\.torrent(?=")' | sort -rV | head -n 1)"
kali_url="https://kali.download/base-images/current/${kali_ver}"

# Kali everything live
#kali_e_ver="$(curl -sL https://kali.download/base-images/current/ | grep -oP '(?<=href=")kali-linux-[0-9]+(\.?[0-9]*)*[a-z]*-live-everything-amd64\.iso\.torrent(?=")' | sort -rV | head -n 1)"
#kali_e_url="https://kali.download/base-images/current/${kali_e_ver}"

# Kali everything live
kali_e_ver="$(curl -sL https://kali.download/base-images/current/ | grep -oP '(?<=href=")kali-linux-[0-9]+(\.?[0-9]*)*[a-z]*-live-everything-amd64\.iso\.torrent(?=")' | sort -rV | head -n 1)"
kali_e_url="https://kali.download/base-images/current/${kali_e_ver}"

# Alpine
alpine_ver="$(curl -sL https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/ | grep -oP '(?<=href=")alpine-extended-[0-9]+(\.?[0-9]*)*-x86_64\.iso(?=">)' | sort -rV | head -n 1)"
alpine_url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/${alpine_ver}"

# Netboot.xyz
netboot_url="https://boot.netboot.xyz/ipxe/netboot.xyz.iso"

# AntiX
antix_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/antix-linux/files/latest/download')"
antix_url="${antix_ver%%\?*}"

# DR parted live
drpart_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/dr-parted-live/files/latest/download')"
drpart_url="${drpart_ver%%\?*}"

# HBCD PE
hbcd_url='https://www.hirensbootcd.org/files/HBCD_PE_x64.iso'

# Ikki Boot
ikki_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/ikkiboot/files/latest/download')"
ikki_url="${ikki_ver%%\?*}"

# Ploplinux
plop_ver="$(curl -sL https://download.plop.at/ploplinux/ | grep -oP '(?<=href=")[0-9]+(\.?[0-9]*)*(?=/">)' | sort -r | head -n 1)"
plop_url="https://download.plop.at/ploplinux/$plop_ver/live/ploplinux-${plop_ver}-x86_64.iso"

# Redorescue
redor_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/redobackup/files/latest/download')"
redor_url="${redor_ver%%\?*}"

# SyslinuxOS
syslinux_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/syslinuxos/files/latest/download')"
syslinux_url="${syslinux_ver%%\?*}"

# Systemrescuecd
systemr_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/systemrescuecd/files/latest/download')"
systemr_url="${systemr_ver%%\?*}"

# Tails
tails_ver="$(curl -sL https://tails.net/torrents/files/ | grep -oP '(?<=href=")tails-amd64-[0-9]+(\.?[0-9]*)*\.iso\.torrent(?=")')"
tails_url="https://tails.net/torrents/files/$tails_ver"

# Ipfire
ipfire_url="$(curl -sL https://downloads.ipfire.org | grep -oP '(?<=href=")[a-z]*://.*x86_64\.iso')"

# Opnsense
opnsense_ver="$(curl -sL https://mirror.ams1.nl.leaseweb.net/opnsense/releases/ | grep -oP '(?<=href=")[0-9]+(\.?[0-9]*)*(?=/" )' | sort -Vr | head -n 1)"
opnsense_url="https://mirror.ams1.nl.leaseweb.net/opnsense/releases/$opnsense_ver/OPNsense-${opnsense_ver}-dvd-amd64.iso.bz2"

# Q4OS
q4os_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/q4os/files/latest/download')"
q4os_url="${q4os_ver%%\?*}"

# Medicat
medicat_ver="$(curl -sL https://github.com/mon5termatt/medicat_installer/tree/main/download/ | grep -Eo 'MediCat_USB_v[0-9]+\.[0-9]+\.torrent' | sort -Vr | head -n 1)"
medicat_url="https://raw.githubusercontent.com/mon5termatt/medicat_installer/main/download/$medicat_ver"

# TrueNas
truenas_url="$(curl -sL https://www.truenas.com/download-truenas-scale/ | grep 'Download STABLE' | grep -oP 'href="\Khttp[s]?://[^"]+\.iso')"

# Déclaration du tableau associatif pour stocker les URLs de chaque distribution
declare -A distros

distros=(
  [rockylinux]="$rocky_url ${rocky_ver-noset}"
  [almalinux]="$alma_url ${alma_ver-noset}"
  [fedora]="$fedora_url ${fedora_ver-noset}"
  [freebsd]="$freebsd_url ${freebsd_ver-noset}"
  [ubuntusrv]="$ubuntusrv_url ${ubuntusrv_ver-noset}"
  [ubuntu]="$ubuntu_url ${ubuntu_ver-noset}"
  [opensuse]="$opensuse_url ${opensuse_ver-noset}"
  [proxmox]="$proxmox_url ${proxmox_ver-noset}"
  [linuxmint]="$mint_url ${mint_ver-noset}"
  [debian]="$debian_url ${debian_ver-noset}"
  [archlinux]="$arch_url ${arch_ver-noset}"
  [kalilinux]="$kali_url ${kali_ver-noset}"
  [kali_ever]="$kali_e_url ${kali_e_ver-noset}"
  [netboot]="$netboot_url ${netboot_ver-noset}"
  [alpine]="$alpine_url ${alpine_ver-noset}"
  [antix]="$antix_url ${antix_ver-noset}"
  [drpart]="$drpart_url ${drpart_ver-noset}"
  [hbcd]="$hbcd_url ${hbcd_ver-noset}"
  [ikki]="$ikki_url ${ikki_ver-noset}"
  [plop]="$plop_url ${plop_ver-noset}"
  [redor]="$redor_url ${redor_ver-noset}"
  [syslinux]="$syslinux_url ${syslinux_ver-noset}"
  [systemr]="$systemr_url ${systemr_ver-noset}"
  [tails]="$tails_url ${tails_ver-noset}"
  [ipfire]="$ipfire_url ${ipfire_ver-noset}"
  [opnsense]="$opnsense_url ${opnsense_ver-noset}"
  [q4os]="$q4os_url ${q4os_ver-noset}"
  [medicat]="$medicat_url ${medicat_ver-noset}"
  [truenas]="$truenas_url ${truenas_ver-noset}"
)

# Fonctions
# Fonction permettant la journalisation
message_log() {
  local msglog="$1"
  echo -e "\n $msglog \n" > "$log_file"
}

# Main
# Création du dossier de stockage des images s'il n'existe pas
if [ ! -d "$images_dir" ]; then
    mkdir -p "$images_dir"
fi

# Bannière fichier log
message_log "-------------- Récupération images systèmes : $log_date -------"

# Vérifier les dépendances
for package in "${dependencies[@]}"; do
  if ! command -v "$package" &>/dev/null; then
    message_log "Vérifier l'installation des paquets: ${dependencies[*]}, avant d'utiliser ce script !"
    exit 1
  fi
done

# Configuration du fichier de somme de contrôle
if [ -f "$final_sum" ]; then
  mv "$final_sum" "$init_sum"
fi

# Boucle sur les informations de chaque distribution
for distro in "${!distros[@]}"; do
  # Vérification si la variable de version est utilisé mais vide
  image_ver="$(echo "${distros[$distro]}" | awk '{print $2}')"

  if [[ -z "$image_ver" ]]; then
    message_log "Erreur : La variable de version est vide pour $distro"
    continue
  fi

  # Obtenir les informations sur l'image
  image_sys="$(echo "${distros[$distro]}" | awk '{print $1}')"
  image_file_part="$(basename "$image_sys")"
  image_url_part="$(dirname "$image_sys")"

  # Test de réponse des serveurs distants
  get_domain="$(echo "$image_url_part" | sed -E 's#(https?://)?([^/]+).*#\1\2#')"
  url_response="$(curl -o /dev/null -s -w "%{http_code}\n" "$get_domain")"
  # 200 : Requête réussie, contenu disponible.
  # 301 : Ressource déplacée définitivement à une autre adresse.
  # 302 : Ressource temporairement à une autre adresse.
  # 403 : Interdit, mais le serveur est accessible.
  # 404 : Non trouvé, mais le serveur a répondu.
  if [[ $url_response =~ ^(200|301|302|403|404)$ ]]; then
    if [ -n "$image_file_part" ]; then
      # Verifie si c'est un fichier torrent
      if echo "$image_file_part" | grep -q '\.torrent$'; then
        # Téléchargement du fichier image via torrent
        # --continue : Permet de reprendre un téléchargement interrompu.
        # --seed-time : Ne partage pas le fichiers via torrent après le téléchargement.
        # --max-tries : Limite le nombre de tentatives en cas d'échec.
        # --retry-wait : Attente en secondes entre chaque nouvelle tentative.
        # --max-download-limit : Limite la vitesse de téléchargement.
        # --check-integrity : Vérifie l'intégrité du fichier, s'il existe déjà, aria2 ne le télécharge pas.
	# --save-session : Sauvegarde la session actuelle utile pour reprendre plus tard si besoin.
        aria2c --dir="$images_dir" \
          --continue=true \
          --seed-time=0 \
          --max-connection-per-server=16 \
          --min-split-size=1M \
          --split=32 \
          --max-tries="$aria_max_tries" \
          --retry-wait="$aria_retry_wait" \
          --max-download-limit="$aria_max_download_limit" \
          --check-integrity=true \
          --bt-tracker="\
        udp://tracker.kali.org:6969/announce,\
        http://tracker.kali.org:6969/announce,\
        udp://tracker.opentrackr.org:1337/announce,\
        udp://open.tracker.cl:1337/announce,\
        udp://tracker.openbittorrent.com:6969/announce,\
        udp://tracker.torrent.eu.org:451/announce,\
        udp://tracker.internetwarriors.net:1337/announce,\
        http://tracker.bt4g.com:2095/announce,\
        udp://tracker.coppersurfer.tk:6969/announce,\
        udp://exodus.desync.com:6969/announce,\
        udp://tracker.leechers-paradise.org:6969/announce,\
        udp://linuxtracker.org:6969/announce,\
        udp://tracker.archlinux.org:6969/announce,\
        http://bttracker.debian.org:6969/announce,\
        udp://open.demonii.com:1337/announce,\
        udp://retracker.lanta.me:2710/announce,\
        udp://exodus.desync.com:6969/announce" \
          --bt-enable-lpd=true \
          --bt-max-peers=200 \
          --bt-request-peer-speed-limit=0 \
          --bt-save-metadata=true \
          --bt-stop-timeout=600 \
          --auto-save-interval=30 \
          --follow-torrent=mem \
          --follow-metalink=mem \
          --enable-dht=true \
          --enable-peer-exchange=true \
          --save-session="$images_dir/.aria_session" \
          --log-level=info \
          --log="$images_dir/.aria2c.log" \
          --quiet \
          "${image_url_part%/}/$image_file_part"

        if [ "$?" != "0" ]; then
          message_log "Erreur téléchargement: ${image_url_part%/}/$image_file_part !"
        fi

        # Supprime le fichier de metadonnées torrent
        find "$images_dir" -type f -name "*.torrent" -exec rm -f {} \;
      else
        # Téléchargement du fichier image via HTTP
        # Description des options de wget
        # --continue : Permet de reprendre un téléchargement interrompu.
        # --tries= : Tentatives en cas d'échec.
        # --timestamping : Télécharge seulement si les fichiers dans le serveur distant sont plus récents que ceux en local.
        # --no-netrc : Ignore les informations d'authentification.
        # --timeout= : Délai d'attente max pour la réponse d'un serveur.
        # --limit-rate= : Limite la bande passante.
        # --wait= : Attend entre chaque téléchargement.
        # --no-http-keep-alive : Désactive les connexions persistantes.
        # --no-cache : Ignore le cache proxy.
        # --recursive : Télécharge récursivement.
        # --no-parent : Ne remonte pas sur les dossiers parents.
        # --no-directories : Télécharge seulement les fichiers ne crée pas de repertoire.
        # --no-host-directories : Ne crée pas de dossier pour le nom de domaine du site.
        # --directory-prefix : Dossier dans lequel sera stocké le fichier.
        wget --continue \
          --tries="$wget_tries" \
          --timestamping \
          --no-netrc \
          --timeout="$wget_timeout" \
          --limit-rate="$wget_limit_rate" \
          --wait="$wget_wait" \
          --no-http-keep-alive \
          --no-cache \
          --recursive \
          --no-parent \
          --no-directories \
          --no-host-directories \
          --quiet \
          --directory-prefix="$images_dir" "${image_url_part%/}/$image_file_part"

        if [ "$?" != "0" ]; then
          message_log "Erreur: Téléchargement de ${image_url_part%/}/$image_file_part !"
        fi
      fi
    else
      message_log "Erreur: Fichier ${image_url_part%/}/$image_file_part impossible a récupérer !"
    fi
  else
    message_log "Erreur: Serveur injoignable - $get_domain - HTTP: $url_response !"
  fi
done

# Récupération des informations sur les images téléchargées
if [ -n "$(find "$images_dir" -mindepth 1 -print -quit)" ]; then
  # Création des sommes de contrôle des fichiers après actualisation
  find "$images_dir" -type f \( \
      -iname "*.iso" -o \
      -iname "*.img" -o \
      -iname "*.dmg" -o \
      -iname "*.vmdk" -o \
      -iname "*.vhd" -o \
      -iname "*.vhdx" -o \
      -iname "*.qcow" -o \
      -iname "*.qcow2" -o \
      -iname "*.wim" -o \
      -iname "*.ova" -o \
      -iname "*.ovf" -o \
      -iname "*.tar" -o \
      -iname "*.bz2" -o \
      -iname "*.lzma" -o \
      -iname "*.7z" \) -exec cksum {} \; > "$final_sum"

  if [ -f "$init_sum" ]; then
	# Comparer les deux fichiers d'empreintes et récupérer les différences(nouvelles images téléchargées)
    mapfile -t diff_output < <(diff "$init_sum" "$final_sum" | grep "^>" | cut -d' ' -f4-)
    if [ -n "${diff_output[*]}" ]; then
	  # Comparer chaque nouvelle image(check_sum_line) avec la liste des anciennes images(line)
      for check_sum_line in "${diff_output[@]}"; do
        message_log "Mise à jour: $(basename "$check_sum_line")"
        new_file="$(echo "$check_sum_line" | tr -cd '[:alpha:]')" 
		# Lire le fichier init_sum(ancienne sommme de contrôle) ligne par ligne et comparer avec les noms des nouvelles images
        while IFS= read -r line; do
          old_file="$(echo "$line" | tr -cd '[:alpha:]')"
		  # Teste si les deux fichiers sont strictement différents
          if [ "$check_sum_line" != "$line" ]; then
			# Teste si les fichiers ont le même nom mais ont une version ancienne
            if [ "$new_file" = "$old_file" ]; then
              # Supprimer aussi le dossier si le fichier est dans un dossier
              chemin_dossier="$(dirname "$line")"
              rm_dir_file="$(echo "${chemin_dossier#"$images_dir"}" | sed 's/\///')"
              if [ -n "$rm_dir_file" ]; then
                rm -rf "${images_dir:?}/${rm_dir_file:?}" && message_log "Dossier supprimé: $images_dir/$rm_dir_file"
              else
                rm -rf "$line" && message_log "Fichier supprimé: $(basename "$line")"
              fi
            fi
          fi
        done < <(cut -d' ' -f3- "$init_sum")
      done
    else
      message_log "Pas de mises à jour !"
    fi
    # Supprimer le fichier de somme de contrôle initial
    rm -rf "$init_sum"
  else
    # Utilisation du script pour la première fois(pas d'init_sum)
    while IFS= read -r first_file; do
      message_log "Nouveau fichier: $(basename "$first_file")"
    done < <(cut -d' ' -f3- "$final_sum")
  fi
else
  message_log "Le dossier $images_dir est vide !"
fi