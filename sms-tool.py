#!/usr/bin/env python
##
### sms-tool.py - messaging over the internet using sms gateways
##
#
import smtplib

emailAddr = ""
emailPasswd = ""  
smtpServer = "" 
smtpPort = "" 

smsGateways = ["txt.att.net", # at&t 
			"vtext.com", # verizon 
			"vmobl.com", # virgin 
			"cingular.com",	# cingular 
			"sms.mycricket.com", # cricket 
			"sms.edgewireless.com", # edge wireless 
			"qwestmp.com", # qwest 
			"messaging.sprintpcs.com", # sprint 
			"page.nextel.com", # nextel 
			"tmomail.net"] # t-mobile 
			
providers = ["At&t", "Verizon", "Virgin Mobile", "Cingular",
					"Cricket", "Edge Wireless", "Qwest", "Sprint",
					"Nextel", "T-Mobile"]
			
def banner():
	print "	sms-tool.py - prototype sms bomber"	
	print "	   by frog(frog5346@gmail.com)"
	print ""
	
def main():
	banner()
	
	for item in range(len(smsGateways)):
		print ("  " + str(item) + ": " + providers[item] + " (" +
			   smsGateways[item] + ")")
			   
	print ""
	choice = raw_input("Choose provider: ")
	
	while int(choice) >= len(smsGateways):
		print "Invalid choice."
		choice = raw_input("Choose provider: ")
		
	if int(choice) < len(smsGateways):
		print "Provider: " + providers[int(choice)]
		
	phoneNum = raw_input("Enter number(area code first): ")
	print "Phone: " + str(phoneNum) + "@" + smsGateways[int(choice)]

	msg = raw_input("Now type your message: ")
	print ""
	print "To: " + str(phoneNum) + "@" + smsGateways[int(choice)]
	print "Message: " + msg
	print ""
	
	theCount = raw_input("How many times should we send the message? ")
	allCount = theCount
	print "Message will be sent " + theCount + " time(s)."
	confirm = raw_input("Ready to send? ")
	
	if confirm == "y" or confirm == "Y" or confirm == "yes" or confirm == "Yes":
		destAddr = str(phoneNum) + "@" + smsGateways[int(choice)]
		
		try:
			connection = smtplib.SMTP(smtpServer, smtpPort)
			connection.set_debuglevel(1)
			connection.starttls()
			connection.login(emailAddr, emailPasswd)
		except smtplib.SMTPAuthenticationError:
			print "SMTP Authentication error."
			exit()
		except smtplib.SMTPServerDisconnected:
			print "SMTP Connection error."
			exit()
		except smtplib.SMTPException, smtpException:
			print "SMTP Exception: " + str(smtpException)
			exit()
		
		try:	
			while theCount > 0:
				print str(theCount) + " message(s) left to send.."
				connection.sendmail(emailAddr, destAddr, msg)
				theCount = int(theCount) - 1
		except:
			print "SMTP send error."
			exit()

		print ""	
		print str(allCount) + " message(s) sent successfully."
	elif confirm == "n" or confirm == "N" or confirm == "no" or confirm == "No":
		print "Aborted."
		exit()
	else: 
		print "Aborted."
		exit()
			  
if __name__ == "__main__":
	main()
