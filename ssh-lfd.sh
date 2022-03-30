#!/bin/bash
##
### ssh-lfd.sh - ssh-l(ogin)-f(ail)-d(eny)
##
#
export DENYHOST="/etc/hosts.deny"
export AUTHLOG="/var/log/auth.log"
export LOGFILE="/var/log/ssh-lfd.log"
export TMPFILE="/tmp/ssh-lfd.tmp"
export HOSTLIST="/tmp/ssh-lfd.hosts"

banner() {
	log ""
	log "  ssh-lfd.sh - l(ogin)-f(ail)-d(eny)"
	log ""
}

log() {
	echo $1
	echo $1 >> $LOGFILE
}

cancel() {
	rm -f $TMPFILE $HOSTLIST
}

trap cancel SIGINT

if [ $(whoami) != "root" ]; then 
	banner
	echo "[!] Error: login as root and try again."
	exit
fi

touch $TMPFILE
cat $AUTHLOG | grep sshd | grep "checking getaddrinfo" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> $TMPFILE
cat $AUTHLOG | grep sshd | grep "Failed password for root" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> $TMPFILE
hosts=($(sort -u $TMPFILE))
rm -f $TMPFILE

for item in ${hosts[@]}; do
	grep $item $DENYHOST 2>&1 > /dev/null

	if [ $? == "1" ]; then
		log "[+] $(date): adding $item to $DENYHOST"
		echo "sshd:$item" >> $DENYHOST
	elif [ $? == "0" ]; then
		continue
	fi

done
