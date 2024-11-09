# GitLab server


## Description

Краткий [HowTo](https://ru.wikipedia.org/wiki/How-to) как установить GitLab server.


#### Contents

- [Omnibus package installation](#omnibus-package-installation)
	- [Конфигурация](#конфигурация)
- [Настройка Backup](#настройка-backup)
- [Настройка Rsync](#настройка-rsync)
- [Восстановление из BackUp](#восстановление-из-backup)

---



## Omnibus package installation

Для работы выбрана OS Ubunut Server 18.04.1 64 bit

Download:
 - [https://mirror.yandex.ru/ubuntu-releases/](https://mirror.yandex.ru/ubuntu-releases/)
 - [http://old-releases.ubuntu.com/releases/18.04.1/](http://old-releases.ubuntu.com/releases/18.04.1/)


1. Install and configure the necessary dependencies

```bash
sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
```

2. Add the GitLab package repository and install the package


```bash
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
```

```bash
sudo EXTERNAL_URL="http://10.30.1.210" apt-get install gitlab-ce
```

во время установки нужно будет ввести пароль для root-a GitLab-а (супер пользователь внутри GitLab, который будет создавать пользователей и выполнять админские штуки!)

* User: `root`
* Pass: `xxx`

**Новые версии GitLab-а изменили правила игры**: 
По умолчанию установка пакета Linux автоматически генерирует пароль для начальной учетной записи администратора (root) и сохраняет его в `/etc/gitlab/initial_root_password` не менее 24 часов.
В целях безопасности через 24 часа этот файл автоматически удаляется первым `gitlab-ctl reconfigure`.

Учетная запись по умолчанию привязана к случайно сгенерированному адресу электронной почты.
Чтобы переопределить это, передайте `GITLAB_ROOT_EMAIL` переменную окружения в команду установки.

```bash
sudo GITLAB_ROOT_EMAIL="gitlab_admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="http://10.30.1.210" apt install gitlab-ce
```

Если во время установки GitLab не выполнит автоматическую перенастройку, вам необходимо передать переменную `GITLAB_ROOT_PASSWORD` или `GITLAB_ROOT_EMAIL` при первом `gitlab-ctl reconfigure` запуске.

**Оба этих варианта временные**, используйте задание нового пароля root-а через WEB-UI.

Можно во время установки, указать нужную версию:

```bash
sudo apt install gitlab-ce=15.4.3-ce.0
```



## Конфигурация

Я хочу хранить репы и данные на RAID массиве!

##### 1. Перенос всех данных (`/var/opt/gitlab`) на RAID

Для этого через `mc` копируем директорию `/var/opt/gitlab` на рэйд(у меня: `/raid` итого получим `/raid/gitlab`), **с сохранением атрибутов файлов** (родитель/права и т.п, без этого могут быть проблемы)

```bash
sudo gitlab-ctl stop
sudo mc
```

Бэкап (перемещение) старой дириктории `/var/opt/gitlab/backups` на нашу `/raid/gitlab/backups` через симлинк:

```bash
cd /var/opt
sudo ln -s /raid/gitlab gitlab
```

Либо через конфиг:

```ini
gitlab_rails['backup_upload_connection'] = {
   :provider => 'Local',
   :local_root => '/raid/gitlab/backups'
 }
```

Проверка и старт:

```bash
sudo gitlab-ctl upgrade
sudo gitlab-ctl start
```

##### 2. E-Mail

Настройку почты просто смотрим в доке: [E-Mail](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/smtp.md)

> Note: Для Yandex почты нужно создать пароль для приложения! (Яндекс сгенерит новый пароль, его нужно прописывать в конфиг GitLab-а!). Безопасность-> Добавить Новое приложение -> ....

Для тестирования почты из gitlab-rails консоли выполните

```bash
gitlab-rails console
```

Команда, для отсылки письма на указанный адрес:
```bash
Notify.test_email('destination_email@address.com', 'Message Subject', 'Message Body').deliver_now

# для выхода из консоли gitlab-rails
quit
```


##### 3. Time Zone

`/etc/gitlab/gitlab.rb`

```ini
gitlab_rails['time_zone'] = 'Europe/Volgograd'
```

reconfigure and restart:

```bash
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```



## Настройка Backup

Для бэкапа будем использовать планировщик cron и скрипт: [gitlab_backup.sh](./gitlab_backup.sh)

Я также добавляю генерацию файлов с различной информацией о сервере [server_status.sh](./server_status.sh):


добавляем в `/etc/crontab`:

```bash
# gitlab service
0  2    * * 6   root    /raid/scripts/gitlab_backup.sh
0  */2  * * *   root    /raid/scripts/server_status.sh
```



## Настройка Rsync

Я хочу чтобы бэкапы и статусы заливались с сервера на мою машину, для этого будем использовать Rsync.

создание файла конфига
```bash
sudo nano /etc/rsyncd.conf
```


```ini
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

```bash
sudo systemctl status rsync.service
sudo systemctl start rsync.service
sudo systemctl enable rsync.service
sudo systemctl disable rsync.service
```


Настройка машины, на которую будут заливаться backup-ы. Для этого также будем использовать cron, добавляем задания синхронизации:


```bash
# GitLab
10 13	* * *	xxx     rsync -au --delete-after rsync@10.30.1.210::backups /home/xxx/Data/Backups/gitlab
10 */2	* * *	xxx     rsync -au --delete-after rsync@10.30.1.210::status  /home/xxx/Data/Backups/gitlab_status
```



## Восстановление из BackUp

Чтобы восстановить GitLab из backup-a, установите чистый GitLab такой же версии, какая у вас находится в backup-e.

Если версия GitLab и backup-a не совпадают, мы получим сообщение:

```bash
GitLab version mismatch:
  Your current GitLab version (16.5.0-ee) differs from the GitLab version in the backup!
  Please switch to the following version and try again:
  version: 16.4.3-ee
```

Конкретную версию GitLab-а можно скачать тут: https://packages.gitlab.com/gitlab/


Восстановите вручную файл `/etc/gitlab/gitlab-secrets.json` и конфиг `/etc/gitlab/gitlab.rb`

```bash
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

Файл backup-a должен быть в папке бэкапов, согласно конфига, если файл был скопирован, требуется изменить права для файла:

```bash
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /raid/gitlab/backups/
sudo chown git:git /raid/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

Теперь можно провести восстановление:

```bash
# остановка БД и бла бла бла
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status

# NOTE: "_gitlab_backup.tar" is omitted from the name
sudo gitlab-rake gitlab:backup:restore BACKUP=1493107454_2018_04_25_10.6.4-ce
```

Если восстановление прошло без ошибок, делаем рестарт и запускаем санитайзер:

```bash
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true

# Дополнительно проверяем артифакты и LFS файлы
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

Больше деталей можно найти в [GitLab docs](https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html)
