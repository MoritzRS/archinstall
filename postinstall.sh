sudo pacman -Syyu
sudo pacman -S neovim wget git php sqlitebrowser firefox godot blender

flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.google.Chrome
flatpak install -y flathub org.gnome.gitlab.somas.Apostrophe
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub rest.insomnia.Insomnia
flatpak install -y flathub com.visualstudio.code-oss
flatpak install -y flathub org.remmina.Remmina