#!/bin/sh
CMD=""
STARTCHECK=`/bin/grep -o "ppp.nostart=.*" /proc/cmdline | /bin/sed -e "s/.*ppp.nostart=//g" -e "s/ .*//g"`
if [ "$STARTCHECK" != "1" ] ; then
	if [ ! -e /smodem/ppp.log ]
		CMD="on"
	fi
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
PPPUSER=`/bin/grep -o "ppp.username=.*" /proc/cmdline | /bin/sed -e "s/.*ppp.username=//g" -e "s/ .*//g"`
PPPPASS=`/bin/grep -o "ppp.password=.*" /proc/cmdline | /bin/sed -e "s/.*ppp.password=//g" -e "s/ .*//g"`
APN=`/bin/grep -o "ppp.apn=.*" /proc/cmdline | /bin/sed -e "s/.*ppp.apn=//g" -e "s/ .*//g"`
/bin/echo "$PPPUSER * $PPPPASS" > /etc/ppp/pap-secrets
/bin/echo "$PPPUSER * $PPPPASS" > /etc/ppp/chap-secrets
/bin/sed -e "s/^name .*/name $PPPUSER/g" /etc/ppp/options.smd > /etc/ppp/options.smd1
/bin/sed -e "s/^APN=.*/APN=$APN/g" /etc/ppp/dialer.smd > /etc/ppp/dialer.smd1
/bin/echo "Username=$PPPUSER"
/bin/echo "Password=$PPPPASS"
/bin/echo "APN=$APN"
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
		/bin/echo -e "ATH\r" > /dev/smd0
		if [ ! -e /etc/ppp/ppp-gprs.pid ] ; then
			if [ ! -e /sys/class/vogue_hw/gsmphone ] ; then
				modem_log "Connection is already terminated. Resetting Modem..."
				/cdmaReset
				MODEMOK="no"
			fi
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
