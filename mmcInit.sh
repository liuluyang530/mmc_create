#########################################################################
# File Name: mmcInit.sh
# Author: yangyang.liu
# mail: yangyang.liu@hxgpt.com
# Created Time: 2019年09月20日 星期五 14时44分26秒
#########################################################################
#!/bin/bash
DEBUG=0
PC=1

print_log(){
	echo "$1" >>/tmp/mmcDisk.log
	#echo "$1" 
}

##################################
#
#
#return: 1,success 0,failed
############################
getConfOption() {
EMMC1_BASE_NAME="variableEmmc1BaseName"
EMMC2_BASE_NAME="variableEmmc2BaseName"
EMMC3_BASE_NAME="variableEmmc3BaseName"
EMMC_BOOT_BASE_NAME="variableBootBaseName"
echo "----------------" > mmcDisk.log
if [ -f $confFile ]
then
	confForceFormat=`cat $confFile | awk '/FORCE_FORMAT/ {print $3}'`
	confEmmcSize=`cat $confFile | awk '/EMMC_SIZE/ {print $3}'`
	#mmc_NAME          = sdb
	confPartitionCountMax=`cat $confFile | awk '/PARTITION_COUNT_MAX/ {print $3}'`
	confPartitionCount=`cat $confFile | awk '/PARTITION_COUNT_ALL/ {print $3}'`
	confEmmcMountDir1=`cat $confFile | awk '/EMMC_MOUNT_DIR_1/ {print $3}'`
	confEmmcMountDir2=`cat $confFile | awk '/EMMC_MOUNT_DIR_2/ {print $3}'`
	confEmmcMountDir3=`cat $confFile | awk '/EMMC_MOUNT_DIR_3/ {print $3}'`
	confEmmcMountDir4=`cat $confFile | awk '/EMMC_MOUNT_DIR_4/ {print $3}'`
	confPartitionSize1=`cat $confFile | awk '/PARTITION_SIZE_1/ {print $3}'`
	confPartitionSize2=`cat $confFile | awk '/PARTITION_SIZE_2/ {print $3}'`
	confPartitionSize3=`cat $confFile | awk '/PARTITION_SIZE_3/ {print $3}'`
	confPartitionSize4=`cat $confFile | awk '/PARTITION_SIZE_4/ {print $3}'`
	confPartitionStartSector=`cat $confFile | awk '/PARTITION_START_SECTOR/ {print $3}'`

	confBootDirCount=`cat $confFile | awk '/EMMC_BOOT_DIR_COUNT/ {print $3}'`
	if [ $confBootDirCount -ge 1 ]
	then
	tempCount=1
	while [ $tempCount -le $confBootDirCount ]
	do
		tempCCount=`expr $tempCount + 2`
		tempName="$""$tempCCount"
		#echo "tempName=$tempName"
		tempDir=`cat $confFile | awk '/EMMC_BOOT_DIR_NAME/ { print '$tempName' }'`
		#echo "tempDir=$tempDir"
		eval $EMMC_BOOT_BASE_NAME$tempCount=$tempDir
		#echo variableBootBaseName$tempCount
		#$EMMC_BOOT_BASE_NAME$tempCount=$tempDir
		tempCount=`expr $tempCount + 1`
	done
	fi

	confGptLogo=`cat $confFile | awk '/GPT_LOGO/ {print $3}'`
	confGptKernel=`cat $confFile | awk '/GPT_KERNEL/ {print $3}'`
	confGptSystem=`cat $confFile | awk '/GPT_SYSTEM/ {print $3}'`

	return 1
else
	echo " read $confFile is error"
	return 0
fi

}



