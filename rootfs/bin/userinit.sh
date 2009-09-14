#!/bin/sh
#
CONF_FILE="/sdcard/hero.user.conf";

renice=0

compcache_en=0
cc_disksize=24
cc_memlimit=24
cc_backingswap_en=0
cc_backingswap=/dev/block/mmcblk0p3
CC_DEVICE=/dev/block/ramzswap0

linux_swap_en=0
linux_swap_partition=/dev/block/mmcblk0p3

sys_vm_en=0
page_cluster=3
laptop_mode=0
dirty_expire_centisecs=3000 
dirty_writeback_centisecs=500
dirty_background_ratio=5
dirty_ratio=10
vfs_cache_pressure=10
overcommit_memory=0
overcommit_ratio=80
swappiness=75


CC_NEW_DECT=0;

swap_file_en=0;
linux_swap_file_size=32;
linux_swap_file=/sdcard/swap.file;

usage() {
  echo
  echo "Usage:"
  echo "/system/sd/userinit.sh [-s|-c config.file|-i]"
  echo 
  echo "Default:"
  echo "Sets system configuration based on the paratermers"
  echo "that listed in /system/sd/user.conf"
  echo 
  echo "  -s: check configuration status and cross" 
  echo "      verifiction with user configurations "
  echo "  -c config.file: use user parameters that defined"
  echo "                  in config.file "
  echo "  -i: Current system settings and info "
  echo
  echo
  exit 0
}


parse_args() 
{
	STATUS_CHK=0;
	DISP_SYS_INFO=0;
	while [ $# != 0 ]; do
	case $1 in
		-s) STATUS_CHK=1;shift;
			;;
		-c) CONF_FILE=$2; shift;shift;
			;;
		-i) DISP_SYS_INFO=1; shift;
			;;
		-*)	usage;
			;;
		*)	usage;
			;;
	esac;

	done;
	
	if [ ! -e ${CONF_FILE} ]; then
		usage;
	fi

}


# reads user specfic parameters
GET_USER_CONF() {
	MATCH=0;
	if [ -e ${CONF_FILE} ]; then

		### clean windows format if needed
		if [ "`grep -c  $CONF_FILE`" != "0" ]; then
			dos2unix $CONF_FILE
		fi

		while read inputline;
		do
			# skip comments
			COMMENTS=$(echo $inputline | grep "#" | wc -l);
			COMMENT2=$(echo $inputline | grep "#" | awk -F"#" '{print $1}');
			[[ $COMMENTS -eq 1 ]] && [[ -z "$COMMENT2" ]] && continue
			
			# skip empty lines
			[[ -z "$inputline" ]] && continue
			
			inputline=$(echo $inputline | awk -F"#" '{print $1}');

			# check begin of configurations
			BEGIN_CHK=$(echo $inputline | grep "{" | wc -l);
			END_CHK=$(echo $inputline | grep "}" | wc -l);

			if [ $MATCH -eq 0 ]; then
				if [ ${BEGIN_CHK} -eq 1 ] ; then
					MATCH=1;
					GROUP=$(echo $inputline | grep "{" | awk -F"{" '{print $1}');
					GROUP_PARS="${GROUP}_pars=\""
					eval "$GROUP=1"
				fi;
			else
				if [ ${END_CHK} -eq 1 ]; then
					MATCH=0;
					if [ $GROUP != "custom_shells" ]; then
						GROUP_PARS="$GROUP_PARS\""
						eval $GROUP_PARS
					fi
				else
					if [ $GROUP == "custom_shells" ]; then
						#inputline=$(echo $inputline | sed -e 's/;//g');
						#inputline=$(echo $inputline | sed -e 's/"/\"/g');
						custom_shells_pars="$custom_shells_pars #"$inputline" "
					else
						eval $inputline
						PAR=$(echo $inputline | awk -F"=" '{print $1}');
						if [ $(echo $inputline | grep _en | wc -l) -eq 0 ]; then
							GROUP_PARS="$GROUP_PARS $inputline "
						fi;
					fi;
				fi;
			fi;
		done < $CONF_FILE ;
	fi;
	
	LAST_LINE_CHK=`tail -1 $CONF_FILE | grep "}" | wc -l`
	if [ ${LAST_LINE_CHK} -eq 1 ] && [ $MATCH -eq 1 ]; then
		MATCH=0;
		GROUP_PARS="$GROUP_PARS\""
		eval $GROUP_PARS
	fi
	
	# checking compcache version
#	if [ -e /system/bin/rzscontrol ]; then 
#		CC_NEW_DECT=1; 
#		CC_STATUS_FLAG="rzscontrol ${CC_DEVICE} -s";
#		CC_VERSION="0.6+"
#	else
		CC_NEW_DECT=0; 
		CC_STATUS_FLAG="cat /proc/ramzswap";
		CC_VERSION="0.5"
#	fi;
	
	# overwrite swapiness 
	if [ ${compcache_en} -eq 1 ] ; then 
		swappiness=${swappiness}; 
	fi;
}

