#!/bin/sh
CMD=""
STARTCHECK=`/bin/grep -o "ppp.nostart=.*" /proc/cmdline | /bin/sed -e "s/.*ppp.nostart=//g" -e "s/ .*//g"`
if [ "$STARTCHECK" != "1" ] ; then
	if [ ! -e /smodem/ppp.log ] ; then
		CMD="on"
	fi
fi

modem_log()
{
	/bin/echo -e "${@}" >> /smodem/ppp.log
}

/bin/echo "${$}" > /smodem/setupmodem.pid

STATUS="0"
/bin/echo $STATUS > /smodem/status

while true ; do
	echo "working" > /smodem/working
	if [ "$CMD" = "on" ]; then 
		if [ "$STATUS" = "0" ] ; then
			modem_log "Turning on data"
			STATUS="1"
			/bin/echo $STATUS > /smodem/status
			if [ -e /sys/class/vogue_hw/gsmphone ] ; then
				/bin/echo -e "AT+CREG?\r" > /dev/smd0
			else
				/bin/echo -e "AT+COPS?\r" > /dev/smd0
			fi
		else
			modem_log "Data already turned on"
		fi
	elif [ "$CMD" = "off" ]; then
		if [ "$STATUS" = "0" ] ; then
			modem_log "Data already off. Resetting Modem..."
			/bin/killall rild
		else
			modem_log "Turning off data"
			/bin/killall pppd
			/bin/echo -e "ATH\r" > /dev/smd0
			STATUS="0"
			/bin/echo $STATUS > /smodem/status
			if [ -e /sys/class/vogue_hw/gsmphone ] ; then
				/bin/echo -e "AT+CREG?\r" > /dev/smd0
			else
				/bin/echo -e "AT+COPS?\r" > /dev/smd0
			fi
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
