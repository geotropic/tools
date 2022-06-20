#!/bin/bash
##
### tropic-setup.sh - Debian Linux 11 first time setup and configuration 
## 
#
plexURL="https://downloads.plex.tv/plex-media-server-new/1.25.8.5663-e071c3d62/debian/plexmediaserver_1.25.8.5663-e071c3d62_amd64.deb"

if [ $(whoami) != "root" ]; then
	echo "[!] Error: Login as root and try again.."
	exit 1
fi

echo -e "\n\t[ Debian $(cat /etc/debian_version) ] - Debian Linux 11 setup and configuration\n"

# Configure network
read -p "[?] Do you want to configure network interfaces(y or n)? " choice 

if [ $choice == "y" ]; then
	configured="false"

	while [ $configured == "false" ]; do
		ip link
		read -p "[?] Enter interface name: " interface 

		if [ ! "$(ip link | grep $interface)" ]; then
			echo "[!] Interface '$interface' not found."
			continue
		elif [ "$(grep $interface /etc/network/interfaces)" ]; then
			echo "[!] Configuration for '$interface' found in /etc/network/interfaces. Skipping.."
			configured="true"
			continue
		fi
	
		wifiConfigured="false"

		while [ $wifiConfigured == "false" ]; do
			read -p "[?] Is '$interface' a wireless interface(y or n)? " choice 

			if [ $choice == "y" ]; then
				echo "[+] Bringing up wireless interface '$interface'.."
				ip link set $interface up

				if [ $? != "0" ]; then
					echo "[!] Failed to bring up wireless interface '$interface'."
					continue
				else
					while [ $wifiConfigured == "false" ]; do 
						echo "[+] Scanning for wireless networks.."
						iwlist $interface scan | grep ESSID
						read -p "[?] Enter the wireless network name: " essid 
						echo "[+] Validating.."

						if [ ! "$(iwlist $interface scan | grep $essid)" ]; then
							echo "[!] Wireless network '$essid' not found."
							continue
						fi

						while true; do
							read -sp "[?] Enter the PSK for '$essid': " psk
							wpa_passphrase $essid $psk
							read -p "[?] Does this look correct(y or n)? " choice 

							if [ $choice == "y" ]; then
								wireless="true"
								wifiConfigured="true"
								break
							elif [ $choice == "n" ]; then
								continue
							fi
						done
					done
				fi
			elif [ $choice == "n" ]; then
				wireless="false"
				wifiConfigured="true"	
			fi
		done

		dhcpConfigured="false"

		while [ $dhcpConfigured == "false" ]; do
			read -p "[?] Use DHCP for interface '$interface'(y or n)? " choice

			if [ $choice == "y" ]; then
				dhcp="true"
				dhcpConfigured="true"
			elif [ $choice == "n" ]; then
			
				while true; do
					read -p "[?] Enter static IP address for '$interface': " address

					if [ ! "$(echo $address | grep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" ]; then
						echo "[!] Error: invalid IPv4 address."
						continue
					elif [ "$(echo $address | grep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" ]; then
						break
					fi
				done
			
				while true; do
					read -p "[?] Enter gateway address for '$interface': " gateway

					if [ ! "$(echo $gateway | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" ]; then
						echo "[!] Error: invalid IPv4 address."
						continue
					elif [ "$(echo $gateway | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" ]; then
						break
					fi
				done

				dhcp="false"
				dhcpConfigured="true"
			fi
		done

		while true; do
			read -p "[?] Allow hotplug on interface '$interface'(y or n)? " choice

			if [ $choice == "y" ]; then
				hotplug="true"
				break
			elif [ $choice == "n" ]; then
				hotplug="false"
				break
			fi
		done
		
		while true; do
			read -p "[?] Set metric for interface '$interface'(y or n)? " choice

			if [ $choice == "y" ]; then
				metric="true"
			
				while true; do
					read -p "[?] Enter metric: " ifMetric

					if [ ! "$(echo $ifMetric | grep -E '[0-9]{1,5}')" ]; then
						echo "[!] Invalid metric, use a number between 1-99999."
						continue
					elif [ "$(echo $ifMetric | grep -E '[0-9]{1,5}')" ]; then
						break
					fi
				done
			elif [ $choice == "n" ]; then
				metric="false"
				break
			fi
		done

		echo "[+] Writing configuration for '$interface' to /etc/network/interfaces.."
		echo -e "\nauto $interface" >> /etc/network/interfaces

		if [ $hotplug == "true" ]; then
			echo "allow-hotplug $interface" >> /etc/network/interfaces
		fi

		if [ $dhcp == "true" ]; then
			echo -e "iface $interface inet dhcp" >> /etc/network/interfaces
		elif [ $dhcp == "false" ]; then
			echo -e "iface $interface inet static\n\taddress $address/24" >> /etc/network/interfaces
			echo -e "\tgateway $gateway" >> /etc/network/interfaces
		fi

		if [ $wireless == "true" ]; then
			wpaPass=$(wpa_passphrase $essid $psk | grep -Eo '[a-f0-9]{64}')
			echo -e "\twpa-ssid $essid\n\twpa-psk $wpaPass" >> /etc/network/interfaces
		fi

		if [ $metric == "true" ]; then
			echo -e "\tmetric $ifMetric" >> /etc/network/interfaces
		fi

		echo "[+] Configuration for '$interface' written to /etc/network/interfaces."

		while true; do 
			read -p "[?] Do you want to configure another interface(y or n)? " choice
			
			if [ $choice == "y" ]; then
				configured="false"
				break
			elif [ $choice == "n" ]; then
				configured="true"
				break
			fi
		done

		service networking restart

		if [ $? != "0" ]; then
			echo "[!] Network configuration failed."
			break
		elif [ $? == "0" ]; then
			configured="true"
			echo "[!] Network configuration successful."
		fi
	done