USER_CONF_CHECK()
{
if [ ${STATUS_CHK} -eq 1 ] || [ ${DISP_SYS_INFO} -eq 1 ]; then
	echo === user.conf ===
	echo "*** general ***"
	#echo general=$general
	echo renice=$renice
	echo 
	#echo compcache_pars=$compcache_pars
	echo "*** CompCache ***"
	#echo compcache=$compcache
	echo compcache_en=$compcache_en
	echo cc_memlimit=$cc_memlimit
	echo cc_disksize=$cc_disksize
	echo cc_backingswap_en=$cc_backingswap_en
	echo cc_backingswap=$cc_backingswap
	echo 
	echo "*** Swap File ***"
	echo swap_file_en=$swap_file_en
	echo linux_swap_file_size=$linux_swap_file_size
	echo linux_swap_file=$linux_swap_file
	echo 
	echo "*** Linux Swap ***"
	#echo linux_swap_pars=$linux_swap_pars
	#echo linux_swap=$linux_swap
	echo linux_swap_en=$linux_swap_en
	echo linux_swap_partition=$linux_swap_partition
	echo 
	echo "*** VM ***"
	#echo sys_vm_pars=$sys_vm_pars
	#echo sys_vm=$sys_vm
	echo sys_vm_en=$sys_vm_en
	echo swappiness=$swappiness
	echo page_cluster=$page_cluster
	echo laptop_mode=$laptop_mode
	echo dirty_expire_centisecs=$dirty_expire_centisecs
	echo dirty_writeback_centisecs=$dirty_writeback_centisecs
	echo dirty_background_ratio=$dirty_background_ratio
	echo dirty_ratio=$dirty_ratio
	echo vfs_cache_pressure=$vfs_cache_pressure
	echo overcommit_memory=$overcommit_memory
	echo overcommit_ratio=$overcommit_ratio
fi;

}


# try to optimize call aswering
renicerloop()
{
while [ 1 ]
do
        renice -18 `pidof com.android.mms`
	renice  5  `pidof com.google.process.gapps`
	renice -18 `pidof com.android.phone`
	renice -18 `pidof android.process.media`
	renice -18 `pidof mediaserver`
	renice -16 `pidof com.htc.launcher`
	renice -15 `pidof com.htc.music`
        sleep 500
done
}

CC_SWAPOFF()
{
	CC_ON=$(lsmod | grep ramzswap | wc -l);
	if [ $STATUS_CHK -eq 0 ] && [ ${CC_ON} -ge 1 ]; 
	then
		swapoff ${CC_DEVICE};
		#rm -fr ${CC_DEVICE};
		#rmmod ramzswap;
		#CC_ON=$(lsmod | grep ramzswap | wc -l);
		#if [ ${CC_ON} -ge 1 ]; then
		#	echo unable to remove compcache modules
		#fi;
	fi;

}

