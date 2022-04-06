#!/bin/bash
##
### whois-denied.sh - Search WHOIS records(over tor) for IP's from /etc/hosts.deny
##	NOTE: Uses tor for whois(whois servers blacklist some tor exit-nodes) and dns resolution
#
if [ -z $(which tor) ]; then
	echo "[!] Error: tor not installed. Install and try again."
	exit 1
elif [ $(whoami) != "root" ]; then
	echo "[!] Error: login as root and try again."
	exit 1
fi

cancel() {
	exit 1
}

trap cancel SIGINT
systemctl status tor | grep 'active' 2>&1 > /dev/null

if [ $? == "0" ]; then
	echo "[-] Starting tor service.."
	sleep 5	
	systemctl start tor
fi

for ip in $(grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/hosts.deny | sort -uR); do
	echo -e "[-] Looking up WHOIS Record for \e[0;94m$ip\e[0m (\e[0;92m\e[4m$(tor-resolve -x $ip 2>/dev/null)\e[0m).."
	torify whois $ip | grep -E 'enied|inet|escr|wner|ame|ange|ountry|tate|ovince|ity' 
	
	if [ $? == "1" ]; then
		echo -e "[!] \e[0;91mNo record found for IP:\e[0m \e[0;94m$ip\e[0m (\e[0;92m\e[4m$(tor-resolve -x $ip 2>/dev/null)\e[0m)."
	fi
	
	echo ""
	sleep 1
done

