#####     --------------------------------------------------
    ##### b) Chroot

    	##### 1) Time zone
    		ln -sf /usr/share/zoneinfo/Europe/Bratislava /etc/localtime
    		hwclock-systohc
    	##### 2) Locale
    		echo "en_US.UTF-8 UTF-8" >> /etc/local.gen
			locale-gen
			echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    	##### 3) Hostname
    		read -p "Enter your computer's name: " COMPUTER_ACCOUNT
    		echo $COMPUTER_NAME >> /etc/hostname
			echo "127.0.0.1  localhost" >> /etc/hosts
			echo "::1        localhost" >> /etc/hosts
			echo "127.0.0.1  " + $COMPUTER_NAME+ ".localdomain "+ $COMPUTER_NAME >> /etc/hosts
    	##### 4) Network configuration
    		read -p "Enter your username: " PERSONAL_ACCOUNT
    		# Create personal account
    		useradd -m -G wheel,users -s /bin/bash $PERSONAL_ACCOUNT
    		# Create password of personal account
			passwd $PERSONAL_ACCOUNT
			# Account sudo permitions
			sed -i "/#MY_PERMISSION/d" /etc/sudoers
			echo -e "%wheel ALL=(ALL) NOPASSWD: ALL #MY_PERMISSION" >> /etc/sudoers
			# Configure network manager
    		pacman --noconfirm --needed -S networkmanager
			systemctl enable NetworkManager
			systemctl start NetworkManager
			pacman --noconfirm --needed -S iw wpa_supplicant dialog wpa-actiond
			systemctl enable dhcpcd
    	##### 5) Initramfs
    		mkinitcpio -p linux
    	##### 6) Root password
    		echo "Enter root password: "
			passwd
    	##### 7) Boot loader
    		pacman --noconfirm --needed -S grub os-prober
			grub-install --recheck --target=i386-pc /dev/sda
			grub-mkconfig -o /boot/grub/grub.cfg
	##### Exit chroot
	exit
#####     --------------------------------------------------