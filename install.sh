#!/bin/bash

######### Prepare Setup ##########
loadkeys de-latin1;
timedatectl set-ntp true;
reflector \
    --latest 5 \
    --sort rate \
    --country Austria,France,Germany,Switzerland \
    --save /etc/pacman.d/mirrorlist;
pacman -Syy --needed --noconfirm parted git wget unzip;

########## Disk Setup ##########
parted /dev/sda -- mklabel gpt;
parted /dev/sda -- mkpart ESP fat32 1MB 512MB;
parted /dev/sda -- mkpart primary 512MB -20GB;
parted /dev/sda -- mkpart primary linux-swap -20GB 100%;
parted /dev/sda -- set 1 esp on;

mkfs.fat -F 32 -n boot /dev/sda1;
mkfs.ext4 -L root /dev/sda2;
mkswap -L swap /dev/sda3;

mount /dev/disk/by-label/root /mnt;
mkdir -p /mnt/boot;
mount /dev/disk/by-label/boot /mnt/boot;
swapon /dev/disk/by-label/swap;

lsblk;
read -p "Press enter to continue";

########## Base Install #########
pacstrap /mnt base base-devel linux linux-firmware;
genfstab -U /mnt >> /mnt/etc/fstab;

read -p "Press enter to continue";

########## Time Setup ##########
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime;
arch-chroot /mnt hwclock --systohc;

read -p "Press enter to continue";


######### Locale Setup #########
echo "LANG=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_ADDRESS=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_IDENTIFICATION=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_MEASUREMENT=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_MONETARY=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_NAME=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_NUMERIC=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_PAPER=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_TELEPHONE=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "LC_TIME=de_DE.UTF-8" >> /mnt/etc/locale.conf;

echo "KEYMAP=de" >> /mnt/etc/vconsole.conf;
echo "FONT=" >> /mnt/etc/vconsole.conf;
echo "FONT_MAP=" >> /mnt/etc/vconsole.conf;

echo "# Autoinstaller" >> /mnt/etc/locale.gen;
echo "de_DE.UTF-8 UTF-8" >> /mnt/etc/locale.gen;
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen;
arch-chroot /mnt locale-gen;

read -p "Press enter to continue";


########## Host Setup #########
echo "archlinux" > /mnt/etc/hostname;
echo "127.0.0.1    localhost" >> /mnt/etc/hosts;
echo "::1          localhost" >> /mnt/etc/hosts;
echo "127.0.1.1    archlinux.localdomain    archlinux" >> /mnt/etc/hosts;

read -p "Press enter to continue";


########## Bootloader Setup ##########
arch-chroot /mnt pacman -S grub-efi-x86_64 efibootmgr dosfstools os-prober mtools --needed --noconfirm;
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck;
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg;

read -p "Press enter to continue";


########## Services ##########
arch-chroot /mnt pacman -S --needed --noconfirm networkmanager dhcpcd acpid gnome-keyring;
arch-chroot /mnt systemctl enable NetworkManager;
arch-chroot /mnt systemctl enable dhcpcd;
arch-chroot /mnt systemctl enable acpid;
arch-chroot /mnt systemctl enable gnome-keyring;

read -p "Press enter to continue";


########## Sound ##########
arch-chroot /mnt pacman -S --needed --noconfirm pipewire

read -p "Press enter to continue";


########## Desktop ##########
arch-chroot /mnt pacman -S --needed --noconfirm xorg-drivers gdm gnome-shell gnome-terminal gnome-control-center gnome-tweak-tool gnome-software gnome-calendar xdg-user-dirs nautilus;
arch-chroot /mnt systemctl enable gdm;

read -p "Press enter to continue";


########## Fonts ###########
arch-chroot /mnt pacman -S --needed --noconfirm ttf-hack-nerd ttf-sourcecodepro-nerd ttf-terminus-nerd;

read -p "Press enter to continue";


########## Shell ##########
arch-chroot /mnt pacman -S --needed --noconfirm zsh starship;
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /mnt/usr/local/zsh-plugins/zsh-autosuggestions;
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /mnt/usr/local/zsh-plugins/zsh-syntax-highlighting;

mkdir -p /mnt/etc/skel/.config;
arch-chroot /mnt starship preset tokyo-night > /etc/skel/.config/starship.toml;

mkdir -p /mnt/etc/skel;
echo "HISTFILE=~/.zhistory" >> /mnt/etc/skel/.zshrc;
echo "HISTSIZE=1000" >> /mnt/etc/skel/.zshrc;
echo "SAVEHIST=1000" >> /mnt/etc/skel/.zshrc;
echo "export NVM_DIR=\"/usr/local/nvm\"" >> /mnt/etc/skel/.zshrc;
echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"" >> /mnt/etc/skel/.zshrc;
echo "[ -s \"$NVM_DIR/bash_completion\" ] && \. \"$NVM_DIR/bash_completion\"" >> /mnt/etc/skel/.zshrc;
echo "alias ls=\"ls --color=auto\"" >> /mnt/etc/skel/.zshrc;
echo "source /usr/local/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /mnt/etc/skel/.zshrc;
echo "source /usr/local/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> /mnt/etc/skel/.zshrc;
echo "eval \"$(starship init zsh)\"" >> /mnt/etc/skel/.zshrc;

read -p "Press enter to continue";


########## Tools ##########
arch-chroot /mnt pacman -S --needed --noconfirm php php-sqlite git wget neovim docker flatpak xdg-desktop-portal-gnome;

# PHP
sed -i s/\;extension=pdo_sqlite/extension=pdo_sqlite/ /mnt/etc/php/php.ini
sed -i s/\;extension=sqlite3/extension=sqlite3/ /mnt/etc/php/php.ini

# NVM
local NVM_DIR="/mnt/usr/local/nvm";
git clone https://github.com/nvm-sh/nvm.git ${NVM_DIR};
cd ${NVM_DIR};
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`;
\. ${NVM_DIR}/nvm.sh;
chmod 777 ${NVM_DIR};
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 18;

read -p "Press enter to continue";


########## User ##########
mkdir -p /mnt/etc/skel/{Bilder,Dev,Dokumente,Downloads,Musik,Videos}
arch-chroot /mnt pacman -S --needed --noconfirm sudo;
arch-chroot /mnt useradd -m -g users -G wheel,storage,disk,power,audio,video,docker -s /usr/bin/zsh mrs;
arch-chroot /mnt echo -e "1234\n1234" | passwd;
arch-chroot /mnt echo -e "1234\n1234" | passwd mrs;
echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/10-installer;

########## Finish ##########
# shutdown now;