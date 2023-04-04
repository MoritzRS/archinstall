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
mkdir -p /mnt/{boot,home};
mkdir -p /mnt/boot/efi;
mount /dev/disk/by-label/boot /mnt/boot/efi;
swapon /dev/disk/by-label/swap;


########## Base Install #########
pacstrap /mnt base base-devel linux linux-firmware;
genfstab -U /mnt >> /mnt/etc/fstab;


########## Time Setup ##########
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime;
arch-chroot /mnt hwclock --systohc;


######### Locale Setup #########
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen;
echo "de_DE.UTF-8 UTF-8" >> /mnt/etc/locale.gen;
arch-chroot /mnt locale-gen;

echo "LANG=de_DE.UTF-8" >> /mnt/etc/locale.conf;
echo "KEYMAP=de-latin1" >> /mnt/etc/vconsole.conf;


########## Host Setup #########
echo "archlinux" > /mnt/etc/hostname;
echo "127.0.0.1    localhost" >> /mnt/etc/hosts;
echo "::1          localhost" >> /mnt/etc/hosts;
echo "127.0.1.1    archlinux.localdomain    archlinux" >> /mnt/etc/hosts;


########## Bootloader Setup ##########
arch-chroot /mnt pacman -S grub-efi-x86_64 efibootmgr dosfstools os-prober mtools --needed --noconfirm;
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck;
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg;


########## Services ##########
arch-chroot /mnt pacman -S --needed --noconfirm networkmanager dhcpcd acpid gnome-keyring;
arch-chroot /mnt systemctl enable NetworkManager;
arch-chroot /mnt systemctl enable dhcpcd;
arch-chroot /mnt systemctl enable acpid;
arch-chroot /mnt systemctl enable fstrim.timer;


########## Sound ##########
arch-chroot /mnt pacman -S --needed --noconfirm pipewire


########## Desktop ##########
arch-chroot /mnt pacman -S --needed --noconfirm xorg-drivers gdm gnome-shell gnome-backgrounds gnome-console gnome-system-monitor gnome-control-center gnome-tweak-tool gnome-software gnome-calendar xdg-user-dirs nautilus;
arch-chroot /mnt systemctl enable gdm;


########## Fonts ###########
arch-chroot /mnt pacman -S --needed --noconfirm ttf-hack-nerd ttf-sourcecodepro-nerd ttf-terminus-nerd;


########## Tools ##########
arch-chroot /mnt pacman -S --needed --noconfirm php php-sqlite git wget neovim docker flatpak xdg-desktop-portal-gnome;

# Docker
arch-chroot /mnt systemctl enable docker;

# PHP
sed -i s/\;extension=pdo_sqlite/extension=pdo_sqlite/ /mnt/etc/php/php.ini
sed -i s/\;extension=sqlite3/extension=sqlite3/ /mnt/etc/php/php.ini

# NVM
NVM_DIR="/mnt/usr/local/nvm";
git clone https://github.com/nvm-sh/nvm.git ${NVM_DIR};
cd ${NVM_DIR};
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`;
\. ${NVM_DIR}/nvm.sh;
chmod 777 ${NVM_DIR};
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 18;


########## Shell ##########
arch-chroot /mnt pacman -S --needed --noconfirm zsh starship;
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions /mnt/usr/local/zsh-plugins/zsh-autosuggestions;
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /mnt/usr/local/zsh-plugins/zsh-syntax-highlighting;

mkdir -p /mnt/etc/skel/.config;
arch-chroot /mnt bash <<SHELL
starship preset pastel-powerline > /etc/skel/.config/starship.toml;
SHELL

mkdir -p /mnt/etc/skel;
echo "HISTFILE=~/.zhistory" >> /mnt/etc/skel/.zshrc;
echo "HISTSIZE=1000" >> /mnt/etc/skel/.zshrc;
echo "SAVEHIST=1000" >> /mnt/etc/skel/.zshrc;
echo "export NVM_DIR=\"/usr/local/nvm\"" >> /mnt/etc/skel/.zshrc;
echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"" >> /mnt/etc/skel/.zshrc;
echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"" >> /mnt/etc/skel/.zshrc;
echo "alias ls=\"ls --color=auto\"" >> /mnt/etc/skel/.zshrc;
echo "source /usr/local/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /mnt/etc/skel/.zshrc;
echo "source /usr/local/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> /mnt/etc/skel/.zshrc;
echo "eval \"\$(starship init zsh)\"" >> /mnt/etc/skel/.zshrc;


########## User ##########
mkdir -p /mnt/etc/skel/{Bilder,Dev,Dokumente,Downloads,Musik,Videos}
arch-chroot /mnt bash <<SHELL
pacman -S --needed --noconfirm sudo;
useradd -m -g users -G wheel,storage,disk,power,audio,video,docker -s /usr/bin/zsh mrs;
usermod -c "MoritzRS" mrs;
echo -e "1234\n1234" | passwd;
echo -e "1234\n1234" | passwd mrs;
SHELL
echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/10-installer;

########## Finish ##########
shutdown now;