##################################
#
#
#
############################
getDiskInfo() {
if [ $PC -eq 0 ] 
then
deviceName=`fdisk -l | awk '$2~/dev\/mmcblk[0-9]:/ {print $2}' | awk -F: '{print $1}'`
#deviceName="/dev/mmcblk0"
diskSize=`fdisk -l $deviceName | awk '$4~/GiB/ {print $3}' | awk -F. '{print $1}'`
sectorsAll=`fdisk -l $deviceName | awk '$8~/sectors/ {print $7}'`
cylindersAll=`fdisk -l $deviceName | awk '$6~/cylinders/ {print $5}'`
headsAll=`fdisk -l $deviceName | awk '$2~/heads/ {print $1}'`
perSectorSize=`fdisk -l $deviceName | awk '$3~/logical/ {print $4}'`
else
deviceName="/dev/mmcblk0"
diskSize=`fdisk -l /dev/mmcblk0 | awk '$3~/GiB/ {print $2}' | awk -F： '{print $2}'`
if [ -z "$diskSize" ];then
	diskSize=`fdisk -l $deviceName | awk '$4~/GiB/ {print $3}' | awk -F. '{print $1}'`
fi
sectorsAll=`fdisk -l $deviceName |grep Disk |awk -F ， '{print $3}' | awk -F " " '{print $1}'`
if [ -z "$sectorsAll" ];then
	sectorsAll=`fdisk -l $deviceName | awk '$8~/sectors/ {print $7}'`
fi
cylindersAll=`fdisk -l $deviceName | awk '$6~/cylinders/ {print $5}'`
headsAll=`fdisk -l $deviceName | awk '$2~/heads/ {print $1}'`
perSectorSize=`fdisk -l $deviceName | awk '$1~/单元/ {print $5}'`
if [ -z "$perSectorSize" ];then
	perSectorSize=`fdisk -l $deviceName | awk '$3~/logical/ {print $4}'`
fi
fi

echo "deviceName=$deviceName  diskSize=$diskSize sectorsAll=$sectorsAll cylindersAll=$cylindersAll headsAll=$headsAll perSectorSize=$perSectorSize">> mmcDisk.log

if [ -z "$deviceName" ]
then
	return 0
fi

#if [ $diskSize -lt 7 ]
#then
#	return 0
#fi

if [ -z "$sectorsAll" ]
then
	return 0
fi

#if [ -z "$cylindersAll" ]
#then
#	return 0
#fi

#if [ -z "$headsAll" ]
#then
#	return 0
#fi

if [ -z "$perSectorSize" ]
then
	return 0
fi


return 1
#echo "1"

}

##################################
#
#
#
############################
CalculationPartationSectorInfo(){

if [ $confPartitionCount -gt $confPartitionCountMax ]
then
	return 0
fi

calcPartition1SectorCount=`expr $confPartitionSize1 \* 1024 \* 1024  / $perSectorSize`
#echo "calcPartition1SectorCount=$calcPartition1SectorCount"
calcPartition2SectorCount=`expr $confPartitionSize2 \* 1024 \* 1024  / $perSectorSize`
#echo "calcPartition2SectorCount=$calcPartition2SectorCount"
calcPartition3SectorCount=`expr $confPartitionSize3 \* 1024 \* 1024  / $perSectorSize`
#echo "calcPartition3SectorCount=$calcPartition3SectorCount"
calcPartition4SectorCount=`expr $confPartitionSize4 \* 1024 \* 1024  / $perSectorSize`
#echo "calcPartition4SectorCount=$calcPartition4SectorCount"

calcPart1sectorStart=$confPartitionStartSector
#echo "calcPart1sectorStart=$calcPart1sectorStart"
calcPart1sectorEnd=`expr $calcPart1sectorStart + $calcPartition1SectorCount - 1`
#echo "calcPart1sectorEnd=$calcPart1sectorEnd"
calcPart2sectorStart=`expr $calcPart1sectorEnd + 1`
#echo "calcPart2sectorStart=$calcPart2sectorStart"
calcPart2sectorEnd=`expr $calcPart2sectorStart + $calcPartition2SectorCount - 1`
#echo "calcPart2sectorEnd=$calcPart2sectorEnd"
calcPart3sectorStart=`expr $calcPart2sectorEnd + 1`
#echo "calcPart3sectorStart=$calcPart3sectorStart"
calcPart3sectorEnd=`expr $calcPart3sectorStart + $calcPartition3SectorCount - 1`
#echo "calcPart3sectorEnd=$calcPart3sectorEnd"
calcPart4sectorStart=`expr $calcPart3sectorEnd + 1`
#echo "calcPart4sectorStart=$calcPart4sectorStart"
calcPart4sectorEnd=`expr $calcPart4sectorStart + $calcPartition4SectorCount - 1`
if [ $calcPart4sectorEnd -gt $sectorsAll ] 
then
    calcPart4sectorEnd=`expr $sectorsAll - 1`
fi
#echo "calcPart4sectorEnd=$calcPart4sectorEnd"
return 1
}


