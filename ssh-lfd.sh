#!/bin/bash
##
### ssh-lfd.sh - ssh-l(ogin)-f(ail)-d(eny)
##
#
export DENYHOST="/etc/hosts.deny"
export AUTHLOG="/var/log/auth.log"
export LOGFILE="/var/log/ssh-lfd.log"

log() {
	echo $1
	echo $1 >> $LOGFILE
}

if [ $(whoami) != "root" ]; then 
	echo "[+] $0 - l(ogin)-f(ail)-d(eny)"	
	echo "[!] Error: login as root and try again."
	exit
fi

hosts=($(cat $AUTHLOG | grep 'sshd' | grep -E 'checking getaddrinfo|Failed password for root' | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -u))

for item in ${hosts[@]}; do
	grep $item $DENYHOST 2>&1 > /dev/null

	if [ $? == "1" ]; then
		log "[+] $(date): adding $item to $DENYHOST"
		echo "sshd:$item" >> $DENYHOST
	elif [ $? == "0" ]; then
		continue
	fi

done
