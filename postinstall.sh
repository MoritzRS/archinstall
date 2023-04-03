sudo pacman -Syyu
sudo pacman -S sqlitebrowser firefox epiphany godot blender

flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --user flathub com.google.Chrome
flatpak install -y --user flathub org.gnome.gitlab.somas.Apostrophe
flatpak install -y --user flathub md.obsidian.Obsidian
flatpak install -y --user flathub rest.insomnia.Insomnia
flatpak install -y --user flathub com.visualstudio.code-oss
flatpak install -y --user flathub org.remmina.Remmina