#!/bin/sh

STARTUP="off"

modem_log()
{
	/bin/echo -e "${@}" >> /smodem/ppp.temp.log
}

/bin/echo "${$}" > /smodem/setupmodem.pid

SLEEPY="1"

# Set maximum number of failed attempts here:
MAXFAIL="4"

if [ ! -e /smodem/num.loops.log ]; then
	/bin/echo "1" > /smodem/num.loops.log
else
	NUMLOOPS="`/bin/cat /smodem/num.loops.log`"
	/bin/echo "$((NUMLOOPS+1))" > /smodem/num.loops.log
fi

APN=`/bin/grep -o "ppp.apn=.*" /proc/cmdline | /bin/cut -d" " -f1 | /bin/sed -e "s/ppp.apn=//g"`

if [ ! -e /smodem/ppp.log ]; then
	/bin/echo ""
	/bin/echo "Initialising Modem:"
	/bin/echo "==================="
	/bin/echo ""
	modem_log "Modem initialization started"
	/system/bin/setprop ro.radio.use-ppp no
	/system/bin/setprop ro.config.nocheckin yes
	PPPUSER=`/bin/grep -o "ppp.username=.*" /proc/cmdline | /bin/cut -d" " -f1 | /bin/sed -e "s/ppp.username=//g"`
	PPPPASS=`/bin/grep -o "ppp.password=.*" /proc/cmdline | /bin/cut -d" " -f1 | /bin/sed -e "s/ppp.password=//g"`
	/bin/echo "$PPPUSER * $PPPPASS" > /etc/ppp/pap-secrets
	/bin/echo "$PPPUSER * $PPPPASS" > /etc/ppp/chap-secrets
	/bin/grep -v "^name " /etc/ppp/options.smd1 | /bin/sed '$a'"name \"$PPPUSER\"" > /etc/ppp/options.smd1
	/bin/echo "Username=$PPPUSER"
	/bin/echo "Password=$PPPPASS"
	/bin/echo "APN=$APN"
	/bin/echo ""
	/bin/echo "$STARTUP" > /smodem/ppp.stat
	/bin/echo "0" > /smodem/num.fail.log
	modem_log "Modem initialization completed"
	SLEEPY="1"
fi
if [ "`/bin/cat /smodem/ppp.stat`" = "on" ]; then 
	if [ "`/bin/ifconfig | /bin/grep ^ppp0`" = "" ]; then
		# Turn on ppp connection
		NUMATTEMPT="`/bin/cat /smodem/num.fail.log`"
		NUMATTEMPT="$((NUMATTEMPT+1))"
		modem_log "Connection attempt ${NUMATTEMPT}..."
		if [ -e /sys/class/vogue_hw/gsmphone ] ; then
			/bin/echo -e "AT+CGDCONT=1,\"IP\",\"$APN\",,0,0\r" > /dev/smd0
			/bin/sleep 2
			/bin/echo -e "ATD*99***1#\r" > /dev/smd0
			/bin/sleep 4
		else
			/bin/cat /initmodem1  > /dev/smd0
			/bin/sleep 2
			/bin/cat /initmodem2 > /dev/smd0
			/bin/sleep 4
		fi
		/bin/pppd /dev/smd1
		TIMEOUT=20
      while [ "`/bin/ifconfig | /bin/grep ^ppp0`" = "" -a ! "$TIMEOUT" = "0" ] ; do
          /bin/echo "Waiting for ppp"
          TIMEOUT=`/bin/expr $TIMEOUT - 1`
          /bin/sleep 1
      done
		if [ "`/bin/ifconfig | /bin/grep ^ppp0`" = "" ]; then
			modem_log "Connection attempt FAILED!"
			NUMFAIL="`/bin/cat /smodem/num.fail.log`"
			/bin/echo "$((NUMFAIL+1))" > /smodem/num.fail.log
			SLEEPY="0"
		else
			modem_log "Connection attempt SUCCESSFUL!"
			modem_log "Phone IP:  `/bin/ifconfig ppp0 | /bin/grep 'inet addr:' | /bin/cut -d':' -f2 | /bin/cut -d' ' -f1`"
			modem_log "Subnet  :  `/bin/ifconfig ppp0 | /bin/grep 'inet addr:' | /bin/cut -d':' -f4 | /bin/cut -d' ' -f1`"
			modem_log "P-t-P   :  `/bin/ifconfig ppp0 | /bin/grep 'inet addr:' | /bin/cut -d':' -f3 | /bin/cut -d' ' -f1`"
			/bin/echo "0" > /smodem/num.fail.log
			SLEEPY="1"
		fi
		
		if [ "`/bin/cat /smodem/num.fail.log`" -ge "$MAXFAIL" ]; then
			modem_log "Connection attempts have failed too many times!"
			modem_log "Giving up on connection..."
			/bin/echo "0" > /smodem/num.fail.log
			/bin/echo "off" > /smodem/ppp.stat
			SLEEPY="1"
		fi
		
	else
		modem_log "Already connected"
		modem_log "Stopping further attempts..."
		/bin/echo "0" > /smodem/num.fail.log
		SLEEPY="1"
	fi