fdiskCreate1P() {
fdisk $deviceName<<EOF
n
p
1
$calcPart1sectorStart
$calcPart1sectorEnd
w
EOF

}

fdiskCreate2P() {
fdisk $deviceName<<EOF
n
p
1
$calcPart1sectorStart
$calcPart1sectorEnd
n
p
2
$calcPart2sectorStart
$calcPart2sectorEnd
w
EOF

}

fdiskCreate3P() {
fdisk $deviceName<<EOF
n
p
1
$calcPart1sectorStart
$calcPart1sectorEnd
n
p
2
$calcPart2sectorStart
$calcPart2sectorEnd
n
p
3
$calcPart3sectorStart
$calcPart3sectorEnd
w
EOF

}

if [ 1 -eq 1 ]; then
fdiskCreate4P() {
fdisk $deviceName<<EOF
n
p
1
$calcPart1sectorStart
$calcPart1sectorEnd

n
p
2
$calcPart2sectorStart
$calcPart2sectorEnd

n
p
3
$calcPart3sectorStart
$calcPart3sectorEnd

n
p
4
$calcPart4sectorStart
$calcPart4sectorEnd

w
EOF

}
else
fdiskCreate4P() {
fdisk $deviceName<<EOF
n
1
$calcPart1sectorStart
$calcPart1sectorEnd

n
2
$calcPart2sectorStart
$calcPart2sectorEnd

n
3
$calcPart3sectorStart
$calcPart3sectorEnd

n
4
$calcPart4sectorStart
$calcPart4sectorEnd

w
EOF

}
fi

##################################
#
#
#
############################
fdiskCreate(){
case $confPartitionCount in
	1)
	if [ $calcPart1sectorEnd -gt $sectorsAll ]
	then
	calcPart1sectorEnd=`expr $sectorsAll - 1`
	fi 
	fdiskCreate1P 
	;;
	2) 
	if [ $calcPart2sectorEnd -gt $sectorsAll ]
	then
	calcPart2sectorEnd=`expr $sectorsAll - 1`
	fi 
	fdiskCreate2P 
	;;
	3) 
	if [ $calcPart3sectorEnd -gt $sectorsAll ]
	then
	calcPart3sectorEnd=`expr $sectorsAll - 1`
	fi 
	fdiskCreate3P 
	;;
	4) 
	if [ $calcPart4sectorEnd -gt $sectorsAll ]
	then
	calcPart4sectorEnd=`expr $sectorsAll - 1`
	fi 
	fdiskCreate4P 
	;;
	*) echo " confPartitionCount=$confPartitionCount is error  ./EmmcDiskInit create|del|info" >> mmcDisk.log ;;
esac
	sync
	sleep 1
}


##################################################
#
###################################################
fdiskDelOne() {
fdisk $deviceName<<EOF
d
w
EOF
}

fdiskDelTwo() {
fdisk $deviceName<<EOF
d
1
d
w
EOF
}

fdiskDelThree() {
fdisk $deviceName<<EOF
d
1
d
2
d
w
EOF
}

fdiskDelFour() {
fdisk $deviceName<<EOF
d
1
d
2
d
3
d
w
EOF
}

fdiskDelFive() {
fdisk $deviceName<<EOF
d
1
d
2
d
3
d
4
d
w
EOF
}