# compcache setup
COMPCACHE()
{
	if [ $STATUS_CHK -eq 1 ] && [ ${compcache_en} -eq 1 ]; then
		echo 
		echo === CompCache status ===
		echo CompCache version ${CC_VERSION}
		SYS_VAL=`$CC_STATUS_FLAG | grep DiskSize | awk -F" " '{print $2}'`
		CC_ON=$(lsmod | grep ramzswap | wc -l);
		
		if [ ! -z $SYS_VAL ] && [ -e ${CC_DEVICE} ] && [ ${CC_ON} -ge 1 ]; then
			echo Compcache enabled
		else
			echo !!!ERROR Compcache disabled
			dmesg | grep ramzswap | tail -10
		fi;
		
		for i in $compcache_pars;
		do
			USER_VAL=$(echo $i | awk -F"=" '{print $2}');
			USER_PAR=$(echo $i | awk -F"=" '{print $1}');
			if [ $USER_PAR == "cc_disksize" ] && [ ${cc_backingswap_en} -eq 0 ] ; then
				USER_PAR="DiskSize"
				USER_VAL=$((${USER_VAL}*1024));
				SYS_VAL=`$CC_STATUS_FLAG | grep ${USER_PAR} | awk -F" " '{print $2}'`
				echo "CompCache: $USER_PAR "$SYS_VAL"(system) "$USER_VAL"(user)"

			elif [ $USER_PAR != "cc_disksize" ] && [ ${cc_backingswap_en} -eq 1 ] ; then
				if [ $USER_PAR == "cc_memlimit" ]; then
					USER_PAR="MemLimit"
					USER_VAL=$((${USER_VAL}*1024));
					SYS_VAL=`$CC_STATUS_FLAG | grep ${USER_PAR} | awk -F" " '{print $2}'`
					echo "CompCache: $USER_PAR "$SYS_VAL"(system) "$USER_VAL"(user)"
				elif [ $USER_PAR == "cc_backingswap" ] && [ ${CC_NEW_DECT} -eq 1 ]; then
					USER_PAR="BackingSwap"
					SYS_VAL=`$CC_STATUS_FLAG | grep ${USER_PAR} | awk -F" " '{print $2}'`
					echo "CompCache: $USER_PAR "$SYS_VAL"(system) "$USER_VAL"(user)"
				else 
					USER_PAR="DiskSize"
					SYS_VAL=`$CC_STATUS_FLAG | grep ${USER_PAR} | awk -F" " '{print $2}'`
					echo "CompCache: Backing_swap "$USER_VAL" , size $SYS_VAL"
				fi
				
				
			fi;
			
			# backing swap detection is still missing
		done
		
		echo 
		echo === CompCache status output ===
		$CC_STATUS_FLAG
		
		
	elif [ $compcache_en -eq 1 ]; then
		CC_SWAPOFF;

		cc_disksize=$((${cc_disksize}*1024));
		CC_DISKSIZE_FLAG="disksize_kb=${cc_disksize}";
		cc_memlimit=$((${cc_memlimit}*1024));
		CC_MEMSIZE_FLAG="memlimit_kb=${cc_memlimit}";
		CC_BACKINGSWAP_FLAG="backing_swap=${cc_backingswap}";		
		
		
		if [ ${cc_backingswap_en} -eq 1 ] && [ -e ${cc_backingswap} ]; then
			CC_DISKSIZE_FLAG="";
		else
			CC_MEMSIZE_FLAG="";
			CC_BACKINGSWAP_FLAG="";
		fi;

#		if [ ${CC_NEW_DECT} -eq 0 ]; then

			mknod -m 0666 /dev/block/ramzswap0 b 254 0
			[ $? -eq 0 ] || fail "Failed to create the block device"

			insmod /lib/modules/lzo_compress.ko
			insmod /lib/modules/lzo_decompress.ko
			insmod /lib/modules/xvmalloc.ko
			insmod /lib/modules/ramzswap.ko ${CC_DISKSIZE_FLAG} ${CC_MEMSIZE_FLAG} ${CC_BACKINGSWAP_FLAG};
			echo insmod /lib/modules/ramzswap.ko ${CC_DISKSIZE_FLAG} ${CC_MEMSIZE_FLAG} ${CC_BACKINGSWAP_FLAG};

#		else
#			if [ ! -z ${CC_DISKSIZE_FLAG} ]; then CC_DISKSIZE_FLAG="--${CC_DISKSIZE_FLAG}"; fi;
#			if [ ! -z ${CC_MEMSIZE_FLAG} ]; then CC_MEMSIZE_FLAG="--${CC_MEMSIZE_FLAG}"; fi;
#			if [ ! -z ${CC_BACKINGSWAP_FLAG} ]; then CC_BACKINGSWAP_FLAG="--${CC_BACKINGSWAP_FLAG}"; fi;
#			modprobe ramzswap  
#			rzscontrol ${CC_DEVICE} ${CC_DISKSIZE_FLAG} ${CC_MEMSIZE_FLAG} ${CC_BACKINGSWAP_FLAG} --init;
#			
#			echo "rzscontrol ${CC_DEVICE} ${CC_DISKSIZE_FLAG} ${CC_MEMSIZE_FLAG} ${CC_BACKINGSWAP_FLAG} --init";
#		fi;
		
		echo "${swappiness}" > /proc/sys/vm/swappiness
		swapon ${CC_DEVICE};
		[ $? -eq 0 ] || fail "Failed to turn on the swap"

	elif [ $compcache_en -eq 0 ]; then
		CC_SWAPOFF;
	fi;
}