fi

# Remove Debian 'cdrom' repos from /etc/apt/sources.list
grep 'cdrom' /etc/apt/sources.list 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[+] Removing 'cdrom' repos from /etc/apt/sources.list.."
	sed -i "/cdrom/d" /etc/apt/sources.list
elif [ $? == "1" ]; then
	echo "[-] /etc/apt/sources.list is already configured."
fi

# Install software from Debian repos
echo "[+] Checking for network connection.."
ping -c 3 google.com 2>&1 > /dev/null

if [ $? != "0" ]; then
	echo "[!] Error: no network connection. Exiting.."
	exit 1
fi

echo "[+] Installing software.."
apt install rsync vim iw hydra ldapscripts python htop ntfs-3g bully aircrack-ng dsniff tor arp-scan \
	nbtscan masscan nmap smbclient reaver tshark gdb build-essential curl tcpdump git gpg proxychains \
	macchanger whois samba samba-client hashcat hcxtools mdk3 mdk4 smartmontools

# Configure tor for manual start and enable control port with hashed password
grep 'ControlPort' /etc/tor/torrc | grep '#' 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[+] Configuring /etc/tor/torrc.."
	service tor stop 2>&1 > /dev/null
	systemctl disable tor 2>&1 > /dev/null
	sed -i "$(grep -n 'ControlPort' /etc/tor/torrc | cut -d ':' -f 1) s/^#//" /etc/tor/torrc
	echo -e "\nHashedControlPassword $(tor --hash-password controlpass | grep 16)" >> /etc/tor/torrc
elif [ $? == "1" ]; then
	echo "[-] /etc/tor/torrc is already configured."
fi

# Configure .bashrc for root
grep 'Added' /root/.bashrc 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] /root/.bashrc is already configured."
elif [ $? == "1" ]; then
	echo "[+] Configuring /root/.bashrc.."
	echo -e "\n# Added after install:" >> /root/.bashrc
	echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc
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

# Configure mounted drives
grep -E '/mnt/storage|/mnt/media' /etc/fstab 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] /etc/fstab is already configured."
elif [ $? == "1" ]; then

	if [ ! -d "/mnt/media" ]; then 
		mkdir /mnt/media
	fi

	if [ ! -d "/mnt/storage" ]; then
		mkdir /mnt/storage
	fi

	echo "[+] Configuring /etc/fstab.."
	echo -e "\n# 2TB Media HDD\nUUID=66FCCE5F2C67D44B   /mnt/media      ntfs    defaults        0       0" >> /etc/fstab
	echo -e "\n# 4TB Storage HDD\nUUID=4E871E2F20018618   /mnt/storage    ntfs    defaults        0       0" >> /etc/fstab
	mount -a

	if [ $? != "0" ]; then
		echo "[!] Error: drives failed to mount. Exiting.."
		exit 1
	fi
