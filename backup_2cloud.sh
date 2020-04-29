#!/bin/bash

#script for copy backups to cloud
#uses s3cmd util
#Rekunov Alexey
#ver. 20190815

# where is backups store? (for s3cmd util)
S3STORE01=/store_tmp/01
S3STORE02=/store_tmp/02
# Bucket name
S3BUCKET01=storage01-cold-01
S3BUCKET02=storage02-cold-01

#CONF
CONF=./backup_2cloud.conf
S3CONF01=./.s3cfg-01
S3CONF02=./.s3cfg-02

#LOG
LOG=./backup_2cloud.log

# path to run file
RUNFILE=/tmp/backup_2cloud.run

# Format backup name
BTIME=$(/bin/date '+%Y%m%d')

echo "Start backup_2cloud script" >> $LOG

# backup_2cloud already running?
if test -e $RUNFILE
        then
                # if RUNFILE exist -> exit
                echo "Script already running!" >> $LOG
                echo "$(/bin/date) ##### End backup_2cloud script #####" >> $LOG
                exit
fi
# backup_2cloud already running. End

# create run file
touch $RUNFILE 2>>/dev/null
# create run file. End

# Copy files to temp store
while read line
do
	SRCPath=$( echo $line | cut -d : -f 1 -s)
	DSTPath=$( echo $line | cut -d : -f 2 -s)
	
	# SRCPath exist?
	if test ! -e $SRCPath
	then
		echo "Backup source not exist!" >> $LOG
	fi
	
	# DSTPath exist ?
	if test ! -e $DSTPath
	then
		mkdir -p $DSTPath 2 >> $LOG
	fi
	
	rsync -avr --del $SRCPath/ $DSTPath 1>>/dev/null 2>>$LOG

done < $CONF
# Copy files to temp store. End

# Prepare files
#find $STORE/* -maxdepth 0 -type d | xargs echo
while read line
do
	DSTPath=$( echo $line | cut -d : -f 2 -s)

	# Compress and crypt files
	echo "$(/bin/date) ##### Start compress files" >> $LOG
	7za a -t7z -mx=0 -mhe=on -p24453gjvld23r $DSTPath.7z $DSTPath 2>>$LOG
	if [ $? -eq 0 ]
	then
		# Delete source files
		echo "$(/bin/date) ##### Delete source $DSTPath" >> $LOG
		rm -rf $DSTPath 1 >> $LOG 2 >> $LOG
	else
		echo "$(/bin/date) ##### Compress ERROR!" >> $LOG
	fi
	echo "$(/bin/date) ##### End compress files" >> $LOG

done < $CONF
# Prepare files. End

# Move files to $BTIME format dir
if test -e $S3STORE01
then
	mkdir -p $S3STORE01/$BTIME 2>>$LOG
	mv $S3STORE01/*.7z $S3STORE01/$BTIME 2>>/dev/null
fi

if test -e $S3STORE02
then
	mkdir -p $S3STORE02/$BTIME 2>>$LOG
	mv $S3STORE02/*.7z $S3STORE02/$BTIME 2>>/dev/null
fi
# Move files to $BTIME format dir. End

# Delete old files from cloud
# First store
if [ -e $S3CONF01 ]
then
	if ls $S3STORE01/*.7z 1>/dev/null 2>&1
	then
		FNAME=$(s3cmd -c $S3CONF01 ls s3://$S3BUCKET01 | head -n 1 | cut -d '/' -f 4)
		echo "$(/bin/date) ##### Store01: delete old archive" >> $LOG
		s3cmd -c $S3CONF01 -r del s3://$S3BUCKET01/$FNAME 1>>$LOG 2>>$LOG
	fi
fi
# Second store
if [ -e $3CONF02 ]
then
	if ls $S3STORE02/*.7z 1>/dev/null 2>&1
	then
		FNAME=$(s3cmd -c $S3CONF02 ls s3://$S3BUCKET02 | head -n 1 | cut -d '/' -f 4)
		echo "$(/bin/date) ##### Store02: delete old archive" >> $LOG
		s3cmd -c $S3CONF02 -r del s3://$S3BUCKET02/$FNAME 1>>$LOG 2>>$LOG
	fi
fi
# Delete old files from cloud. End

# Copy files to cloud
# First store
if test -e $S3CONF01
then
	# Create dir $BTIME format
	echo "$(/bin/date) ##### Store01: begin transfer archive" >> $LOG
	s3cmd -c $S3CONF01 -r put $S3STORE01/$BTIME s3://$S3BUCKET01 2>>$LOG
	# If s3cmd result done, delete local files
	if [ $? -eq 0 ]
	then
		rm -rf $S3STORE01/$BTIME 2>>$LOG
	fi
	echo "$(/bin/date) ##### Store01: finish transfer archive" >> $LOG
	
else
	echo "$(/bin/date) ##### $S3CONF01 not exist" >> $LOG
fi

# Second store
if test -e $S3CONF02
then
	# Create dir $BTIME format
	echo "$(/bin/date) ##### Store02: begin transfer archive" >> $LOG
	s3cmd -c $S3CONF02 -r put $S3STORE02/$BTIME s3://$S3BUCKET02 2>>$LOG
	# If s3cmd result done, delete local files
	if [ $? -eq 0 ]
	then
		rm -rf $S3STORE02/$BTIME 2>>$LOG
	fi
	echo "$(/bin/date) ##### Store02: finish transfer archive" >> $LOG
else
	echo "$(/bin/date) ##### $S3CONF02 not exist" >> $LOG
fi
# Copy files to cloud. End

echo "$(/bin/date) ##### End script" >> $LOG
echo "$(/bin/date) ####################################" >> $LOG
echo "$(/bin/date) ####################################" >> $LOG

# remove run file
rm -f $RUNFILE 2>>$LOG
