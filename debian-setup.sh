#!/bin/bash
##
### debian-setup.sh - Debian Linux 11 first time setup and configuration 
## 
#
if [ $(whoami) != "root" ]; then
	echo "[!] Error: Login as root and try again.."
	exit 1
fi

echo -e "\n\t[ Debian $(cat /etc/debian_version) ] - Debian Linux 11 setup and configuration\n"

# Check for internet connectivity
echo "[+] Checking for network connection.."
ping -c 3 google.com 2>&1 > /dev/null

if [ $? != "0" ]; then
	echo "[!] Error: no network connection. Exiting.."
	exit 1
fi

# Remove Debian 'cdrom' repos from /etc/apt/sources.list
grep 'cdrom' /etc/apt/sources.list 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[+] Removing 'cdrom' repos from /etc/apt/sources.list.."
	sed -i "/cdrom/d" /etc/apt/sources.list
fi

# Install software from Debian repos
echo "[+] Installing software.."
apt update
apt install rsync vim iw hydra python htop ntfs-3g bully aircrack-ng dsniff tor arp-scan nbtscan \
	masscan nmap smbclient reaver tshark gdb build-essential curl tcpdump git gpg proxychains \
	macchanger whois samba-client hashcat hcxtools mdk3 mdk4 winbind libnss-winbind xfce4-terminal

# Disable tor from startup
if [ "$(systemctl status tor | grep enabled)" ]; then
	echo "[+] Removing tor from startup.."
	systemctl disable tor > /dev/null 2>&1
elif [ "$(systemctl status tor | grep disabled)" ]; then
	echo "[-] tor service is already configured."
fi

# Configure Windows NetBIOS name resolution
grep 'wins' /etc/nsswitch.conf 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] /etc/nsswitch.conf is already configured."
elif [ $? == "1" ]; then
	echo "[+] Configuring /etc/nsswitch.conf.."
	sed -i "s/myhostname/wins myhostname/" /etc/nsswitch.conf
fi

# Configure .bashrc for root
grep 'Added' /root/.bashrc 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] /root/.bashrc is already configured."
elif [ $? == "1" ]; then
	echo "[+] Configuring /root/.bashrc.."
	echo -e "\n# Added after install:" >> /root/.bashrc
	echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;37m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc
	echo "alias grep='grep --color'" >> /root/.bashrc
	echo "alias ip='ip -c'" >> /root/.bashrc
	echo "alias diff='diff --color=auto'" >> /root/.bashrc
fi

# Configure .bash_logout for root and users
if [ -f "/root/.bash_logout" ]; then
	echo "[-] /root/.bash_logout is already configured."
elif [ ! -f "/root/.bash_logout" ]; then
	echo "[+] Creating /root/.bash_logout.."
	echo -e "\n# Clear history on logout\ncat /dev/null > ~/.bash_history\nhistory -c" > /root/.bash_logout
fi

users=($(getent passwd {1000..6000} | cut -d ":" -f 1))

for user in ${users[*]}; do
	grep 'history -c' /home/$user/.bash_logout 2>&1 > /dev/null

	if [ $? == 0 ]; then
		echo "[-] /home/$user/.bash_logout is already configured."	
	elif [ $? == 1 ]; then
		echo "[+] Creating /home/$user/.bash_logout.."
		echo -e "\n# Clear history on logout\ncat /dev/null > ~/.bash_history\nhistory -c" > /home/$user/.bash_logout
	fi
done

# Configure vim for root and users
if [ -f "/root/.vimrc" ]; then
	echo "[-] /root/.vimrc is already configured."
elif [ ! -f "/root/.vimrc" ]; then
	echo "[+] Creating /root/.vimrc.."	
	echo -e "syntax enable\nset number\nset tabstop=4\nset autoindent\ncolorscheme delek" > /root/.vimrc
fi

for user in ${users[*]}; do
	
	if [ -f "/home/$user/.vimrc" ]; then
		echo "[-] /home/$user/.vimrc is already configured."
	elif [ ! -f "/home/$user/.vimrc" ]; then
		echo "[+] Creating /home/$user/.vimrc.."
		echo -e "syntax enable\nset number\nset tabstop=4\nset autoindent\ncolorscheme delek" > /home/$user/.vimrc
	fi
done

# Set up tmp directory 
if [ ! -d "/usr/local/tmp" ] && [ ! -d "/usr/local/tmp/..." ]; then
	echo "[+] Setting up tmp directory.."
	mkdir /usr/local/tmp /usr/local/tmp/...
	chmod go-rx /usr/local/tmp /usr/local/tmp/...
fi

# Generate encryption keys for root
read -p "[?] Generate encryption keys for root(y/n)? " choice

if [ $choice == "y" ]; then
	gpg --full-generate-key
fi

echo "[!] $0 finished. Exiting.."
exit 0