# Send E-Mail from console in Linux


## Description

Краткий [HowTo](https://ru.wikipedia.org/wiki/How-to) как в Linux отправить почту (E-Mail) через консоль.


#### Contents

- [Introduction](#introduction)
	- [Установка и настройка sSMTP](#установка-и-настройка-ssmtp)
	- [Тестирование отправки сообщений из командной строки](#тестирование-отправки-сообщений-из-командной-строки)
- [Links](#links)


---



## Introduction

Вам может понадобиться отправлять сообщения электронной почты из командной строки для отслеживания важных событий, передачи информации о состоянии системы или для чего-либо еще.


### Установка и настройка sSMTP

На следующем шаге нужно установить агент передачи сообщений (Message Transfer Agent - MTA), в нашем случае sSMTP, который может лишь отправлять сообщения электронной почты, но не принимать их.

Команда для установки sSMTP в Debian или Ubuntu:

```console
sudo apt-get install ssmtp
```


Файл конфигурации sSMTP, в который вам придется добавить информацию для доступа к почтовому серверу, расположен по пути `/etc/ssmtp/ssmtp.conf`.

Пример содержимого этого файла приведен ниже.

**Gmail**
```console
mailhub=smtp.gmail.com:587
rewriteDomain=gmail.com
hostname=smtp.gmail.com:587

AuthUser=<имя-пользователя>@gmail.com
AuthPass=<пароль>

FromLineOverride=YES
UseTLS=YES
USESTARTTLS=YES
```

**Yandex**
```console
mailhub=smtp.yandex.ru:465
rewriteDomain=yandex.ru
hostname=smtp.yandex.ru:465

AuthUser=<имя-пользователя>@yandex.ru
AuthPass=<пароль>

FromLineOverride=YES
UseTLS=YES
USESTARTTLS=YES
```


Используйте команду [man ssmtp.conf](https://linux.die.net/man/5/ssmtp.conf) для получения информации обо всех параметрах конфигурации sSMTP.

Настраиваем отправителей писем:
Редактируем файл `/etc/ssmtp/revaliases`

```console
root:почта@с_которой_отсылаем:smtp.yandex.ru:465
user:почта@с_которой_отсылаем:smtp.yandex.ru:465
```

Измените `user` на пользователя, который заведен в вашей системе.

Проверим настройки, отправив тестовое письмо

```console
echo test | sendmail -v <имя-адресата>@gmail.com
```


### Тестирование отправки сообщений из командной строки

Существует огромное количество утилит с интерфейсом командной строки для отправки сообщений электронной почты на любой вкус.

Команда `mail` доступна после установки пакета программного обеспечения `mailutils` в дистрибутивах Debian и Ubuntu и может использоваться практически в любом дистрибутиве Linux.

```console
mail -s "test $(date)" -A /var/log/syslog <имя-адресата>@gmail.com < /dev/null
```

```console
echo "Text of Message" | mail -s "test $(date)" -A /var/log/syslog <имя-адресата>@gmail.com
```

```console
mail -s "test $(date)" -A /var/log/syslog <имя-адресата>@gmail.com < /file/to/send
```

флаг `-A` добавит файл во вложение к письму, `-s` указывает заголовок письма.

Вы можете отредактировать эту команду в соответствии со своими потребностями.


**Note**
> не во всех реализациях отправка прикрепленного файла и тела сообщений работают! Нужно отправлять либо то либо другое. или делать два отправления

> иногда нужно отсылать пустое тело письма, иначе запускается консольный режим ввода письма для этого можно использовать < /dev/null

> При этом, если использовать флаг `-A` то режим ввода письма запускается, но текст все равно не отсылается! Отсылается только прикрепленный файл. Чтобы подавить ввод также используем < /dev/null



## Links


- [Отправка почты для root на внешний ящик](https://help.ubuntu.ru/wiki/%D0%BE%D1%82%D1%80%D0%B0%D0%B2%D0%BA%D0%B0_%D0%BF%D0%BE%D1%87%D1%82%D1%8B_%D0%B4%D0%BB%D1%8F_root_%D0%BD%D0%B0_%D0%B2%D0%BD%D0%B5%D1%88%D0%BD%D0%B8%D0%B9_%D1%8F%D1%89%D0%B8%D0%BA)
- [Send mail from command line in Linux or OpenWrt](http://rus-linux.net/MyLDP/internet/send-mail-command-line-linux-openwrt.html)
- [16 COMMAND EXAMPLES TO SEND EMAIL FROM THE LINUX COMMAND LINE](https://blog.edmdesigner.com/send-email-from-linux-command-line/)
