#!/bin/bash
#####     Created by: ag
#####     --------------------------------------------------
#####  INPUTS                                  #####
	read -p "What is your RAM (G)? " RAM_IN
	RAM=$(bc <<< "$RAM_IN * 1.5")
	read -p "What is your ROOT_SPACE (G)? " ROOT_SPACE
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
        timedatectl status
        timedatectl set-ntp true
		timedatectl status 
    ##### e) Partition the disks
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

+${RAM}G
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

+${RAM}G
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
	    lsblk
        read -p "Press any key..."
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
		curl https://raw.githubusercontent.com/ag-archlinux/dwm/master/new/chroot.sh > /mnt/chroot.sh
	    arch-chroot /mnt bash chroot.sh
	    rm /mnt/chroot.sh
    ##### c) Unmount all the partitions
    	umount -R /mnt
    ##### d) Restart the machine
    	reboot
#####     --------------------------------------------------