SWAPFILE_CHK()
{
	if [ ! -e  ${linux_swap_file} ] && [ ${swap_file_en} -eq 1 ]; then
		linux_swap_file_size=$((${linux_swap_file_size}*1024));
		echo "Creating swap file: ${linux_swap_file}"
		dd if=/dev/zero of=${linux_swap_file} bs=1024 count=${linux_swap_file_size}
		mkswap ${linux_swap_file}
		if [ -e  ${linux_swap_file} ]; then
			echo "SWAP file "${linux_swap_file}" created "
		else
			echo "ERROR!!! Unable to create swapfile "${linux_swap_file}""
		fi;
	elif  [ -e  ${linux_swap_file} ] && [ ${swap_file_en} -eq 1 ]; then
		LINUXSWAP_OFF;
	elif  [ -e  ${linux_swap_file} ] && [ ${swap_file_en} -eq 0 ]; then
		LINUXSWAP_OFF;
		echo Remove "${linux_swap_file}"
		rm ${linux_swap_file}
	fi;

}


LINUXSWAP_OFF()
{
	LINUX_SWAP_ON=$(cat /proc/swaps | grep ${linux_swap_partition} | wc -l);
	if [ $STATUS_CHK -eq 0 ] && [ ${LINUX_SWAP_ON} -eq 1 ]; then 
		swapoff ${linux_swap_partition};
		echo swapoff ${linux_swap_partition};
	fi;
}

# set linux swap
LINUXSWAP()
{
	if [ $STATUS_CHK -eq 1 ] && [ ${linux_swap_en} -eq 1 ]; then
		echo 
		echo === Linux Swap status ===
		for i in $linux_swap_pars;
		do
			USER_VAL=$(echo $i | awk -F"=" '{print $2}');
			USER_PAR=$(echo $i | awk -F"=" '{print $1}');
			if [ $USER_PAR == "linux_swap_partition" ]; then
				if [ ! -n ${USER_VAL} ]; then
					echo !!! Linux SWAP error :${USER_VAL} is not a device node;
				fi;
				LINUX_SWAP_ON=$(cat /proc/swaps | grep ${USER_VAL} | wc -l);
				if [ ${LINUX_SWAP_ON} -ne 1 ]; then 
					echo !!! Linux SWAP error: Linux swap is not enabled;
				else
					echo Linux SWAP enabled on ${USER_VAL}
				fi;
			fi;
		done
		
	elif [ ${linux_swap_en} -eq 1 ] && [ ${cc_backingswap_en} -eq 0 ];  then
		LINUXSWAP_OFF;
		
		if [ -n ${linux_swap_partition} ] && [ ${swap_file_en} -eq 0 ]; then
			echo mkswap ${linux_swap_partition};
			mkswap ${linux_swap_partition};
		fi;
		echo ${swappiness} > /proc/sys/vm/swappiness;
		echo swapon ${linux_swap_partition};
		swapon ${linux_swap_partition};
	elif [ ${linux_swap_en} -eq 0 ] ; then
		LINUXSWAP_OFF;
	fi;
}

