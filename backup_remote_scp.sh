#!/bin/bash

#script for copy backups from remote web server
#Rekunov Alexey
#ver. 20190604

#where is backups store?
STORE=/var/store
#LOG
LOG=./backup_remote.log
# path to run file
RUNFILE=/tmp/backup_remote.run

# backup_remote already running?
if test -e $RUNFILE
        then
                # if RUNFILE exist -> exit
                echo "Script already running!" >> $LOG
                echo "$(/bin/date) ##### End backup_remote script #####" >> $LOG
                exit
fi
# backup_remote already running. End

# create run file
touch $RUNFILE 2>>/dev/null
# create run file. End

### company.com ###

echo "$(/bin/date '+%H:%M:%S') company.com" >> $LOG

#local store
STORE1=$STORE/company.com/

#remote store
SRV1=company.com
#remote path with web backups
PATH1=/back/www
#remote path with sql backups
DBPATH1=/back/sql
#user for copy backups
USER1=user_name
PASS1=user_pass

#STORE1 exist?
if [ ! -e $STORE1 ]
then
        mkdir $STORE1 2>>$LOG
		echo "$(/bin/date '+%H:%M:%S') Папка $STORE1 создана." >> $LOG
fi

#copy site backups
scp $USER1@$SRV1:$PATH1/* $STORE1 1>>$LOG 2>>$LOG

#copy db backups
scp $USER1@$SRV1:$DBPATH1/* $STORE1 1>>$LOG 2>>$LOG

### company.com ###

# remove run file
rm -f $RUNFILE 2>>$LOG

