#!/bin/sh

SAVE_DIR=/raid/status
TIME_STAMP=$(date "+%Y.%m.%d-%H_%M")
FILE_PREFIX=$SAVE_DIR/$TIME_STAMP

#RAID
RAID_STATUS_FILE="$FILE_PREFIX"_raid.txt
cat /proc/mdstat > $RAID_STATUS_FILE
echo "\n\n ---- detail ----\n\n" >> $RAID_STATUS_FILE
mdadm --detail /dev/md0 >> $RAID_STATUS_FILE


#Disk Size
DISK_STATUS_FILE="$FILE_PREFIX"_disk.txt
df -h > $DISK_STATUS_FILE

echo "\n\n ---- raid ----\n\n" >> $DISK_STATUS_FILE
du -h -d1 /raid/ >> $DISK_STATUS_FILE

echo "\n\n ---- ssd ----\n\n" >> $DISK_STATUS_FILE
du -h -d1 / >> $DISK_STATUS_FILE


#Top
TOP_STATUS_FILE="$FILE_PREFIX"_top.txt
top -b -n 1 > $TOP_STATUS_FILE


#GitLab
GITLAB_STATUS_FILE="$FILE_PREFIX"_gitlab.txt
sudo gitlab-ctl status > $GITLAB_STATUS_FILE


# Удаляем все кроме последних 12  файлов (сутки статистики (каждые 2 часа))!
ls -t1 $SAVE_DIR/*raid.txt   | tail -n +13 | xargs rm -r 2>/dev/null
ls -t1 $SAVE_DIR/*disk.txt   | tail -n +13 | xargs rm -r 2>/dev/null
ls -t1 $SAVE_DIR/*top.txt    | tail -n +13 | xargs rm -r 2>/dev/null
ls -t1 $SAVE_DIR/*gitlab.txt | tail -n +13 | xargs rm -r 2>/dev/null
