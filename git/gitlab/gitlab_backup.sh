#!/bin/sh

BACKUP_DIR=/raid/gitlab/backups

# Удаляем все кроме последних файлов
ls -t1 $BACKUP_DIR/*_config.tar | tail -n +2 | xargs rm -r 2>/dev/null
ls -t1 $BACKUP_DIR/*_backup.tar | tail -n +2 | xargs rm -r 2>/dev/null


tar -cf $BACKUP_DIR/$(date "+%Y.%m.%d-%H_%M_gitlab_config.tar")  /etc/gitlab/*
gitlab-rake gitlab:backup:create CRON=1
