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
parted /dev/nvme0n1 -- mklabel gpt;
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB;
parted /dev/nvme0n1 -- mkpart primary 512MB -20GB;
parted /dev/nvme0n1 -- mkpart primary linux-swap -20GB 100%;
parted /dev/nvme0n1 -- set 1 esp on;

mkfs.fat -F 32 -n boot /dev/nvme0n1p1;
mkfs.ext4 -L root /dev/nvme0n1p2;
mkswap -L swap /dev/nvme0n1p3;

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
cat <<EOF > /mnt/etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    archlinux.localdomain    archlinux
EOF


########## Bootloader Setup ##########
arch-chroot /mnt pacman -S grub-efi-x86_64 efibootmgr dosfstools os-prober mtools --needed --noconfirm;
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck;
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg;


########## Services ##########
arch-chroot /mnt pacman -S --needed --noconfirm networkmanager dhcpcd acpid gnome-keyring libsecret;
arch-chroot /mnt systemctl enable NetworkManager;
arch-chroot /mnt systemctl enable dhcpcd;
arch-chroot /mnt systemctl enable acpid;
arch-chroot /mnt systemctl enable fstrim.timer;
echo "password	optional	pam_gnome_keyring.so" >> /mnt/etc/pam.d/passwd

########## Sound ##########
arch-chroot /mnt pacman -S --needed --noconfirm pipewire


########## Desktop ##########
arch-chroot /mnt pacman -S --needed --noconfirm \
    xorg-drivers \
    gdm gnome-shell \
    gnome-backgrounds \
    gnome-calculator \
    gnome-calendar \
    gnome-console \
    gnome-control-center \
    gnome-disk-utility \
    gnome-software \
    gnome-software-packagekit-plugin \
    gnome-system-monitor \
    gnome-text-editor \
    gnome-tweak-tool \
    gnome-user-share \
    gvfs \
    gvfs-goa \
    gvfs-google \
    gvfs-gphoto2 \
    gvfs-mtp \
    gvfs-nfs \
    gvfs-smb \
    evince \
    gthumb \
    seahorse \
    sushi \
    totem \
    xdg-user-dirs-gtk \
    nautilus \
    flatpak \
    xdg-desktop-portal-gnome;
arch-chroot /mnt systemctl enable gdm;


########## Touchpad ##########
cat <<EOF > /mnt/etc/X11/xorg.conf.d/30-touchpad.conf
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
EndSection
EOF


########## Fonts ###########
arch-chroot /mnt pacman -S --needed --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-hack-nerd \
    ttf-sourcecodepro-nerd \
    ttf-terminus-nerd;


########## User ##########
mkdir -p /mnt/etc/skel/{Bilder,Dev,Dokumente,Downloads,Musik,Videos}
arch-chroot /mnt bash <<SHELL
pacman -S --needed --noconfirm sudo;
useradd -m -g users -G wheel,storage,disk,power,audio,video mrs;
usermod -c "MoritzRS" mrs;
echo -e "1234\n1234" | passwd;
echo -e "1234\n1234" | passwd mrs;
SHELL
echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/10-installer;

########## Finish ##########
shutdown now;