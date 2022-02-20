#!/usr/bin/env python
##
### checkftp.py - Check ftp for anonymous login
##
#
import ftplib,sys
from ftplib import FTP

def usage():
    print("    checkftp.py - check ftp for anonymous login")
    print("         Usage: " + sys.argv[0] + " <hostname>")

def main():
    if len(sys.argv) < 2:
        usage()
        exit()

    host = sys.argv[1]
    anon = False

    try:
	ftp = FTP(host, timeout = 5)
    except:
        print("[!] Error: Could not connect to " + host)
        exit()

    try:
    	print("[-] Trying anonymous login at " + host + "..")
        ftp.login()
        anon = True
        print("[+] " + host + " allows anonymous login")
	print("[-] Trying to interact(pwd)..")

	try:
	    ftp.pwd()
	    print("[+] Interaction successful")
	    ftp.close()
	except:
	    print("[!] Error: interaction with server failed(pwd)")
	    ftp.close()
    
    except:
        print("[!] Error: Could not login as 'anonymous' on " + host)
        anon = False
        ftp.close()

    if anon == True: 
	saveFile = open("anons.txt", "a")
        saveFile.write("[+] " + host + " allows anonymous login\n")
        saveFile.close()

    exit()

if __name__ == "__main__":
    main()
