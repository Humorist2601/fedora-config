#!/usr/bin/bash

#-------------------------------VARIABLE AND FUNCTION DECLARATION----------------------------------#

# Variables for color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Variable for correct user home directory.
USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)

# Function to print messages
print_message() {
    echo -e "${1}${2}${NC}"
}

# Function to check internet connectivity
check_internet() {
    if ping -c 1 1.1.1.1 &> /dev/null; then
        print_message "${GREEN}" "Internet is reachable. Proceeding with the installation."
    else
        print_message "${RED}" "Error: No internet connectivity. Exiting the script."
        exit 1
    fi
}

# Function to prompt user for confirmation
prompt_for_confirmation() {
    read -p "Do you want to proceed? (y/n): " -n 1 -r -e choice
    case "$choice" in 
        [Yy]* ) ;;
        [Nn]* ) print_message "${YELLOW}" "Aborted by user. Exiting the script."; exit 1;;
        * ) print_message "${RED}" "Invalid choice. Exiting the script."; exit 1;;
    esac
}

# Function to prompt for optional installations
prompt_for_optional_install() {
    local prompt_message=$1
    local action_function=$2
    read -p "$prompt_message (y/n): " -n 1 -r -e choice
    case "$choice" in 
        [Yy]* ) "$action_function" ;;
        [Nn]* ) print_message "${YELLOW}" "Cancelled by user. Not proceeding with $prompt_message...";;
        * ) print_message "${RED}" "Invalid choice. Not proceeding with $prompt_message...";;
    esac
}

# Function to install packages
install_packages() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        print_message "${GREEN}" "Installing $package..."
        if ! sudo dnf install -y "$package" &> /dev/null; then
            print_message "${RED}" "Failed to install $package"
        fi
    done
}

# Function to add COPR repositories
add_copr_repos() {
    local repos=("$@")
    for repo in "${repos[@]}"; do
        print_message "${GREEN}" "Adding COPR repository $repo..."
        if ! sudo dnf copr enable -y "$repo" &> /dev/null; then
            print_message "${RED}" "Failed to install $repo"
            exit 1
        fi
    done
}

# Function to install flatpaks
install_flatpak() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        print_message "${GREEN}" "Installing $package..."
        if ! flatpak install -y "$package" &> /dev/null; then
            print_message "${RED}" "Failed to install $package"
        fi
    done
}

# Function to install hyprland-dotfiles
install_dotfiles() {
    local repository=$1
    # Cloning the repository
    print_message "${YELLOW}" "Clonning $repository repository!"
    mkdir -p "$USER_HOME/GitHub/$repository"
    if ! git clone "https://github.com/Humorist2601/$repository" "$USER_HOME/GitHub/$repository" &> /dev/null; then
        print_message "${RED}" "Failed to clone $repository repository."
        return 1
    fi

    # Executing the install script
    print_message "${YELLOW}" "Running $repository setup script..."
    "$USER_HOME/GitHub/$repository/setup.sh"
}

#----------------------------------------START SCRIPT RUN------------------------------------------#

# Check internet connectivity
check_internet

# Prompt user for confirmation
prompt_for_confirmation

# Updating firmware
prompt_for_optional_install "Do you want to upgrade firmware?" upgrade_firmware
upgrade_firmware() {
    print_message "${GREEN}" "Upgrading Firmware..."
    fwupdmgr get-devices 
    fwupdmgr refresh --force 
    fwupdmgr get-updates 
    fwupdmgr update
}

# Fastest mirror setup
FILE="/etc/dnf/dnf.conf"
if [ -e $FILE ] && grep -q 'fastestmirror=True' $FILE; then
    print_message "${RED}" "Fastest mirror setup previously done."
else
    printf "fastestmirror=True" > $FILE
    printf "max_parallel_downloads=10 " >> $FILE
    printf "deltarpm=true" >> $FILE
    printf "defaultyes=True" >> $FILE
    printf "                     '''\e[0m \n" >> $FILE
    print_message "${GREEN}" "Fastest mirror setup done."
fi

# Updating repositories list
print_message "${GREEN}" "Updating repositories..."
if ! sudo dnf check-update &> /dev/null; then
    print_message "${RED}" "Failed to update the repositories."
    exit 1
fi

# Installing necessary packages
print_message "${GREEN}" "Installing necessary packages..."
install_packages "@'Common NetworkManager Submodules'" "@'Development Tools'" "@'Hardware Support'"

# Installing Fedora RPM Fusion
install_packages "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" "groupupdate" "core"
sudo dnf -y update
sudo dnf -y upgrade --refresh

# Installing codecs
print_message "${GREEN}" "Installing codecs..."
sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing
sudo dnf -y update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf -y update @sound-and-video

# Adding COPR packages
print_message "${GREEN}" "Adding COPR repositories..."
add_copr_repos "atim/starship" "nucleo/gocryptfs" "solopasha/hyprland" "zeno/scrcpy"

