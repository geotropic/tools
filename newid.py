#!/usr/bin/env python
##
### newid.py - Change tor identity
##
#
import telnetlib

torHost = "localhost" 
torControlPort = 9051
torPort = 9050
torPassword = "controlpass"

def main():
	print """
	    newid.py - change tor exit node

		        o  o        
	               ( -- )       
	            /\( ,   ,)/\    
                  ^^   ^^  ^^   ^^  
	"""

	try: 
		telnet = telnetlib.Telnet(torHost, torControlPort)
	except:
		print " [!] Error: connection refused. Is TOR service running?"
		print ""
		exit()
		
	telnet.set_debuglevel(0)
	telnet.write('authenticate "' + torPassword + '"' + "\n")
	telnet.read_until("250 OK")
	telnet.write("signal newnym" + "\n")
	telnet.read_until("250 OK")
	telnet.write("quit")

	print "		[+] Changed exit node"
	print ""

if __name__ == "__main__":
	main()