##################################
#
#
#
############################
fdiskDel() {
partitionCount=`fdisk -l $deviceName | awk '{if($1~/dev\/mmcblk[0-9]/) print $1}' | wc -l`

if [ $partitionCount -lt 1 ]
then
	echo "disk is empty">>mmcDisk.log
	return 0
fi
	umount ${deviceName}*
	
case $partitionCount in
	1)
	fdiskDelOne 
	;;
	2) fdiskDelTwo ;;
	3) fdiskDelThree ;;
	4) fdiskDelFour ;;
	*) echo " partition count $partitionCount > 4" >>mmcDisk.log
esac
	# destroy the partition table
	dd if=/dev/zero of=${deviceName} bs=512 count=2
	sync
	partprobe
return 1

}


##################################
#
#
#
############################
mkfsExt4(){
local tempCount=1
local mmcMountDir="/mnt"
fdisk -l $deviceName | awk '{if($1~/dev\/mmcblk[0-9]/) print $1}' | while read line
do
	echo $line >>mmcDisk.log
	if [ ! -d $mmcMountDir ]; then
		mkdir -p $mmcMountDir
	fi
	mount $line $mmcMountDir
	if [ $? -ne 0 ]; then
		mount -t squashfs $line $mmcMountDir
		if [ $? -ne 0 ]; then
			echo "mkfsExt4 $line"
			if [ $PC -eq 0 ]; then
			mkfs.ext2 $line
			else
			mkfs.ext4 $line
			fi
			sync
		else
			echo "[SUCCESS]** [$line] ** partation is ok!!!"
			sudo umount -vf $line
		fi
	else
		echo "[SUCCESS]** [$line] ** partation is ok!!!"
		sudo umount -vf $line
	fi
	sleep 1
done

return 1

}

mkBootDir(){
    local tempCount=1
	if [ ! -d "$confEmmcMountDir1" ]; then
		mkdir -p $confEmmcMountDir1
	fi

    mount $deviceName"p1" $confEmmcMountDir1
    if [ $confBootDirCount -gt 1 ]; then
	while [ $tempCount -le $confBootDirCount ]
	do
		tempDir1=`eval echo '$'$EMMC_BOOT_BASE_NAME$tempCount`
		tempDir=$confEmmcMountDir1$tempDir1
		#echo "tempDir=$tempDir"
		if [ ! -d "$tempDir" ]; then
			echo "mkdir $tempDir."
			mkdir -p $tempDir
		fi
		tempCount=`expr $tempCount + 1`
	done
    fi

	if [ ! -z "$confGptKernel" ];then
		echo "[UPDATE] $confGptKernel to $confEmmcMountDir1..."
		cp -rf $confGptKernel $confEmmcMountDir1
	fi
    umount -vf $deviceName"p1"
	
	if [ ! -d "$confEmmcMountDir2" ]; then
		mkdir -p $confEmmcMountDir2
	fi
	mount $deviceName"p2" $confEmmcMountDir2
	if [ ! -z "$confGptSystem" ];then
		echo "[UPDATE] $confGptSystem to $confEmmcMountDir2..."
		tar -zxf $confGptSystem -C $confEmmcMountDir2
	fi
	sync
	umount -vf $deviceName"p2"
}

fsckPart(){
local mmcMountDir="/mnt"
fdisk -l $deviceName | awk '{if($1~/dev\/mmcblk[0-9]/) print $1}' | while read line
do
	echo $line >>mmcDisk.log
	if [ ! -d $mmcMountDir ]; then
		mkdir -p $mmcMountDir
	fi
	mount $line $mmcMountDir
	if [ "$?" -ne 0 ]; then
		mount -t squashfs $line $mmcMountDir
		if [ "$?" -ne 0 ]; then
			echo "fsck $line"
			e2fsck -v -p $line >> mmcDisk.log
			if [ "$?" -ne 0 ]; then
				e2fsck -y -v -f -c $line
			fi
			sync
		else
			umount -vf $line
		fi
	else
		umount -vf $line
	fi
done
}



