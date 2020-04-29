#!/bin/bash

# Скрипт для копирования бэкапов с другого сервера через rsync
# Rekunov Alexey. 2015-12-22

# Имя лога
LOG=/root/backup.log
echo "---------- $(/bin/date) ----------" >> $LOG

# Куда будут складываться архивы
STOREtmp0=/store/
# Куда монтироуем
STOREtmp1=/tmp/storetmp1/
# Откуда забираем бэкапы
STOREsmb0=//serverbackup/backups/
#Данные для подключения к серверу
USERsmb=user_name
PASSsmb=user_pass
# path to run file
RUNFILE=/tmp/backup.run

# script already running?
if test -e $RUNFILE
        then
                # if RUNFILE exist -> exit
                echo "Script already running!" >> $LOG
                echo "$(/bin/date) ##### End script #####" >> $LOG
                exit
fi

# create run file
touch $RUNFILE 2>>/dev/null

# Проверяем есть ли папка $STOREtmp0
if test -e $STOREtmp0
then
        echo "$(/bin/date '+%H:%M:%S') Папка $STOREtmp0 найдена." >> $LOG
else
        mkdir $STOREtmp0 2>>$LOG
	echo "$(/bin/date '+%H:%M:%S') Папка $STOREtmp0 создана." >> $LOG
fi

# Проверяем есть ли папка $STOREtmp1 (временная)
if test -e $STOREtmp1
then
        echo "$(/bin/date '+%H:%M:%S') Папка $STOREtmp1 найдена." >> $LOG
else
        mkdir $STOREtmp1 2>>$LOG
        echo "$(/bin/date '+%H:%M:%S') Папка $STOREtmp1 создана." >>$LOG
fi

# Монтируем шару удаленного сервера (read only)
if test -e $STOREtmp0
then
	/sbin/mount.cifs $STOREsmb0 $STOREtmp1 -o ro,iocharset=utf8,user=$USERsmb,password=$PASSsmb,dom=DOMAIN.LOCAL 2>>$LOG
	echo "$(/bin/date '+%H:%M:%S') Папка $STOREsmb0 смонтирована." >> $LOG
else
	echo "$(/bin/date '+%H:%M:%S') Папка $STOREsmb0 не смонтирована!" >> $LOG
	echo "$(/bin/date '+%H:%M:%S') Скрипт завершен с ошибкой!!" >> $LOG
	return 1
fi

# Копируем бэкапы в $STOREtmp0
echo "$(/bin/date '+%H:%M:%S') Копирование бэкапов из $STOREsmb0 в $STOREtmp0." >> $LOG
rsync -av --bwlimit=5120 --delete $STOREtmp1 $STOREtmp0 1>>$LOG 2>>$LOG
echo "$(/bin/date '+%H:%M:%S') Завершено." >> $LOG

# Отмонтируем папку
umount $STOREtmp1 2>>$LOG

# remove run file
rm -f $RUNFILE 1>>$LOG 2>>$LOG

echo "$(/bin/date '+%H:%M:%S') Резервное копирование завершено." >> $LOG
echo "++++++++++ $(/bin/date) ++++++++++" >> $LOG
