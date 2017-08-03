#!/bin/bash

echo "Pinging Loopback Address...."

gatewayIPStr=`route | grep default`
gatewayIP=$(echo $gatewayIPStr | cut -d " " -f2)

#echo $gatewayIP
#echo $gatewayIPStr | cut -d " " -f2
#echo "Pinging Loopback Address"

ping -c 4 127.0.0.1>>/dev/null

if [ $? -eq 0 ]
then
	sudo ifconfig lo down
	ipAddr=`ifconfig | grep inet\ a  | cut -d ":" -f2 | cut -d " " -f1 | head -n 1`
	sudo ifconfig lo up
	
	echo "your Ip Address $ipAddr"
	echo "Gateway Address $gatewayIP"
#	echo $gatewayIPStr | cut -d " " -f2

	ping -c 4 $ipAddr>>/dev/null
	
	if [ $? -eq 0 ]
	then
		echo "No problem in your TCP/IP Configuration."
		echo "Checking internet connectivity..."
		ping -c 5 www.google.com>>/dev/null

		if [ $? -eq  0 ]
		then
			echo "Able to reach internet, yah!"
		else
			echo "Not able to check internet connectivity!"
		
		echo "Checking Gateway Config..."
		ping -c 5 $gatewayIP>>/dev/null

			if [ $? -eq  0 ]
			then
				echo "Able to your Gateway, i think Firewall applied on your Gateway!"
			else
				echo " Not able reach Gateway....!"
			fi		
		fi
	else
		echo "Problem in your TCP/IP Configuration."
		
	fi
else
echo "Check Your TCP/IP Configuration."
fi


