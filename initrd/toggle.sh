#!/bin/sh

modem_log()
{
        /bin/echo -e "${@}" >> /smodem/ppp.temp.log
}

if [ -e /smodem/working ]; then
	/bin/echo "setupmodem.sh is not sleeping yet..."
	/bin/echo ""
	/bin/echo "Please wait a few seconds before"
	/bin/echo "running the toggle again"
	exit 1
elif [ "`/bin/ifconfig | /bin/grep ^ppp0`" = "" ]; then
	# Turn ppp connection on
	modem_log "Initiating ppp connection..."
	/bin/echo "on" > /smodem/control
	/bin/echo "Turning ppp connection on."
else
	# Turn off ppp connection
	modem_log "Terminating ppp connection..."
	/bin/echo "off" > /smodem/control
	/bin/echo "Turning ppp connection off."
fi
