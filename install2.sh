#!/bin/bash
#####     Created by: ag
#####     File: install2.sh
#####     --------------------------------------------------
#####  INPUTS                                  #####
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
#####     -------------------------------------------------- 
#####     3. Post-Installation - Configuration
      # A. LOGIN AS ROOT
	##### a) update & install bash-completion
		sudo pacman --noconfirm --needed -Syu
		sudo pacman --noconfirm --needed -S bash-completion
	##### b) create personal account & password of personal account
   		useradd -m -g users -G audio,video,network,wheel,storage -s /bin/bash $USERNAME
   		echo "$USERNAME:$USER_PASSWORD" | /usr/sbin/chpasswd
    ##### c) account sudo permitions
		sed -i "/#MY_PERMISSION/d" /etc/sudoers
		echo -e "%wheel ALL=(ALL) NOPASSWD: ALL #MY_PERMISSION" >> /etc/sudoers
	##### d) logout of root
	    curl -LO https://raw.githubusercontent.com/ag-archlinux/arch-dwm/master/install3.sh 
	    cp install3.sh /home/$USERNAME/install3.sh
	    rm install3.sh
	    rm install2.sh
	    exit