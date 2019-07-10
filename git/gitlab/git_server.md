# Git Server on Ubuntu server


## Description

Краткий [HowTo](https://ru.wikipedia.org/wiki/How-to) как установить Ubuntu-server.


#### Contents

- [OS Ubuntu Server](#os-ubuntu-server)
	- [Действия после установки](#действия-после-установки)
		- [Обновление](#обновление)
		- [Установка tools](#установка-tools)
		- [Создание tmpfs](#создание-tmpfs)
		- [Установка SSH](#установка-ssh)
		- [Установка статического IP-адреса](#установка-статического-ip-адреса)


---



## OS Ubuntu Server

Для работы выбрана OS Ubunut Server 18.04.1 64 bit

Download:  [https://www.ubuntu.com/download/server](https://www.ubuntu.com/download/server)


Параметры затребованные во время установки:

* PC-Name: `git-server`
* User: `xxx`
* Pass: `xxx`



### Действия после установки


#### Обновление
```console
sudo apt-get update
sudo apt-get upgrade
```


#### Установка tools
```console
sudo apt install mc
sudo apt install htop
sudo apt install make
```


#### Создание tmpfs
```console
sudo nano /etc/fstab
```

В конец файла прописываем это:

```console
# Параметры для tmpfs
tmpfs /tmp                tmpfs defaults 0 0
tmpfs /var/tmp            tmpfs defaults 0 0
tmpfs /home/xxx/.cache    tmpfs defaults 0 0
```


#### Установка SSH

```console
sudo apt install ssh
systemctl enable ssh.socket
```

[Настройка SSH](http://help.ubuntu.ru/wiki/ssh)


После можно ребутнуться и проверить как все работает! Дальнейшую работу можно проводить удаленно!


#### Установка статического IP-адреса

[Netplan](https://netplan.io/) — это новая утилита сетевых настроек с помощью командной строки, установленный  начиная с Ubuntu 17.10 для легкого управления и сетевых настроек в системах Ubuntu. Она позволяет настроить сетевой интерфейс с использованием абстракции YAML. Он работает совместно с сетевыми демонами NetworkManager и systemd-networkd (называемыми рендерерами, вы можете выбрать, какой из них использовать) в качестве интерфейсов к ядру.

Он считывает сетевую конфигурацию, описанную в файле `/etc/netplan/*.yaml`. Вы можете хранить конфигурации для всех своих сетевых интерфейсов в этих файлах.



```console
sudo nano /etc/netplan/01-netcfg.yaml
```

Вставляем наш конфиг:

```console
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    enp5s0:
      dhcp4: no
      dhcp6: no
      addresses: [10.30.1.210/8]
      gateway4: 10.0.0.1
      nameservers:
        addresses: [10.0.0.1, 10.0.0.2]
```

Применяем настройки:

```console
sudo netplan apply
```

Проверяем:

```console
ifconfig -a
```


Далее идет настройка [RAID](../../linux/software_raid.md) и установка [GitLab-a](./GitLab.md)
