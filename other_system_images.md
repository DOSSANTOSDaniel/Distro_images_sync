# Autres images système

## Images au format ISO

```bash
# Manjaro XFCE
manjaro_xfce_url="$(curl -sL https://manjaro.org/products/download/x86 | grep -oP '(?<=href=")http[s]?://download.manjaro.org/xfce/[0-9]+(\.?[0-9]*)*/manjaro-xfce-[0-9]+(\.?[0-9]*)*-[0-9]*-linux[0-9]*\.iso(?=" )' | sort -Vr | head -n 1)"

# Yunohost
yunohost_ver="$(curl -sL https://repo.yunohost.org/images/ | grep -oP 'yunohost-[A-Za-z]+-[0-9]+(\.?[0-9]*)*-amd64-stable.iso' | sort -Vr | head -n 1)"
yunohost_url="https://repo.yunohost.org/images/$yunohost_ver"

# EndeavourOS
endeavouros_ver="$(curl -sL https://mirror.alpix.eu/endeavouros/iso/ | grep -oP '(?<=href=")EndeavourOS_Endeavour-[0-9]+(\.?[0-9]*)*\.iso\.torrent(?=">)' | sort -Vr | head -n 1)"
endeavouros_url="https://mirror.alpix.eu/endeavouros/iso/$endeavouros_ver"

# NixOS
nixos_url="$(curl -sL https://nixos.org/download/ | grep -oP '(?<=href=")http[s]?://channels.nixos.org/nixos-[0-9]+(\.?[0-9]*)*/latest-nixos-gnome-x86_64-linux.iso(?=")' | sort -Vr | head -n 1)"

# Trisquel
trisquel_ver="$(curl -sL https://cdimage.trisquel.info/trisquel-images/ | grep -oP '(?<=href=")triskel_[0-9]+(\.?[0-9]*)*_amd64.iso.torrent(?=">)' | sort -Vr | head -n 1)"
trisquel_url="https://cdimage.trisquel.info/trisquel-images/$trisquel_ver"

# TinycoreLinux
tinycorelinux_ver="$(curl -sL http://www.tinycorelinux.net/downloads.html | grep -oP '(?<=href=")[0-9]+\.x/x86/release/CorePlus-current\.iso(?=">)' | sort -Vr | head -n 1)"
tinycorelinux_url="http://www.tinycorelinux.net/$tinycorelinux_ver"

# MX Linux
mxlinux_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/mx-linux/files/latest/download')"
mxlinux_url="${mxlinux_ver%%\?*}"

# Clonezilla
clonezilla_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/clonezilla/files/latest/download')"
clonezilla_url="${clonezilla_ver%%\?*}"

# Openmediavault
openmediavault_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/openmediavault/files/latest/download')"
openmediavault_url="${openmediavault_ver%%\?*}"

# CachyOS
cachyos_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/cachyos-arch/files/latest/download')"
cachyos_url="${cachyos_ver%%\?*}"

# SnalLinux
snal_ver="$(curl -sL -I -o /dev/null -w '%{url_effective}' 'https://sourceforge.net/projects/snallinux/files/latest/download')"
snal_url="${snal_ver%%\?*}"

# MiniOS
minios_git_api="https://api.github.com/repos/minios-linux/minios-live/releases/latest"
minios_url="$(curl -s "$API_URL" | grep -oP '"browser_download_url":\s*"\K[^"]+/minios-bookworm-xfce-ultra-en-lkm-aufs-amd64-zstd-[0-9]+_[0-9]+.iso' | sort -Vr | head -n 1)"

# Virtio-win 
virtio_win_ver="$(curl -sL https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/ | grep -oP '(?<=href=")virtio-win-[0-9]+(\.?[0-9]*)*-[0-9]+(?=/">)' | sort -Vr | head -n 1)"
virtio_win_url="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/$virtio_win_ver/virtio-win.iso"

# Iumkit
iumkit_ver="$(curl -sL 'https://www.iumkit.net/portail/wp-content/uploads/downloads/dium/' | grep -oP '(?<=href=")Depannium-[0-9]+\.?[0-9]*-[0-9]*\.iso(?=">)' | sort -Vr | head -n 1)"
iumkit_url="https://www.iumkit.net/portail/wp-content/uploads/downloads/dium/$iumkit_ver"

# IPFire
ipfire_ver="$(curl -sL 'https://www.ipfire.org/' | grep -oP 'Latest\s+Release:\s+IPFire\s+\K[0-9]+\.[0-9]+' | sort -Vr | head -n 1)"
ipfire_ver1="$(curl -sL 'https://www.ipfire.org/' | grep -oP 'Core\s+Update\s+\K[0-9]+' | sort -Vr | sed -n 2p)"
ipfire_url="https://downloads.ipfire.org/releases/ipfire-${ipfire_ver%%.*}.x/${ipfire_ver}-core${ipfire_ver1}/ipfire-${ipfire_ver}-core${ipfire_ver1}-x86_64.iso"

# Fedora Silverblue
fedorasil_ver="$(curl -sL https://torrent.fedoraproject.org/torrents/ | grep -oP 'href="\KFedora-Silverblue-ostree-x86_64-[0-9]+\.torrent' | sort -Vr | head -n 1)"
fedorasil_url="https://torrent.fedoraproject.org/torrents/${fedora_ver}"

# Secure-K OS
securek_url="$(curl -s https://api.github.com/repos/LumIT-Labs/open-securekos/releases/latest | grep "browser_download_url" | grep "open-securek-os-initial-image.iso" | cut -d '"' -f 4)"

# Parrot
parrot_ver="$(curl -sL https://deb.parrot.sh/parrot/iso/ | grep -oP 'href="\K([0-9]+\.){2}[0-9]+' | sort -Vr | head -n 1)"
parrot_url="https://deb.parrot.sh/parrot/iso/${parrot_ver}/Parrot-security-${parrot_ver}_amd64.iso.torrent
```

