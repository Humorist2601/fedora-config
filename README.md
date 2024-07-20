# fedora-config

Automate the setup of your [Minimal Fedora](https://fedoraproject.org/) and [Hyprland](https://hyprland.org/) with this script. Personalize, install essential packages, apply themes, and integrate Dotfiles effortlessly.

## Features

- Hyprland - a Tiling compositor with the looks
- Dotfiles integration (optional)

This is the way I install in my system.

**Note:** This scripts contains a lot of application that you might not need... Those are the apps that I usually use, so feel free to change the script to your needs.

## Usage

Do this after having a minimal install of Fedora.

### Before Script (Installing GIT)
1. `sudo dnf update -y`
2. `sudo dnf install git -y`

### With Script (Main Configuration)
1. Clone this repository: `git clone https://github.com/Humorist2601/fedora-config`
2. Enter the folder: `cd fedora-config`
2. Run the script: `./install.sh`
3. Follow on-screen prompts.

### After Script (Installing NVIDIA Drivers)
1. `sudo dnf install kmodtool akmods mokutil openssl -y`
2. `sudo kmodgenca -a`
3. `sudo mokutil --import /etc/pki/akmods/certs/public_key.der` 
4. Enter a password, you need to remember it for step 6
5. `sudo reboot`
6. 	- First select `Enroll MOK`.
	- Then `Continue`.
	- Hit `Yes` and enter the password from step 4.
 	- Then select `OK` and your device will reboot again.
7. Again enter the folder: `cd fedora-config`
8. Run the script: `./nvidia.sh`
9. Follow on-screen prompts.

**Note:** Ensure you have an active internet connection before running the script.

## Contributions

Contributions are welcome! Fork the repository, make improvements, and submit a pull request.

## Acknowledgements

- Thanks to [M0streng0](https://github.com/M0streng0/) for the initial [script](https://github.com/M0streng0/Fedora-M0streng0)
 
## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.