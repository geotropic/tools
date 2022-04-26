#!/bin/bash
##
### rotate.sh - Setup proxychains.conf with a new set of transparent proxies      
## Note: For better results, configure proxychains for 'random' and modify tcp timeouts to a lower number
#
getProxies() {
    proxyURL="https://api.proxyscrape.com/v2/?request=getproxies&protocol=socks5&timeout=10000&country=all"
    proxyList=($(curl -s $proxyURL))
}

addProxies() {
    proxies=($(shuf -e ${proxyList[*]} -n 30))

    for proxy in ${proxies[*]}; do
        echo -e "socks5\t$proxy" >> /etc/proxychains.conf
        sed -i "$(grep -n $proxy /etc/proxychains.conf | cut -d ':' -f 1) s/:/ /" /etc/proxychains.conf
    done
}

deleteProxies() {
    for x in {1..30}; do
        sed -i '$d' /etc/proxychains.conf
    done
}

if [ $(whoami) != "root" ]; then
    echo "[!] Login as root and try again."
    exit 1
fi

if [ ! "$(which curl)" ]; then
    echo "[!] Install 'curl' and try again."
    exit 1
elif [ ! "$(which proxychains)" ]; then
    echo "[!] Install 'proxychains' and try again."
    exit 1
fi

grep 'rotate.sh' /etc/proxychains.conf 2>&1 > /dev/null

if [ $? == "0" ]; then
    echo "[-] Downloading new proxy list.."
    getProxies
    echo "[-] Deleting old proxies.."
    deleteProxies
    echo "[-] Adding new proxies.."
    addProxies
elif [ $? == "1" ]; then
    echo "[-] Downloading new proxy list.."
    getProxies
    echo -e "\n# Added by rotate.sh:" >> /etc/proxychains.conf
    echo "[-] Adding new proxies.."
    addProxies
fi

echo "[!] /etc/proxychains.conf:"
tail -n 31 /etc/proxychains.conf
exit