fi

# Migrate scripts into /usr/local/sbin
if [ "$(ls /usr/local/sbin)" ]; then
	echo "[-] /usr/local/sbin is already configured."
elif [ ! "$(ls /usr/local/sbin)" ]; then
	echo "[+] Migrating scripts into /usr/local/sbin.."
	cp /mnt/storage/Backup/tropic-backup/sbin/* /usr/local/sbin
	chmod go-rx /usr/local/sbin
	chmod go-rx /usr/local/sbin/*
fi

# Add entries to /etc/crontab
grep -E 'SSH|2TB|DuckDNS' /etc/crontab 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] /etc/crontab is already configured."
elif [ $? == "1" ]; then
	echo "[+] Adding entries to /etc/crontab.."
	echo -e "\n# SSH blacklist every 3 minutes" >> /etc/crontab
	echo -e "*/3   * * * *   root    /usr/local/sbin/ssh-lfd.sh 2>&1 > /dev/null" >> /etc/crontab
	echo -e "\n# Backup 2TB media drive to 4TB storage drive every monday morning" >> /etc/crontab
	echo -e "0     5 * * 1   root    rsync -avu /mnt/media/* /mnt/storage > /dev/null 2>&1" >> /etc/crontab
	echo -e "\n# Update DuckDNS domain records every night" >> /etc/crontab
	echo -e "0     3 * * *   root    /usr/local/sbin/dns-update.sh 2>&1 > /dev/null" >> /etc/crontab
fi

# Import encryption keys
gpg --list-keys | grep tropic 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] Encryption keys already imported."
elif [ $? == "1" ]; then 
	echo "[+] Importing encryption keys.."
	gpg --import /mnt/storage/Backup/tropic-backup/tmp/.../tropic.public
	gpg --import /mnt/storage/Backup/tropic-backup/tmp/.../tropic.private
	gpg --edit-key tropic trust quit
fi

# Set up tmp directory 
if [ ! -d "/usr/local/tmp" ] && [ ! -d "/usr/local/tmp/..." ]; then
	echo "[+] Setting up tmp directory.."
	mkdir /usr/local/tmp /usr/local/tmp/...
	chmod go-rx /usr/local/tmp /usr/local/tmp/...
	cp /mnt/storage/Backup/tropic-backup/tmp/.../*.gpg /usr/local/tmp/...
	chmod go-rx /usr/local/tmp/.../*
fi

# Configure samba server
grep -E 'remote-storage|remote-media' /etc/samba/smb.conf 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] /etc/samba/smb.conf is already configured."
elif [ $? == "1" ]; then
	echo "[+] Configuring /etc/samba/smb.conf.."
	echo -e "\n[remote-storage]\n\tcomment = Remote Storage 4TB\n\tread only = no\n\tpath = /mnt/storage\n\tguest ok = no" >> /etc/samba/smb.conf
	echo -e "\n[remote-media]\n\tcomment = Remote Media 2TB\n\tread only = no\n\tpath = /mnt/media\n\tguest ok = no" >> /etc/samba/smb.conf
fi

for user in ${users[*]}; do
	pdbedit --list | grep $user 2>&1 > /dev/null

	if [ $? == "0" ]; then
		continue
	elif [ $? == "1" ]; then
		smbpasswd -a $user
		echo "[+] User: $user added to smbd."	
	fi
done

service smbd restart

# Download and install Plex
systemctl list-units --type=service | grep 'plex' 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] Plex Media Server already installed."
elif [ $? == "1" ]; then
	echo "[+] Downloading Plex Media Server .deb package.."
	wget $plexURL 
	echo "[+] Installing Plex Media Server .deb package.."
	dpkg -i plex*.deb
	rm -f plex*.deb
	echo "[+] Configuring package manager for Plex updates.."	
	wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add - 
	sed -i "$(grep -n 'public' /etc/apt/sources.list.d/plexmediaserver.list | cut -d ':' -f 1) s/^#//" /etc/apt/sources.list.d/plexmediaserver.list 
fi

echo "[!] $0 finished. Exiting.."
exit 0
