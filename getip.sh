#!/bin/bash
##
### getip.sh - get public ip by reaching out to ipchicken.com
##
#
curl -s https://ipchicken.com | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -u
