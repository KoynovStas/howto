# FTP-server vsftpd


## Description

Краткий HowTo как установить FTP-сервер [vsftpd](https://vsftpd.devnet.ru/rus/) на Ubuntu


#### Contents

- [Установка vsftpd](#установка-vsftpd)
- [Настройка vsftpd](#настройка-vsftpd)
    - [Параметры IPv4 IPv6](#параметры-ipv4-ipv6)
    - [Анонимный доступ](#анонимный-доступ)
    - [Ограничение доступа](#ограничение-доступа)
    - [Общие настройки](#общие-настройки)
    - [SSL-сертификат](#ssl-сертификат)
- [Links](#links)



---



Ubuntu поддерживает различные FTP сервера, мы рассмотрим [vsftpd](https://vsftpd.devnet.ru/rus/)


### Установка vsftpd

Чтобы установить на Ubuntu:

```console
sudo apt install vsftpd
```

Проверьте работоспособность сервера:

```console
sudo systemctl status vsftpd
```

Управление через systemctl:

```console
sudo systemctl status  vsftpd
sudo systemctl start   vsftpd
sudo systemctl stop    vsftpd
sudo systemctl restart vsftpd
sudo systemctl enable  vsftpd
sudo systemctl disable vsftpd
```

Более детально см: [systemd](https://wiki.archlinux.org/title/Systemd_(Русский))



## Настройка vsftpd

Настройте сервер [vsftpd](https://vsftpd.devnet.ru/rus/) через файл конфигурации — **/etc/vsftpd.conf**



#### Параметры IPv4 IPv6:

```ini
listen=YES
listen_ipv6=NO
```


#### Анонимный доступ:

```ini
anonymous_enable=YES
no_anon_password=YES
anon_root=/home/xxx/ftp
```

- `no_anon_password` - Не требовать от анонимуса пароль при работе в CLI клиенте
- `anon_root` - Куда должен попадать анонимный пользователь



#### Ограничение доступа:

```ini
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
```

 - `write_enable` - разрешить команды записи на сервере
 - `chroot_local_user` - использовать для пользователей изолированное окружение (доступ только к своим домашним каталогам)
 - `allow_writeable_chroot` - разрешить копировать файлы внутри своей домашней директории

При таких параметрах мы разрешаем доступ по FTP всем пользователям системы.
Если они прошли проверку логин-пароль. Они будут ограничены своей домашней директорией.
Данный метод хорошо подходит для домашнего сервера, для других желательно внести дополнительные ограничения:

Разрешите аутентификацию на FTP-сервере только тем пользователям, которые указаны в файле **userlist**:

```ini
# Use only users from list
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
```

Добавляем в список пользователей:

```console
ftp_user
anonymous
```

По умолчанию, авторизация выполняется с использованием локальных пользователей. Чтобы использовать специальную учетную запись, для подключения к FTP, создаем пользователя следующей командой:

```console
sudo useradd ftp_user
sudo passwd ftp_user
sudo usermod -d /home/xxx/ftp ftp_user
sudo usermod -s /bin/false ftp_user
```

где `ftp_user` — имя учетной записи; `/home/xxx/ftp` — домашний каталог (в него будем попадать при подключении); изменение шелла на `/bin/false` — запрет пользователю на локальный вход в систему.


Открываем на редактирование следующий файл:

```console
sudo nano /etc/shells
```

И добавляем следующее:

```console
/bin/false
```

мы добавили `/bin/false` в список разрешенных оболочек. В противном случае, может вернуться ошибка `530 Login incorrect`.


Чтобы пользователь имел права писать в директорию он должен быть ее владельцем, для
этого можно изменить ее владельца и группу:

```console
sudo chown ftp_user:ftp_user ftp
```

директория выше должна иметь другого владельца, чтобы при подключении по FTP, сам FTP сервер (черзе chroot) не позволял подняться выше (тем самым ограничив доступ).



#### Общие настройки:

```ini
pasv_enable=YES

hide_ids=YES
local_umask=022
connect_from_port_20=YES
use_localtime=YES
xferlog_enable=YES
utf8_filesystem=YES
```

- `pasv_enable` - включает пассивный режим работы FTP-сервера
- `hide_ids` - cкрыть владельца и группу, будет показано что файлами владеет `ftp:ftp`
- `local_umask` - назначьте права для новых файлов
- `connect_from_port_20` - настройте порт 20 для передачи данных
- `use_localtime` - разрешите серверу использовать локальный часовой пояс
- `xferlog_enable`- настройте запись всех передач файлов в лог
- `utf8_filesystem` - установить utf-8 как кодировку для файловой системы (в FileZila смотри менеджер сайтов)


#### SSL-сертификат:

Для настройки защищённой FTP-передачи с помощью SSL/TLS, так называемый [SFTP](https://ru.wikipedia.org/wiki/SFTP), нужен SSL-сертификат.
Вы можете использовать уже существующий сертификат или создать самоподписанный.

Генерация своего сертификата:

```console
sudo openssl req -x509 -newkey rsa:2048 -nodes -days 1825 -out /etc/ssl/certs/vsftpd.pem -keyout /etc/ssl/private/vsftpd.key
```

Это создаст сертификат сроком на 5 лет с RSA битностью 2048, при генерации будут запрошены параметры (страна, обьект и т.п)

Добавляем параметры в конфиг:

```ini
rsa_cert_file=/etc/ssl/certs/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.key
ssl_enable=YES

allow_anon_ssl=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
ssl_ciphers=HIGH
```

- `allow_anon_ssl` - разрешает использовать SSL анонимным пользователям
- `force_local_data_ssl` требует использования шифрования, и если установить `YES`, клиенты без шифрования не смогут подключиться (анонимный сможет)
- `force_local_logins_ssl` также требует подключение по SSL (анонимный сможет)
- `ssl_tlsv1` - использовать TLS версии 1
- `ssl_sslv2` и `ssl_sslv3` - использовать SSL версии 1 и 2
- `ssl_ciphers` - выбор шифра. В данном примере мы говорим использовать максимально безопасный.


После сохранения конфига, необходимо ребутнуть сервер:

```console
sudo systemctl restart vsftpd
```


Данные параметры дают доступ к серверу только пользователям указанным в файле `userlist_file=/etc/vsftpd.userlist` и только через [SFTP](https://ru.wikipedia.org/wiki/SFTP)
они могут создавать директории и добавлять файлы в своей домашней директории.
Анонимный пользователь может заходить как по FTP так и по SFTP и будет попадать в директорию `anon_root=/home/xxx/ftp` права у него только на чтение!

> WEB браузеры умеет только в стандартный FTP, для доступа по SFTP гуглим



## Links

- [vsftpd.conf(5) - Linux man page](https://linux.die.net/man/5/vsftpd.conf)
- [FileZila](https://filezilla-project.org)
