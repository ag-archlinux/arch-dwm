#!/bin/bash
#####     Created by: ag
#####     --------------------------------------------------
if [ ! "$(ls -A "/home")" ]; then
#####  INPUTS                                  #####
	##### hostname
	echo -n "Hostname: "
	read HOSTNAME
	: "${HOSTNAME:?"Missing hostname"}"
	##### root password
	echo -n "Root password: "
	read -s ROOT_PASSWORD
	echo
	echo -n "Repeat root password: "
	read -s ROOT_PASSWORD_REPEAT
	echo
	[[ "$ROOT_PASSWORD" == "$ROOT_PASSWORD_REPEAT" ]] || ( echo "Root passwords did not match"; exit 1; )
	##### username
	echo -n "Username: "
	read USERNAME
	: "${USERNAME:?"Missing username"}"
	##### user password
	echo -n "User password: "
	read -s USER_PASSWORD
	echo
	echo -n "Repeat user password: "
	read -s USER_PASSWORD_REPEAT
	echo
	[[ "$USER_PASSWORD" == "$USER_PASSWORD_REPEAT" ]] || ( echo "User passwords did not match"; exit 1; )
	##### root space
	read -p "What is your ROOT_SPACE (G)? " ROOT_SPACE
	##### timezone
	TIMEZONE="Europe/Bratislava"
	##### locale
	LOCALE="en_US.UTF-8"
	##### drive
	DRIVE="/dev/sda"
#####     --------------------------------------------------
#####     1. Pre-Installation
    ##### a) Set the keyboard layout
        loadkeys us
    ##### b) Verify the boot mode
        if [-d "/sys/firmware/efi/efivars"]; then
            echo "UEFI"
            BOOT="UEFI"
        else
            echo "BIOS"
            BOOT="BIOS"
        fi
    ##### c) Connect to the Internet
    	ping -q -w1 -c1 google.com &>/dev/null && CONN="CONNECTED" || (CONN="NOT_CONNECTED";)
        while [ "$CONN" != "CONNECTED" ]; do
            echo -e "\033[0;36m'You are not connected to the internet!'\033[0;0m"
            ip link
            read -p "What is name of your wifi? (number:name: ...) : " WIFI
            wifi-menu -o $WIFI
            ping -q -w1 -c1 duckduckgo.com &>/dev/null && CONN="CONNECTED" || CONN="NOT_CONNECTED"
        done
        echo "You are connected to the internet!"
    ##### d) Update the system clock
        timedatectl set-ntp true
    ##### e) Partition the disks
          # swap
    	SWAP=$(free --mebi | awk '/Mem:/ {print $2}')
 		SWAP_SPACE=$(( $SWAP + 130 ))MiB
    	if [ "$BOOT" = "BIOS" ]; then
  			echo "BIOS"
#   Prepare the disk
         	fdisk -l
			cat<<EOF | fdisk /dev/sda
				n
				p
				1

				+${ROOT_SPACE}G
				n
				p
				2

				+${SWAP_SPACE}
				t
				2
				82
				n
				p
				3


				w
EOF
		else
			echo "UEFI"
			fdisk -l
#   Prepare the disk
			cat<<EOF | fdisk /dev/sda
				n
				p
				1

				+500M
				t
				ef
				n
				p
				2

				+${SWAP_SPACE}
				t
				2
				82
				n
				p
				3

				+${ROOT_SPACE}G
				n
				p
				4


				w
EOF
		fi
    ##### f) Format the partitions & Mount the file systems
        if [ "$BOOT" = "BIOS" ]; then
 			mkfs.ext4 /dev/sda1
			mount /dev/sda1 /mnt
			mkswap /dev/sda2
			swapon /dev/sda2
			mkfs.ext4 /dev/sda3
			mkdir -p /mnt/home
			mount /dev/sda3 /mnt/home
		else
			yes | eval mkfs.fat -F32 /dev/sda1 
			mkfs.ext4 /dev/sda3
			mkfs.ext4 /dev/sda4
			mkswap /dev/sda2
			swapon /dev/sda2
			mount /dev/sda3 /mnt
			mkdir -p /mnt/boot
			mount /dev/sda1 /mnt/boot
			mkdir -p /mnt/home
			mount /dev/sda4 /mnt/home
		fi
#####     --------------------------------------------------
#####     2. Installation
	##### a) Select the mirrors
	    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
		curl -s "https://www.archlinux.org/mirrorlist/?country=SK&country=CZ&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist
	##### b) Install the base packages
		pacstrap /mnt base base-devel