##################################
#
#  start!!!
#
############################
#1. judge argument.
if [ $# -ne 1 ]; then
	echo "usage: ./mmcInit.sh create|del|info"
	exit 0
elif [ $1 != "create" -a $1 != "del" -a $1 != "info" ]; then
	echo "usage: ./mmcInit.sh create|del|info"
	exit 0
fi

# check the if root?
userid=`id -u`
if [ $userid -ne "0" ]; then
  echo "you're not root?"
#  exit
fi


if [ `uname -a |grep Polaris | wc -l` -eq 1 ]; then
    PC=0
else
    PC=1
fi

#2. include config file.
if [ $PC -eq 1 ]; then
	confFile=$PWD/mmcDisk.conf
else
	confFile=/etc/mmcDisk.conf
fi

#3. fuction check disk exit and read info
getDiskInfo
if [ $? -ne 1 ]; then
	exit 0
fi

#4. fuction read config file information.
getConfOption
if [ $? -ne 1 ]; then
	exit 0
fi

#5. fuction calculation sector info, must after function's getDiskInfo
CalculationPartationSectorInfo
if [  $? -ne 1 ]; then
	exit 0
fi

if [ $confForceFormat -eq 1 ]
then
	fdiskDel
fi

# main process program
case $1 in
	"create")
	partitionCount=`fdisk -l $deviceName | awk '{if($1~/dev\/mmcblk[0-9]/) print $1}' | wc -l`
	if [ $partitionCount -le 1 ]; then
		fdiskDel
		fdiskCreate
		mkfsExt4
		fsckPart
		mkBootDir
		#mountEmmc
		echo "[SUCCESS] --- mmc init done."
	elif [ $partitionCount -eq $confPartitionCount ]; then
		print_log "The hard disk is ok."
		fsckPart
		#fdiskDel
		mkBootDir
		#mountEmmc		
	else
		print_log "The hard disk is damaged, please format it."
		if [ $confForceFormat -eq 1 ]
		then
			fdiskDel
			fdiskCreate
			mkfsExt4
		fi

		fsckPart
		#fdiskDel
	fi
	;;
	"del")  fdiskDel ;;
	"info") getDiskInfo ;;
	*) print_log " $1 is error  ./EmmcDiskInit create|del|info";;
esac

#remount with read only.
#/bin/mount -o remount,ro /

#debug message.....
if [ $DEBUG -eq 1 ]; then
echo ">>>>>>>>>>>>>>>>>>>>>>debug start"
echo "confForceFormat=$confForceFormat confEmmcSize=$confEmmcSize confPartitionCountMax=$confPartitionCountMax confPartitionCount=$confPartitionCount confEmmcMountDir1=$confEmmcMountDir1 confEmmcMountDir2=$confEmmcMountDir2 confEmmcMountDir3=$confEmmcMountDir3 confEmmcMountDir4=$confEmmcMountDir4 confPartitionSize1=$confPartitionSize1 confPartitionSize2=$confPartitionSize2 confPartitionSize3=$confPartitionSize3 confPartitionStartSector=$confPartitionStartSector confEmmc1DirCount=$confEmmc1DirCount"
echo "deviceName=$deviceName  diskSize=$diskSize sectorsAll=$sectorsAll cylindersAll=$cylindersAll headsAll=$headsAll perSectorSize=$perSectorSize"
echo "calcPartition1SectorCount=$calcPartition1SectorCount calcPartition2SectorCount=$calcPartition2SectorCount calcPartition3SectorCount=$calcPartition3SectorCount calcPartition4SectorCount=$calcPartition4SectorCount"
echo "calcPart1sectorStart=$calcPart1sectorStart calcPart1sectorEnd=$calcPart1sectorEnd "
echo "calcPart2sectorStart=$calcPart2sectorStart calcPart2sectorEnd=$calcPart2sectorEnd "
echo "calcPart3sectorStart=$calcPart3sectorStart calcPart3sectorEnd=$calcPart3sectorEnd "
echo "calcPart4sectorStart=$calcPart4sectorStart calcPart4sectorEnd=$calcPart4sectorEnd "
fi

exit 0

