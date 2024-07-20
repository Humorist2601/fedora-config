#!/usr/bin/bash

# START VARIABLE AND FUNCTION DECLARATION

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to install nvidia drivers
nvidia() {
    if lspci | grep -i "nvidia" &> /dev/null; then
        print_message "${GREEN}" "NVIDIA GPU detected. Installing NVIDIA drivers..."
        install_packages "akmod-nvidia" "xorg-x11-drv-nvidia-cuda" "nvidia-vaapi-driver" "libva-utils" "vdpauinfo" "vulkan" "kmodtool" "akmods" "mokutil" "openssl"
    else
        print_message "${YELLOW}" "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
    fi
}

# Function to prompt for restarting the system
prompt_for_restart() {
    print_message "${GREEN}" "Installation completed successfully."
    print_message "${GREEN}" "You should now reboot."
    read -p "Do you want to proceed? (y/n): " -n 1 -r -e choice
    case "${choice:-Y}" in 
        [Yy]* ) print_message "${GREEN}" "Rebooting..." ; sleep 1 ; shutdown -r now ;;
        [Nn]* ) print_message "${YELLOW}" "Aborted by user. Exiting the script."; exit 1;;
        * ) print_message "${RED}" "Invalid choice. Exiting the script."; exit 1;;
    esac
}

# END VARIABLE AND FUNCTION DECLARATION

# START SCRIPT RUN

# Detect and install NVIDIA drivers
nvidia

# Restart the system
prompt_for_restart

# END SCRIPT RUN
