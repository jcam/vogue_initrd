#!/bin/sh

modem_log()
{
        /bin/echo -e "${@}" >> /smodem/ppp.temp.log
}

/bin/echo "" > /smodem/ppp.temp.log
if [ -e /smodem/setupmodem.pid ]; then
	/bin/echo "setupmodem.sh is not sleeping yet..."
	/bin/echo ""
	/bin/echo "Please wait a few seconds before"
	/bin/echo "running the toggle again"
	modem_log "Toggle is not ready yet..."
	modem_log "Please wait a few seconds and try again."
	exit 1
elif [ "`/bin/ifconfig | /bin/grep ^ppp0`" = "" ]; then
	# Turn ppp connection on
	modem_log "Initiating ppp connection..."
	/bin/echo "on" > /smodem/ppp.stat
	/bin/echo "Turning ppp connection on."
else
	# Turn off ppp connection
	modem_log "Terminating ppp connection..."
	/bin/echo "off" > /smodem/ppp.stat
	/bin/echo "Turning ppp connection off."
fi

/bin/echo '/bin/cat /smodem/sleep.pid | /bin/xargs /bin/kill' | /bin/su
