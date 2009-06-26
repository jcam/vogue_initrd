#!/bin/sh

STARTCHECK=`/bin/grep -o "ppp.nostart=.*" /proc/cmdline | /bin/cut -d" " -f1 | /bin/sed -e "s/ppp.nostart=//g"`
if [ "$STARTCHECK" == "1" ] ; then
    CMD=""
else
    CMD="on"
fi

MODEMOK="yes"

modem_log()
{
	/bin/echo -e "${@}" >> /smodem/ppp.log
}

/bin/echo "${$}" > /smodem/setupmodem.pid


/bin/echo ""
/bin/echo "Initialising Modem:"
/bin/echo "==================="
/bin/echo ""
modem_log "Modem initialization started"
#/system/bin/setprop ro.radio.use-ppp no
#/system/bin/setprop ro.config.nocheckin yes
PPPUSER=`/bin/grep -o "ppp.username=.*" /proc/cmdline | /bin/cut -d" " -f1 | /bin/sed -e "s/ppp.username=//g"`
PPPPASS=`/bin/grep -o "ppp.password=.*" /proc/cmdline | /bin/cut -d" " -f1 | /bin/sed -e "s/ppp.password=//g"`
/bin/echo "$PPPUSER * $PPPPASS" > /etc/ppp/pap-secrets
/bin/echo "$PPPUSER * $PPPPASS" > /etc/ppp/chap-secrets
/bin/grep -v "^name " /etc/ppp/options.smd | /bin/sed '$a'"name \"$PPPUSER\"" > /etc/ppp/options.smd1
/bin/echo "Username=$PPPUSER"
/bin/echo "Password=$PPPPASS"
/bin/echo ""
modem_log "Modem initialization completed"

while [ "$MODEMOK" == "yes" ] ; do
	echo "working" > /smodem/working
	if [ "$CMD" = "on" ]; then 
		if [ ! -e /etc/ppp/ppp-gprs.pid ] ; then
			modem_log "Starting pppd..."
			/bin/pppd /dev/smd1
			if [ ! -e /etc/ppp/ppp-gprs.pid ] ; then
				modem_log "Connection attempt FAILED!"
			else
				modem_log "Connection attempt SUCCESSFUL!"
	                        modem_log "Phone IP:  `/bin/ifconfig ppp0 | /bin/grep 'inet addr:' | /bin/cut -d':' -f2 | /bin/cut -d' ' -f1`"
        	                modem_log "Subnet  :  `/bin/ifconfig ppp0 | /bin/grep 'inet addr:' | /bin/cut -d':' -f4 | /bin/cut -d' ' -f1`"
                	        modem_log "P-t-P   :  `/bin/ifconfig ppp0 | /bin/grep 'inet addr:' | /bin/cut -d':' -f3 | /bin/cut -d' ' -f1`"
			fi
		else
			modem_log "pppd already running"
		fi
	elif [ "$CMD" = "off" ]; then
		if [ ! -e /etc/ppp/ppp-gprs.pid ] ; then
			modem_log "Connection is already terminated. Resetting Modem..."
			/bin/echo -e "AT+CFUN=66\r" > /dev/smd0
			/bin/sleep 2
			/bin/echo -e "AT+CFUN=1\r" > /dev/smd0
			/bin/sleep 2
			/bin/echo -e "AT+CLVL=102\r" > /dev/smd0
			/bin/sleep 1
			/bin/echo -e "AT+CMUT=0\r" > /dev/smd0
			MODEMOK="no"
		else
			modem_log "Shutting down pppd..."
			/bin/kill `/bin/grep -v ppp /etc/ppp/ppp-gprs.pid`
		fi

	elif [ "$CMD" != "" ]; then
		modem_log "Invalid command: $CMD"
		modem_log "Aborting further actions..."
	fi

	modem_log "Done!"
	rm /smodem/working
	read CMD < /smodem/control
done
rm /smodem/setupmodem.pid
