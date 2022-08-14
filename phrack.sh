#!/bin/bash
##
### phrack.sh - Download phrack
##
#
if [ $(whoami) != "root" ]; then
	echo "[!] Login as root."
	exit 1
fi

echo -e "\n\t[ $0 ]\n"
read -p "[?] How many issues to download? " total 
echo $total | grep -E '[0-9]{1,4}' 2>&1 > /dev/null

if [ $? == "0" ]; then
	
	if [ ! -d "phrack" ]; then
		echo -e "\n[!] Started: $(date)\n"
		echo "[+] Creating 'phrack' as working directory.."
		mkdir phrack
		cd phrack
	elif [ -d "phrack" ]; then
		echo -e "\n[!] Started: $(date)\n"	
		echo "[-] Using 'phrack' as working directory."
		cd phrack
	fi

	for (( issue = 1; issue <= $total; issue++ )); do 
		
		if [ ! -f "phrack$issue.tar.gz" ] && [ ! -d "phrack$issue" ]; then
			echo "[+] Downloading phrack$issue.tar.gz.."
			wget -q --show-progress "http://phrack.org/archives/tgz/phrack$issue.tar.gz"
			echo "[+] Decompressing phrack$issue.tar.gz into 'phrack$issue'.."
			mkdir phrack$issue
			cd phrack$issue
			tar -zxf ../phrack$issue.tar.gz
			cd ..
			echo -e "[+] Deleting phrack$issue.tar.gz..\n"	
			rm -f phrack$issue.tar.gz
		elif [ -f "phrack$issue.tar.gz" ] || [ -d "phrack$issue" ]; then
			echo "[-] phrack$issue.tar.gz already downloaded."
			continue
		fi
	done

elif [ $? == "1" ]; then
	echo "[!] Input must be a number. Exiting.."
	cd ..
	rm -rf phrack
	exit 1
fi

echo -e "[!] Finished: $(date)"