#####     3. Configure the system
	##### a) Fstab
	    cat /mnt/etc/fstab
        genfstab /mnt >> /mnt/etc/fstab
    ##### b) Prepare for post-installation
        cp /etc/skel/.bash_profile /etc/skel/.bash_profile.backup 
        touch /etc/skel/script.sh
    	curl -LO https://raw.githubusercontent.com/ag-archlinux/arch-dwm/master/install.sh 
    	cp install.sh /etc/skel/script.sh
    	echo "bash /etc/skel/script.sh" >> /etc/skel/.bash_profile
	##### c) Chroot
        cat<<EOF | arch-chroot /mnt
	    	##### 1) Time zone
    			ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    			hwclock-systohc
    		##### 2) Locale
    			sed -i "s|#\($LOCALE.*\)\$|\1|" /etc/locale.gen
                locale-gen
                echo "LANG=$LOCALE" >> /etc/locale.conf
	    	##### 3) Hostname
    			echo $HOSTNAME >> /etc/hostname
				echo "127.0.0.1  localhost" >> /etc/hosts
				echo "::1        localhost" >> /etc/hosts
				echo "127.0.0.1  " + $HOSTNAME+ ".localdomain "+ $HOSTNAME >> /etc/hosts
    		##### 4) Network configuration
				##### a) create personal account & password of personal account
    				useradd -k /etc/skel -m -g users -G audio,video,network,wheel,storage -s /bin/bash $USERNAME
    				echo "$USERNAME:$USER_PASSWORD" | /usr/sbin/chpasswd
    			##### b) account sudo permitions
					sed -i "/#MY_PERMISSION/d" /etc/sudoers
					echo -e "%wheel ALL=(ALL) NOPASSWD: ALL #MY_PERMISSION" >> /etc/sudoers    		
				##### c) configure network manager
    				pacman --noconfirm --needed -S networkmanager
					systemctl enable NetworkManager
					systemctl start NetworkManager
				  	#pacman --noconfirm --needed -S iw wpa_supplicant dialog wpa-actiond
				  	#systemctl enable dhcpcd
    		##### 5) Initramfs
    			mkinitcpio -p linux
    		##### 6) Root password
    			echo "root:$ROOT_PASSWORD" | /usr/sbin/chpasswd
    		##### 7) Boot loader
    			pacman --noconfirm --needed -S grub os-prober
				grub-install --recheck --target=i386-pc "$DRIVE"
				grub-mkconfig -o /boot/grub/grub.cfg
			##### Exit chroot
				exit
EOF
    ##### d) Unmount all the partitions
    	umount -R /mnt
    ##### e) Restart the machine
        rm new.sh
    	reboot
#####     --------------------------------------------------
else 
#####     3. Post-Installation - Configuration
	##### a) login as user

	##### b) update & xorg & installation of another programs
		sudo pacman --noconfirm --needed -Syu
		sudo pacman --noconfirm --needed -S xorg-server xorg-xinit xorg-xsetroot gcc make pkg-config bash-completion libx11 libxft libxinerama ttf-ubuntu-font-family
		sudo pacman --noconfirm --needed -S filezilla gimp inkscape firefox neovim rxvt-unicode zip unrar unzip ranger htop
		sudo pacman --noconfirm --needed -S scrot w3m lynx atool highlight xclip mupdf mplayer transmission-cli openssh
		sudo pacman --noconfirm --needed -S ncmpcpp pulseaudio-alsa pulsemixer	wget zathura conky 
		sudo pacman --noconfirm --needed -S nitrogen compton youtube-dl sxiv entr
		sudo pacman --noconfirm --needed -S gimp kodi qrencode netcat feh mediainfo
		sudo pacman --noconfirm --needed -S termbin noto-fonts neomutt urlview
	##### c) graphics driver & dislpay manager	
		#lspci | grep -e VGA -e 3D
		#sudo pacman -S lightdm
		#sudo pacman -S lightdm-gtk-greeter lightdm-gtk-greeter-settings
     	#sudo systemctl enable lightdm.service
    ##### d) git & packages
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
	##### e) copy my config files
		cp ~/arch-dwm/home/.xinitrc ~/.xinitrc
	##### f) startx
	    sudo cp /etc/skel/.bash_profile.backup /etc/skel/.bash_profile
	    sudo rm -rf /etc/skel/.bash_profile.backup
	    sudo rm -rf /etc/skel/script.sh

		startx
		pkill x
		startx 
fi 