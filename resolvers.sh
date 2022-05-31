#!/bin/bash
##
### resolvers.sh - Resolve offending IP's from /etc/hosts.deny, seperate the non-resolvable IP's, and log the resolvable domains
### NOTE: This script uses tor for dns resolution.
##
#
blacklist="cat /etc/hosts.deny | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -t ."
red="\e[0;91m"
blue="\e[0;94m"
green="\e[0;92m"
esc="\e[0m"
uline="\e[4m"

if [ $(whoami) != "root" ]; then
    echo -e "\e${red}[!] Login as root and try again.\e${esc}"
    exit 1
fi

if [ -z $(which tor) ]; then
    echo -e "\e${red}[!] Tor not installed. exiting..\e${esc}"
    exit 1
fi

ss -4tlpn | grep 'tor' 2>&1 > /dev/null

if [ $? == "1" ]; then
    echo -e "\e${red}[!] Tor service not running. Starting tor..\e${esc}"
    service tor start
	sleep 5
fi	

for host in $(eval $blacklist); do
	tor-resolve -x $host > /dev/null 2>&1

	if [ $? == "0" ]; then
        echo -e "[${blue}+${esc}] ${blue}$host${esc} resolves to ${green}${uline}$(tor-resolve -x $host)${esc}."
		echo $host >> resolvers.txt
		echo -e "${blue}$host${esc}\t\t${green}$(tor-resolve -x $host)${esc}" >> domains.txt
	elif [ $? == "1" ]; then
        echo -e "[${red}x${esc}] ${red}$host${esc} does not resolve."
        echo $host >> non-resolvers.txt
	fi 
done

sleep 5 
echo -e "[${green}!${esc}] ${blue}Resolution complete:${esc} ${green}${uline}$(wc -l non-resolvers.txt resolvers.txt | grep 'total') hosts.${esc}"
echo -e "[${green}!${esc}] ${blue}/etc/hosts.deny:${esc} ${green}${uline}$(cat /etc/hosts.deny | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | wc -l) total hosts.${esc}"
