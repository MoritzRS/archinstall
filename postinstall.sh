#!/bin/bash

########## Change Password ##########
passwd;


########## Setup git ##########
git config --global user.name MoritzRS;
git config --global user.email moritz.r.schulz@gmail.com;
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret;


########## Setup Gnome ##########
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'";
dconf write /org/gnome/desktop/interface/enable-hot-corners false;
dconf write /org/gnome/desktop/interface/show-battery-percentage true;

dconf write /org/gnome/desktop/input-sources/sources "[('xkb', 'de')]";

dconf write /org/gnome/desktop/session/idle-delay "uint32 0";
dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type "'nothing'";
dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-battery-type "'nothing'";

# dconf write /org/gnome/desktop/interface/font-name "'JetBrainsMono Nerd Font 11'";
# dconf write /org/gnome/desktop/interface/monospace-font-name "'JetBrainsMono Nerd Font Mono 10'";
# dconf write /org/gnome/desktop/interface/document-font-name "'JetBrainsMono Nerd Font 11'";

dconf write /org/gnome/desktop/background/picture-uri "'file:///usr/share/backgrounds/gnome/blobs-l.svg'";
dconf write /org/gnome/desktop/background/picture-uri-dark "'file:///usr/share/backgrounds/gnome/blobs-d.svg'";
dconf write /org/gnome/desktop/screensaver/picture-uri "'file:///usr/share/backgrounds/gnome/blobs-d.svg'";

dconf write /org/gnome/shell/favorite-apps "['com.google.Chrome.desktop', 'firefox.desktop', 'org.gnome.Epiphany.desktop', 'org.gnome.Console.desktop', 'code-oss.desktop', 'org.gnome.Nautilus.desktop', 'obsidian.desktop', 'org.remmina.Remmina.desktop', 'org.gnome.Software.desktop', 'gnome-system-monitor.desktop']";

########## Update System ##########
sudo pacman -Syyu;


########## Install Grub Theme ##########
git clone --depth=1 https://github.com/vinceliuice/grub2-themes grub-themes;
cd grub-themes;
sudo ./install.sh -t tela -s 1080p;
cd ..;
rm -rf grub-themes;


########## Ensure proper Graphics Drivers ##########
sudo pacman -S --needed --noconfirm \
    vulkan-icd-loader \
    vulkan-radeon \
    mesa;

########## Install Native Packages ##########
sudo pacman -S --needed --noconfirm \
    blender \
    code \
    epiphany \
    firefox \
    godot \
    obsidian \
    remmina \
    sqlitebrowser;


########## Install Flatpaks ##########
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo;
flatpak install -y flathub com.google.Chrome;
flatpak install -y flathub org.gnome.gitlab.somas.Apostrophe;
flatpak install -y flathub rest.insomnia.Insomnia;