# Installing Hyprland necessary packages
print_message "${GREEN}" "Installing Hyprland packages..."
install_packages "hyprland" "hyprlock" "hypridle" "waybar-git" "polkit-gnome" "swww" "kitty" "mako" "xdg-user-dirs" "curl" "wget" "tar"

# Creating User Common directories
xdg-user-dirs-update

# Installing other necessary packages
print_message "${GREEN}" "Installing other necessary packages..."
install_packages "pamixer" "gammastep" "starship" "brightnessctl" "lightdm" "bluez" "blueman" "cups" "rofi-wayland" "fastfetch" "nautilus" "file-roller"

# Autologin using LightDM
prompt_for_optional_install "Do you want to enable autologin?" enable_autologin
enable_autologin() {
    print_message "${GREEN}" "Configuring autologin with Lightdm..."
    sudo cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak
    sudo sed -i "/^\[Seat:\*]/a autologin-user=$(whoami)" "/etc/lightdm/lightdm.conf"
    sudo sed -i "/^\[Seat:\*]/a autologin-user-timeout=0" "/etc/lightdm/lightdm.conf"
    sudo sed -i "/^\[Seat:\*]/a autologin-session=hyprland" "/etc/lightdm/lightdm.conf"
    sudo systemctl enable lightdm &> /dev/null
    sudo systemctl set-default graphical.target &> /dev/null
}

# Installing Auto-cpureq
prompt_for_optional_install "Do you want to install Auto-cpufreq (For Laptops)?" install_auto_cpufreq
install_auto_cpufreq() {
    print_message "${GREEN}" "Installing Auto-cpufreq..."
    if ! git clone https://github.com/AdnanHodzic/auto-cpufreq.git "/tmp/auto-cpufreq" &> /dev/null; then
        print_message "${RED}" "Failed to clone auto-cpufreq repository."
        return 1
    fi
    sudo /tmp/auto-cpufreq/auto-cpufreq-installer 
    sudo auto-cpufreq --install
}

# Installing virtualization
prompt_for_optional_install "Do you want to install virtualization?" install_virtualization
install_virtualization() {
    print_message "${GREEN}" "Enabling virtualization..."
    if ! sudo dnf install @virtualization -y &> /dev/null; then
        print_message "${RED}" "Failed to install virtualization packages."
        return 1
    fi
    sudo cp /etc/libvirt/libvirtd.conf /etc/libvirt/libvirtd.conf.bak
    sudo sed -i '/^# unix_sock_group/s/.*/unix_sock_group = "libvirt"/' "/etc/libvirt/libvirtd.conf"
    sudo sed -i '/^# unix_sock_rw_perms/s/.*/unix_sock_rw_perms = "0770"/' "/etc/libvirtd/libvirtd.conf"
    sudo usermod -a -G libvirt "$(whoami)"
    sudo systemctl enable libvirtd &> /dev/null
}

print_message "${GREEN}" "Minimal Hyprland installed..."

prompt_for_confirmation "Do you want to proceed with optional installations?"

# Installing CLI Packages
print_message "${GREEN}" "Installing CLI packages..."
install_packages "btop" "neovim" "zoxide" "cmatrix" "tldr" "tree" "trash-cli" "powertop" "python3-pip" "pipx" "dbus-glib" "papirus-icon-theme" "wireguard-tools" "libwebp-devel" "jq" "adw-gtk3-theme" "fish" "fzf"

# Installing GUI packages

print_message "${GREEN}" "Installing GUI packages..."
install_packages "easyeffects" "calibre" "cool-retro-term" "baobab" "gnome-disk-utility" "gparted" "firefox" "mousepad" "kde-connect" "pavucontrol" "qalculate-gtk" "inkscape" "ristretto" "gimp" "gimp-resynthesizer" "gimp-lensfun" "rawtherapee" "vlc" "rpi-imager" "simple-scan" "wireshark" "7z" "android-tools" "aria2" "curl" "qbittorrent" "gnome-calendar" "gnome-clocks" "gnome-calculator" "loupe" "sushi" "gocryptfs" "mpv" "python3-nautilus" "scrcpy" "syncthing" "tlp" "unrar" "unzip" "wl-clipboard" "snapshot"

# Installing Flatpak packages
print_message "${GREEN}" "Installing Flatpak packages..."
install_packages "flatpak"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
install_flatpak "flathub" "org.gtk.Gtk3theme.adw-gtk3" "flathub org.gtk.Gtk3theme.adw-gtk3-dark" "org.gnome.gitlab.somas.Apostrophe" "com.usebottles.bottles" "dev.geopjr.Collision" "com.github.tchx84.Flatseal" "com.github.neithern.g4music" "it.mijorus.gearlever" "fr.handbrake.ghb" "io.github.Hexchat" "keepassxc" "org.bunkus.mkvtoolnix-gui" "io.github.amit9838.mousam" "org.nicotine_plus.Nicotine" "com.github.jeromerobert.pdfarranger" "com.spotify.Client" "io.github.mpobaschnig.Vaults" "com.vscodium.codium" "io.github.flattool.Warehouse"

