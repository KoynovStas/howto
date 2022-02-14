#!/bin/sh

BACKUP_DIR=/raid/gitlab/backups


COUNT_FILES=3

# Удаляем все кроме последних COUNT_FILES-1 файлов
ls -t1 $BACKUP_DIR/*_config.tar     | tail -n +$COUNT_FILES | xargs rm -r 2>/dev/null
ls -t1 $BACKUP_DIR/*_backup.tar     | tail -n +$COUNT_FILES | xargs rm -r 2>/dev/null
ls -t1 $BACKUP_DIR/*_config.tar.md5 | tail -n +$COUNT_FILES | xargs rm -r 2>/dev/null
ls -t1 $BACKUP_DIR/*_backup.tar.md5 | tail -n +$COUNT_FILES | xargs rm -r 2>/dev/null

tar -cf $BACKUP_DIR/$(date "+%Y.%m.%d-%H_%M_gitlab_config.tar")  /etc/gitlab/*
gitlab-rake gitlab:backup:create CRON=1


# calculate md5
cd $BACKUP_DIR
for file in *.tar
do
    if [ ! -f $file.md5 ]
        then  md5sum $file > $file.md5
    fi
done
