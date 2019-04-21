#!/bin/bash
#####     Created by: ag
#####     --------------------------------------------------
#####     1. Configuration
	##### a) xorg
		sudo pacman --noconfirm --needed -Syu
		sudo pacman --noconfirm --needed -S xorg-server xorg-xinit xorg-xsetroot bash-completion gcc make pkg-config libx11 libxft libxinerama ttf-ubuntu-font-family
		sudo pacman --noconfirm --needed -S filezilla gimp inkscape firefox neovim rxvt-unicode zip unrar unzip ranger htop
		sudo pacman --noconfirm --needed -S scrot w3m lynx atool highlight xclip mupdf mplayer transmission-cli openssh
		sudo pacman --noconfirm --needed -S ncmpcpp pulseaudio-alsa pulsemixer	wget zathura conky 
		sudo pacman --noconfirm --needed -S nitrogen compton youtube-dl sxiv entr
		sudo pacman --noconfirm --needed -S gimp kodi qrencode netcat feh mediainfo
		sudo pacman --noconfirm --needed -S termbin noto-fonts neomutt urlview
	##### b) graphics driver & dislpay manager	
		#lspci | grep -e VGA -e 3D
		#sudo pacman -S lightdm
		#sudo pacman -S lightdm-gtk-greeter lightdm-gtk-greeter-settings
     	#sudo systemctl enable lightdm.service
    ##### b) git
    	cd
		sudo pacman --noconfirm --needed -S git
		git clone https://github.com/ag-archlinux/arch-dwm
		sudo rm -rf conf.sh 

		git clone https://git.suckless.org/dwm
		git clone https://git.suckless.org/dmenu
		git clone https://git.suckless.org/st
		git clone https://git.suckless.org/surf
		
		cd ~/dwm/   && make clean install
		cd ~/dmenu/ && make clean install
		cd ~/st/   && make clean install
		cd ~/surf/ && make clean install
	##### c) copy my config files
		cp ~/arch-dwm/home/.xinitrc ~/.xinitrc
	##### d) startx
	    sudo cp /etc/skel/.bash_profile.backup /etc/skel/.bash_profile
	    sudo rm -rf /etc/skel/.bash_profile.backup
	    sudo rm -rf /etc/skel/script.sh

		startx
		pkill x
		startx