# Installing Easyeffects Presets
print_message "${GREEN}" "Installing easyeffects presets..."
mkdir -p ~/.config/easyeffects/output
bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/PulseEffects-Presets/master/install.sh)"

# Adding the Dotfiles
prompt_for_optional_install "Do you want to add my Dotfiles?" add_dotfiles
add_dotfiles() {
    install_dotfiles "hyprland-dotfiles"
}

# Install Fonts
install_latest_release "ryanoasis/nerd-fonts" "JetBrainsMono.zip"
mkdir -p ~/.local/share/fonts/JetBrainsMono/
unzip -o "/tmp/latest-JetBrainsMono.zip" -d ~/.local/share/fonts/JetBrainsMono/ &> /dev/null
fc-cache -fv &> /dev/null

# Install Bibata Cursor theme
install_latest_release "ful1e5/Bibata_Cursor" "Bibata-Modern-Classic.tar.xz"
sudo mkdir -p /usr/share/icons/Bibata-Modern-Classic/
sudo tar -xf "/tmp/latest-Bibata-Modern-Classic.tar.xz" -C /usr/share/icons/
sudo sed -i "s/Inherits=.*/Inherits=Bibata-Modern-Classic/" "/usr/share/icons/default/index.theme"

# Change Plymouth
install_packages "plymouth-theme-spinner"
sudo plymouth-set-default-theme spinner -R &> /dev/null

# Grub theme
install_latest_release "Jacksaur/CRT-Amber-GRUB-Theme" "CRT-Amber-Theme.zip"
sudo mkdir -p /boot/grub2/theme/CRT-Amber-Theme
sudo unzip -o "/tmp/latest-CRT-Amber-Theme.zip" -d /boot/grub2/theme/CRT-Amber-Theme &> /dev/null
sudo sed -i -e 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/' \
            -e 's/^GRUB_TERMINAL_OUTPUT=/#GRUB_TERMINAL_OUTPUT=/' \
            -e '$ a GRUB_THEME="/boot/grub2/theme/CRT-Amber-Theme/CRT-Amber-GRUB-Theme/theme.txt"' \
            /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg &> /dev/null

# Restart the system
prompt_for_restart

# END SCRIPT RUN

# START USEFUL CODE

# Function to install from github latest release
#install_latest_release() {
#    local REPO=$1
#    local ASSET_PATTERN=$2
#
#    print_message "${GREEN}" "Fetching the latest release data from GitHub for $REPO..."
#    local LATEST_RELEASE
#    LATEST_RELEASE=$(curl -s https://api.github.com/repos/"$REPO"/releases/latest)
#
#    # Extract the download URL for the desired asset
#    local DOWNLOAD_URL
#    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | jq -r ".assets[] | select(.name | endswith(\"$ASSET_PATTERN\")) | .browser_download_url")
#
#    # Check if the download URL was found
#    if [[ -z "$DOWNLOAD_URL" ]]; then
#        print_message "${RED}" "Error: No asset found with the pattern matching '$ASSET_PATTERN'."
#        return 1
#    fi
#
#    # Download the file to /tmp directory
#    local FILE_PATH="/tmp/latest-$ASSET_PATTERN"
#    print_message "${GREEN}" "Downloading the latest release - $REPO"
#    wget -q "$DOWNLOAD_URL" -O "$FILE_PATH"
#
#    # Install the package if INSTALL is true and the file is an RPM
#    if [[ "$ASSET_PATTERN" == *.rpm ]]; then
#        if sudo dnf install "$FILE_PATH" -y &> /dev/null; then
#            print_message "${GREEN}" "Installation complete."
#        else
#            print_message "${RED}" "Installation failed."
#            return 1
#        fi
#    else
#        print_message "${YELLOW}" "Downloaded to $FILE_PATH"
#    fi
#}

#print_message "${GREEN}" "Adding repositories..."
#if ! sudo dnf config-manager --add-repo https://repository.mullvad.net/rpm/stable/mullvad.repo -y &> /dev/null; then
#    print_message "${RED}" "Failed to add Mullvad repository."
#fi

# Installing from GitHub
#print_message "${GREEN}" "Installing packages from GitHub..."
#
# Install thorium
#install_latest_release "Alex313031/thorium" "AVX2.rpm"

# AppImages
#print_message "${GREEN}" "Installing AppImages..."
#mkdir -p ~/Applications
#
# Install AppImageLauncher
#install_latest_release "TheAssassin/AppImageLauncher" "x86_64.rpm"

# END USEFUL CODE