elif [ "`/bin/cat /smodem/ppp.stat`" = "off" ]; then
	if [ "`/bin/ifconfig | /bin/grep ^ppp0`" = "" ]; then
		modem_log "Connection is already terminated!"
		modem_log "Stopping further attempts..."
		/bin/echo "0" > /smodem/num.fail.log
		SLEEPY="1"
	else
		# Turn off connection
		NUMATTEMPT="`/bin/cat /smodem/num.fail.log`"
		NUMATTEMPT="$((NUMATTEMPT+1))"
		modem_log "Termination attempt ${NUMATTEMPT}..."
		/system/bin/ps | /bin/grep "pppd" | /bin/sed "s/  */ /g" | /bin/cut -d' ' -f2 | /bin/xargs /bin/kill
		/bin/sleep 1
		/bin/echo -e "ATH\r" > /dev/smd0
		if [ -e /sys/class/vogue_hw/gsmphone ] ; then
			/bin/sleep 1
		else
			/bin/sleep 1
			/bin/echo -e "AT+CFUN=66\r" > /dev/smd0
			/bin/sleep 2
			/bin/echo -e "AT+CFUN=1\r" > /dev/smd0
			/bin/sleep 2
			/bin/echo -e "AT+CLVL=102\r" > /dev/smd0
			/bin/sleep 1
			/bin/echo -e "AT+CMUT=0\r" > /dev/smd0
			/bin/sleep 1
		fi

		if [ "`/bin/ifconfig | /bin/grep ^ppp0`" != "" ]; then
			modem_log "Termination attempt FAILED!"
			NUMFAIL="`/bin/cat /smodem/num.fail.log`"
			/bin/echo "$((NUMFAIL+1))" > /smodem/num.fail.log
			SLEEPY="0"
		else
			modem_log "Termination attempt SUCCESSFUL!"
			modem_log "ppp0 connection is down"
			/bin/echo "0" > /smodem/num.fail.log
			SLEEPY="1"
		fi
		
		if [ "`/bin/cat /smodem/num.fail.log`" -ge "$MAXFAIL" ]; then
			modem_log "Termination attempts have failed too many times!"
			modem_log "Giving up on terminating connection..."
			/bin/echo "0" > /smodem/num.fail.log
			/bin/echo "on" > /smodem/ppp.stat
			SLEEPY="1"
		fi
		
	fi
else
	modem_log "Invalid ppp.on contents!"
	modem_log "Aborting further actions..."
	SLEEPY="1"
fi

if [ "$SLEEPY" = "1" ]; then
	modem_log "Done!"
	/bin/cat /smodem/ppp.temp.log >> /smodem/ppp.log
	rm /smodem/setupmodem.pid
	/smodem/sleep.sh
	rm /smodem/sleep.pid
fi
