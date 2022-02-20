#!/bin/bash
##
### resolvers.sh - Resolve offending IP's from /etc/hosts.deny, seperate the non-resolvable IP's, and log the resolvable domains
### NOTE: Run script as './resolvers.sh 2>/dev/null' to suppress bash script warnings. This script uses tor for dns resolution.
##
#
export blacklist="cat /etc/hosts.deny | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -t ."

if [ $(whoami) != "root" ]; then
    echo -e "\e[0;91m[!] Login as root and try again.\e[0m"
    exit 1
elif [ -z $(which tor) ]; then
    echo -e "\e[0;91m[!] Tor not installed. exiting..\e[0m"
    exit 1
fi

if [ -z $(ss -4tlpn | grep 'tor') ]; then
    echo -e "\e[0;91m[!] Tor service not running. Starting tor..\e[0m"
    service tor start
	sleep 5
fi

for host in $(eval $blacklist); do
    sleep .03

    if [ -z $(tor-resolve -x $host) ]; then
        echo -e "[\e[0;91mx\e[0m] \e[0;91m$host\e[0m does not resolve."
        echo $host >> non-resolvers.txt
    else 
        echo -e "[\e[0;94m+\e[0m] \e[0;94m$host\e[0m resolves to \e[0;92m\e[4m$(tor-resolve -x $host)\e[0m."
		echo $host >> resolvers.txt
		echo -e "\e[0;94m$host\e[0m\t\t\e[0;92m$(tor-resolve -x $host)\e[0m" >> domains.txt
    fi &
done

sleep 20 
echo -e "[\e[0;92m!\e[0m] \e[0;94mResolution complete\e[0m on \e[0;92m\e[4m$(wc -l non-resolvers.txt resolvers.txt | grep 'total') hosts.\e[0m"
echo -e "[\e[0;92m!\e[0m] \e[0;92m\e[4m$(wc -l /etc/hosts.deny)\e[0m"
