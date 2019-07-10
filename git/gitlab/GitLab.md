# GitLab server


## Description

Краткий [HowTo](https://ru.wikipedia.org/wiki/How-to) как установить GitLab server.


#### Contents

- [Omnibus package installation](#omnibus-package-installation)
	- [Конфигурация](#конфигурация)
- [Настройка Backup](#настройка-backup)
- [Настройка Rsync](#настройка-rsync)


---



## Omnibus package installation

Для работы выбрана OS Ubunut Server 18.04.1 64 bit

Download:  [https://www.ubuntu.com/download/server](https://www.ubuntu.com/download/server)


1. Install and configure the necessary dependencies

```console
sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates
```

2. Add the GitLab package repository and install the package


```console
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
```

```console
sudo EXTERNAL_URL="http://10.30.1.210" apt-get install gitlab-ce
```

во время установки нужно будет ввести пароль для root-a GitLab-а (супер пользователь внутри GitLab, который будет создавать пользователей и выполнять админские штуки!)

* User: `root`
* Pass: `xxx`


## Конфигурация

Я хочу хранить репы и данные на RAID массиве!

1. Перенос всех данных (`/var/opt/gitlab`) на RAID

Для этого через `mc` копируем директорию `/var/opt/gitlab` на рэйд, **с сохранением атрибутов файлов** (родитель/права и т.п)

```console
sudo gitlab-ctl stop
sudo mc
```

Бэкап (перемещение) старой дириктории в `/var/opt/gitlab_backup`

Создание симлинка:

```console
cd /var/opt
sudo ln -s /raid/gitlab gitlab
```


Проверка и старт:

```console
sudo gitlab-ctl upgrade
sudo gitlab-ctl start
```

2. E-Mail

Настройку почты просто смотрим в доке: [E-Mail](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/smtp.md)



3. Time Zone

`/etc/gitlab/gitlab.rb`

```console
gitlab_rails['time_zone'] = 'Europe/Volgograd'
```

reconfigure and restart:

```console
gitlab-ctl reconfigure gitlab-ctl restart
```


## Настройка Backup

Для бэкапа будем использовать планировщик cron и скрипт: [gitlab_backup.sh](./gitlab_backup.sh)

Я также добавляю генерацию файлов с различной информацией о сервере [server_status.sh](./server_status.sh):


добавляем в `/etc/crontab`:

```console
# gitlab service
0  2    * * 6   root    /raid/scripts/gitlab_backup.sh
0  */2  * * *   root    /raid/scripts/server_status.sh
```


## Настройка Rsync

Я хочу чтобы бэкапы и статусы заливались с сервера на мою машину, для этого будет использовать Rsync.

создание файла конфига
```console
sudo nano /etc/rsyncd.conf
```


```console
# rsyncd.conf - Example file, see rsyncd.conf(5)

# Set this if you want to stop rsync daemon with rc.d scripts
pid file = /var/run/rsyncd.pid

# Указываем файл для логов
log file = /var/log/rsyncd.log

# Выключаем логирование передаваемых файлов
transfer logging = no

max connections = 2
exclude = lost+found/
dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2 *.rar *.7z *.mp3 *.jpg


[backups]
path = /raid/gitlab/backups
comment = GitLab BackUp
read only = true
list = true
uid = root
gid = root
hosts allow = localhost 10.30.1.90
hosts deny = *


[status]
path = /raid/status
comment = Server status
read only = true
list = true
hosts allow = localhost 10.30.1.90
hosts deny = *
```


Управление:

```console
sudo systemctl status rsync.service
sudo systemctl start rsync.service
sudo systemctl enable rsync.service
sudo systemctl disable rsync.service
```


Настройка машины, на которую будут заливаться backup-ы. Для этого также будем использовать cron, добавляем задания синхронизации:


```console
# GitLab
10 13	* * *	xxx     rsync -au --delete-after rsync@10.30.1.210::backups /home/xxx/Data/Backups/gitlab
10 */2	* * *	xxx     rsync -au --delete-after rsync@10.30.1.210::status  /home/xxx/Data/Backups/gitlab/status
```
