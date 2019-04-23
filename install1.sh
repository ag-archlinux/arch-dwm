#!/bin/bash
#####     Created by: ag
#####     File: install1.sh
#####     --------------------------------------------------
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
	##### b) Chroot
        arch-chroot /mnt /bin/bash <<EOF
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
				  # configure network manager
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
				grub-install --recheck --target=i386-pc $DRIVE
				grub-mkconfig -o /boot/grub/grub.cfg
			##### Exit chroot
				exit
EOF
    ##### c) Unmount all the partitions
    	umount -R /mnt
    ##### e) Restart the machine
        rm install1.sh
    	reboot
#####     --------------------------------------------------