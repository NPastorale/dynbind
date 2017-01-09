#!/usr/local/bin/bash

#######################################################
#                                                     #
#  Obtains the current external IP, compares it       #
#  against the defined IPs in the bind config         #
#  file and, if they do not match, it modifies them   #
#                                                     #
#######################################################

#############
# Variables #
#############
# Files to be modified
pfconfig=/conf/config.xml
bindconfig=/cf/named/etc/namedb/master/ExternalView/nahue.com.ar.DB
pfconfigcache=/tmp/config.cache
pfconfigbkp="$pfconfig-e"
bindconfbkp="$bindconfig-e"
#External interface
interface=rl0
# Current external IP
currextip=$(ifconfig $interface | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
# Current bind config file IP
currbindip=$(grep 'www' $bindconfig | grep -Eo '([0-9]*\.){3}[0-9]*')
# Current serial number
currbindser=$(cut -f 3 $bindconfig | head -10 | tail -1 | grep -Eo '([0-9]*)')
# Current serial number substring
currbindsersub=${currbindser:0:8}
# Same date serial plus one
newserial1=$((currbindser + 1))
# Current date YYYYMMDD
currdate=$(date +%Y%m%d)
# Current date serial format YYYYMMDDXX
newserial=$(date +%Y%m%d)01

if [ -z "$currextip" ]
then
	exit
fi

if [ "$currextip" != "$currbindip" ] # Compares the current external IP against the one in the zone file
then
	sed -i -e "s/$currbindip/$currextip/g" "$pfconfig" # Replaces all the occurrences of current file IP found with the new IP on pfconfig
	sed -i -e "s/$currbindip/$currextip/g" "$bindconfig" # Replaces all the occurrences of current file IP found with the new IP on bindconfig
	if [ "$currbindsersub" = "$currdate" ] # Compares the date within the current serial number against the current date
	then
		sed -i -e "s/$currbindser/$newserial1/g" "$pfconfig" # Adds one to the current serial on pfconfig
		sed -i -e "s/$currbindser/$newserial1/g" "$bindconfig" # Adds one to the current serial on bindconfig
	else
		sed -i -e "s/$currbindser/$newserial/g" "$pfconfig" # Replaces the old serial with the new one on pfconfig
		sed -i -e "s/$currbindser/$newserial/g" "$bindconfig" # Replaces the old serial with the new one on bindconfig
	fi
	rm $pfconfigbkp
	rm $bindconfbkp
	rm $pfconfigcache
	killall -e named
fi
