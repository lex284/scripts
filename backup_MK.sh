#!/bin/bash

# script for backup Mikrotik routers
# Get backup files and export config from router
# Rekunov Alexey
# ver. 20170725

# router's list
RLIST=backup_MK.list

# where is backup store?
STORE=/store/

# LOG
LOG=backup_MK.log

# Time format for file name
# 20170725-145513
BTIME=$(/bin/date '+%Y%m%d-%H%M%S')

# User (ssh key needed)
USER=backbot

# path for run file
RUNFILE=/tmp/backup_MK.run

echo "$(/bin/date) ##### Start backup_MK script #####" >> $LOG

# backup_MK already running?
# if RUNFILE exist -> exit
if test -e $RUNFILE
then
	echo "$(/bin/date) Script already running!" >> $LOG
	echo "$(/bin/date) ##### End backup_MK script #####" >> $LOG
	exit
fi
# backup_MK already running. End

# create run file
touch $RUNFILE 2>>$LOG
# create run file. End

# router list is lost
if test ! -e $RLIST
then
	echo "$(/bin/date) Router list ($RLIST) is lost!" >> $LOG
	echo "$(/bin/date) ##### Exit #####" >> $LOG
fi
# router list is lost. End

# create backup store dirs
if test ! -e $STORE/$BTIME
then
	mkdir -p $STORE/$BTIME 1>>$LOG 2>>$LOG
	echo "$(/bin/date) Create dir for backups" >> $LOG
fi
# create backup store dirs. End

# backup routers
while read line
do
	# router ip
	LIST_RIP=$( echo $line | cut -d : -f 1 -s )
	# router name
	LIST_RNAME=$( echo $line | cut -d : -f 2 -s )

	# router identity
	RNAME="$( ssh -n $USER@$LIST_RIP '/system identity export' | grep 'name' | cut -d '=' -f 2 | tr -d '\n' | tr -d '\r' )" 2>>$LOG

	# backup configuration
	echo "$(/bin/date) Backup configuration - $RNAME" >> $LOG
	BACKNAME=${RNAME}_${BTIME}
	ssh -n $USER@$LIST_RIP /system backup save dont-encrypt=yes name=$BACKNAME 1>>$LOG 2>>$LOG

	# export configuration
	echo "$(/bin/date) Export configuration - $RNAME" >> $LOG
	ssh -n $USER@$LIST_RIP /export file=$BACKNAME 1>>$LOG 2>>$LOG

	# copy backup to store
	scp $USER@$LIST_RIP:/$BACKNAME.backup $STORE/$BTIME 1>>$LOG 2>>$LOG
	scp $USER@$LIST_RIP:/$BACKNAME.rsc $STORE/$BTIME 1>>$LOG 2>>$LOG

done < $RLIST
# backup routers. End

# remove run file
rm -f $RUNFILE 2>>$LOG

echo "$(/bin/date) ##### End backup_MK script #####" >> $LOG
echo "$(/bin/date) ################################" >> $LOG