# set virtual memory
SET_VM()
{
	if [ $STATUS_CHK -eq 1 ] && [ ${sys_vm_en} -eq 1 ]; then
		echo 
		echo === VM status ===
		for i in $sys_vm_pars;
		do
			USER_VAL=$(echo $i | awk -F"=" '{print $2}');
			USER_PAR=$(echo $i | awk -F"=" '{print $1}');
			if [ $USER_PAR == "page_cluster" ]; then USER_PAR=page-cluster; fi;
			SYS_VAL=`cat /proc/sys/vm/"$USER_PAR"`
			if [ $USER_VAL -ne "$SYS_VAL" ] || [ -z $SYS_VAL ]; then
				echo "ERROR!!! Set VM: $USER_PAR - "$SYS_VAL"(system) "$USER_VAL"(user)"
			else
				echo "Set VM: $USER_PAR - "$SYS_VAL"(system) "$USER_VAL"(user)"
			fi;
		done
		
	elif [ ${sys_vm_en} -eq 1 ] && [ ${sys_vm} -eq 1 ];
	then
		echo ${page_cluster} > /proc/sys/vm/page-cluster; 
		echo ${laptop_mode} > /proc/sys/vm/laptop_mode;
		echo ${dirty_expire_centisecs} > /proc/sys/vm/dirty_expire_centisecs;
		echo ${dirty_writeback_centisecs} > /proc/sys/vm/dirty_writeback_centisecs;
		echo ${dirty_background_ratio} > /proc/sys/vm/dirty_background_ratio; 
		echo ${dirty_ratio} > /proc/sys/vm/dirty_ratio;	
		echo ${vfs_cache_pressure} > /proc/sys/vm/vfs_cache_pressure;
		echo ${overcommit_ratio} > /proc/sys/vm/overcommit_ratio;
		echo ${overcommit_memory} > /proc/sys/vm/overcommit_memory;
		echo ${swappiness} > /proc/sys/vm/swappiness;
	fi;
}


SYS_INFO ()
{
	if [ ${DISP_SYS_INFO} -eq 1 ]; then
		echo
		echo === free ===
		free
		echo
		echo === swaps  ===
		cat /proc/swaps 
		echo
		echo === ${CC_STATUS_FLAG} ===
		${CC_STATUS_FLAG}
		echo
		echo === meminfo ===
		cat /proc/meminfo
		echo
		echo === VM configurations ===
		sysctl -a | grep vm
		exit 0;
	fi
	

}


USER_CMD()
{
	i=1;
	while [ $i -ne 0 ];
	do
		i=$((${i}+1));
		cmd=`echo $custom_shells_pars | cut -d "#" -f $i`
		if [ -z "$cmd" ]; then
			i=0;
		else 
			/bin/sh -c "$cmd"			
		fi;
	done
}

#main program
parse_args $*
GET_USER_CONF;
USER_CONF_CHECK;
SYS_INFO;

SWAPFILE_CHK;
COMPCACHE;
LINUXSWAP;
SET_VM;
USER_CMD;
if [ ${STATUS_CHK} -eq 0 ] && [ $renice -eq 1 ]; then
	renicerloop > /dev/null 2>&1 &
fi

exit 0;
