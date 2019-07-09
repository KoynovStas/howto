# Software raid in Linux (mdadm)


## Description

Краткий [HowTo](https://ru.wikipedia.org/wiki/How-to) как в Linux средствами [mdadm](http://xgu.ru/wiki/mdadm) собрать софтварный [RAID](https://ru.wikipedia.org/wiki/RAID) и настроить авто-монтирование.


#### Contents

- [Introduction](#introduction)
- [OS Ubuntu Server](#os-ubuntu-server)
	- [Установка tools](#установка-tools)
- [Подготовка разделов](#подготовка-разделов)
	- [Создание разделов](#создание-разделов)
	- [Изменение типа разделов](#изменение-типа-разделов)
- [Создание RAID-массива](#создание-raid-массива)
	- [Проверка правильности сборки](#проверка-правильности-сборки)
	- [Создание файловой системы поверх RAID-массива](#создание-файловой-системы-поверх-raid-массива)
	- [Создание mdadm.conf](#создание-mdadmconf)
- [Автомонтирование RAID](#автомонтирование-raid)
- [Обслуживание RAID](#обслуживание-raid)
	- [Мониторинг состояния](#мониторинг-состояния)
	- [Замена сбойного диска](#замена-сбойного-диска)
		- [1. Пометка диска как сбойного](#1-пометка-диска-как-сбойного)
		- [2. Удаление сбойного диска](#2-удаление-сбойного-диска)
		- [3. Выключаем машину, меняем диск](#3-выключаем-машину-меняем-диск)
		- [4. Подготовка нового жесткого диска](#4-подготовка-нового-жесткого-диска)
		- [5. Добавление нового диска](#5-добавление-нового-диска)
- [Links](#links)



---



## Introduction


[RAID](https://ru.wikipedia.org/wiki/RAID) массивы позволяют с помощью нескольких винчестеров создать систему хранения данных, которая будет обладать нужной степенью отказоустойчивости. Например, в случае массива [RAID-5](https://ru.wikipedia.org/wiki/RAID#RAID_5) ваши данные останутся в целости при сгорании одного из винчестеров, [RAID-6](https://ru.wikipedia.org/wiki/RAID#RAID_6) позволяет обеспечить гарантированное сохранение данных при вылете уже двух винчестеров. [RAID-1](https://ru.wikipedia.org/wiki/RAID#RAID_1), он же “зеркало”, нужен в тех случаях, когда нужно хранить важную информацию. Обычно зеркало создается из двух дисков и информация записывается одновременно на два диска. Поэтому выход из строя одного диска не приведет к потере информации. Также такой тип RAID-а дает небольшое увеличение скорости чтения. Кроме того, есть специальный тип [RAID-0](https://ru.wikipedia.org/wiki/RAID#RAID_0), который вообще говоря не обеспечивает никакой сохранности и нужен лишь для увеличения скорости работы.


Итак, если вы решили создать RAID массив, вам понадобятся как минимум несколько винчестеров. Но кроме того вам придется выбрать технологию управления вашим массивом. Существуют три основных возможности:
- аппаратный RAID-массив
- аппаратно-программный RAID-массив
- программный RAID-массив.

Первые два способа требуют наличия достаточно дорогих RAID-контроллеров и имеют один немаловажный недостаток: если у вас сгорит не винчестер, а RAID-контроллер, то восстановить массив обычно можно будет только достав ровно такой же контроллер. А поскольку нет никаких гарантий, что лет через 5 на рынке всё ещё будет нужное железо, то иногда использование аппаратных RAID-массивов нежелательно. С другой стороны, полностью аппаратный массив никак не зависит от программной начинки компьютера.


## OS Ubuntu Server

Для работы выбрана OS Ubunut Server 18.04.1 64 bit

Download:  [https://www.ubuntu.com/download/server](https://www.ubuntu.com/download/server)



### Установка tools

Для создания и управления [RAID](https://ru.wikipedia.org/wiki/RAID) массивом вам потребуется утилита [mdadm](http://xgu.ru/wiki/mdadm)

```console
sudo apt-get install mdadm
```



## Подготовка разделов

Нужно определить на каких физических разделах будет создаваться RAID-массив. Если разделы уже есть, нужно найти свободные (`fdisk -l`). Если разделов ещё нет, но есть неразмеченное место, их можно создать с помощью программ `fdisk` или `cfdisk`.

Для создания массива вам нужны не винчестеры целиком, а лишь логические диски (желательно - одинакового объёма, в противном случае размер массива будет рассчитываться исходя из размера диска с минимальным объёмом), но использовать два диска на одном винчестере - очень плохая идея, ибо это уничтожает весь смысл применения RAID.



Просмотреть какие разделы есть:

```console
fdisk -l
```


Просмотреть, какие разделы куда смонтированы, и сколько свободного места есть на них (размеры в килобайтах):

```console
df -k
```

Если вы будете использовать созданные ранее разделы, обязательно размонтируйте их. RAID-массив нельзя создавать поверх разделов, на которых находятся смонтированные файловые системы.

```console
umount /dev/hdeX
```



### Создание разделов

Если разделы больше 2ТБ, то нужно использовать [parted](http://man7.org/linux/man-pages/man8/parted.8.html) и размечать под [GPT](https://en.wikipedia.org/wiki/GUID_Partition_Table):


```console
parted -a optimal /dev/sda
```


Если меньше 2ТБ, то можно размечать `fdisk-ом` или `cfdisk-ом`(псевдо-графическая утилита)

Создадим разделы типа - **fd** - `Linux raid auto`.

```console
fdisk /dev/sdd

Welcome to fdisk (util-linux 2.27.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0xbb8eba44.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1):
First sector (2048-3907029167, default 2048):
Last sector, +sectors or +size{K,M,G,T,P} (2048-3907029167, default 3907029167):

Created a new partition 1 of type 'Linux' and of size 1.8 TiB.



Command (m for help): t
Selected partition 1
Partition type (type L to list all types): L

 0  Empty           24  NEC DOS         81  Minix / old Lin bf  Solaris
 1  FAT12           27  Hidden NTFS Win 82  Linux swap / So c1  DRDOS/sec (FAT-
 2  XENIX root      39  Plan 9          83  Linux           c4  DRDOS/sec (FAT-
 3  XENIX usr       3c  PartitionMagic  84  OS/2 hidden or  c6  DRDOS/sec (FAT-
 4  FAT16 <32M      40  Venix 80286     85  Linux extended  c7  Syrinx
 5  Extended        41  PPC PReP Boot   86  NTFS volume set da  Non-FS data
 6  FAT16           42  SFS             87  NTFS volume set db  CP/M / CTOS / .
 7  HPFS/NTFS/exFAT 4d  QNX4.x          88  Linux plaintext de  Dell Utility
 8  AIX             4e  QNX4.x 2nd part 8e  Linux LVM       df  BootIt
 9  AIX bootable    4f  QNX4.x 3rd part 93  Amoeba          e1  DOS access
 a  OS/2 Boot Manag 50  OnTrack DM      94  Amoeba BBT      e3  DOS R/O
 b  W95 FAT32       51  OnTrack DM6 Aux 9f  BSD/OS          e4  SpeedStor
 c  W95 FAT32 (LBA) 52  CP/M            a0  IBM Thinkpad hi ea  Rufus alignment
 e  W95 FAT16 (LBA) 53  OnTrack DM6 Aux a5  FreeBSD         eb  BeOS fs
 f  W95 Ext'd (LBA) 54  OnTrackDM6      a6  OpenBSD         ee  GPT
10  OPUS            55  EZ-Drive        a7  NeXTSTEP        ef  EFI (FAT-12/16/
11  Hidden FAT12    56  Golden Bow      a8  Darwin UFS      f0  Linux/PA-RISC b
12  Compaq diagnost 5c  Priam Edisk     a9  NetBSD          f1  SpeedStor
14  Hidden FAT16 <3 61  SpeedStor       ab  Darwin boot     f4  SpeedStor
16  Hidden FAT16    63  GNU HURD or Sys af  HFS / HFS+      f2  DOS secondary
17  Hidden HPFS/NTF 64  Novell Netware  b7  BSDI fs         fb  VMware VMFS
18  AST SmartSleep  65  Novell Netware  b8  BSDI swap       fc  VMware VMKCORE
1b  Hidden W95 FAT3 70  DiskSecure Mult bb  Boot Wizard hid fd  Linux raid auto
1c  Hidden W95 FAT3 75  PC/IX           bc  Acronis FAT32 L fe  LANstep
1e  Hidden W95 FAT1 80  Old Minix       be  Solaris boot    ff  BBT
Partition type (type L to list all types): fd
Changed type of partition 'Linux' to 'Linux raid autodetect'.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```


### Изменение типа разделов

Итак, для начала нужно подготовить разделы, которые вы хотите включить в RAID, присвоив им тип **fd** (`Linux RAID Autodetect`) Это не обязательно, но желательно.

Изменить тип раздела можно с помощью `fdisk`.

Рассмотрим как это делать на примере раздела `/dev/hde1`.

```console
fdisk /dev/hde
    The number of cylinders for this disk is set to 8355.
    There is nothing wrong with that, but this is larger than 1024,
    and could in certain setups cause problems with:
    1) software that runs at boot time (e.g., old versions of LILO)
    2) booting and partitioning software from other OSs
    (e.g., DOS FDISK, OS/2 FDISK)

    Command (m for help):

    Use FDISK Help

    Now use the fdisk m command to get some help:

    Command (m for help): m
    ...
    ...
    p   print the partition table
    q   quit without saving changes
    s   create a new empty Sun disklabel
    t   change a partition's system id
    ...
    ...
    Command (m for help):

    Set The ID Type To FD

    Partition /dev/hde1 is the first partition on disk /dev/hde.
    Modify its type using the t command, and specify the partition number
    and type code.
    You also should use the L command to get a full listing
    of ID types in case you forget.

    Command (m for help): t
    Partition number (1-5): 1
    Hex code (type L to list codes): L

    ...
    ...
    ...
    16  Hidden FAT16    61   SpeedStor       f2  DOS secondary
    17  Hidden HPFS/NTF 63  GNU HURD or Sys fd  Linux raid auto
    18  AST SmartSleep  64  Novell Netware  fe  LANstep
    1b  Hidden Win95 FA 65  Novell Netware  ff  BBT
    Hex code (type L to list codes): fd
    Changed system type of partition 1 to fd (Linux raid autodetect)

    Command (m for help):


    Make Sure The Change Occurred

    Use the p command to get the new proposed partition table:

    Command (m for help): p

    Disk /dev/hde: 4311 MB, 4311982080 bytes
    16 heads, 63 sectors/track, 8355 cylinders
    Units = cylinders of 1008 * 512 = 516096 bytes

    Device Boot    Start       End    Blocks   Id  System
    /dev/hde1             1      4088   2060320+  fd  Linux raid autodetect
    /dev/hde2          4089      5713    819000   83  Linux
    /dev/hde4          6608      8355    880992    5  Extended
    /dev/hde5          6608      7500    450040+  83  Linux
    /dev/hde6          7501      8355    430888+  83  Linux

    Command (m for help):


    Save The Changes

    Use the w command to permanently save the changes to disk /dev/hde:

    Command (m for help): w
    The partition table has been altered!

    Calling ioctl() to re-read partition table.

    WARNING: Re-reading the partition table failed with error 16: Device or resource busy.
    The kernel still uses the old table.
    The new table will be used at the next reboot.
    Syncing disks.
```
Аналогичным образом нужно изменить тип раздела для всех остальных разделов, входящих в RAID-массив.


## Создание RAID-массива

Создание RAID-массива выполняется с помощью программы mdadm (ключ 	`--create`). Мы воспользуемся опцией `--level`, для того чтобы создать RAID-массив 1 уровня. С помощью ключа `--raid-devices` укажем устройства, поверх которых будет собираться RAID-массив.

```console
mdadm --create --verbose /dev/md0 --level=1  --raid-devices=3 /dev/hde1 /dev/hdf2 /dev/hdg1

mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
mdadm: size set to 1953382464K
mdadm: automatically enabling write-intent bitmap on large array
Continue creating array? y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```


Если вы хотите сразу создать массив, где диска не хватает (**degraded**) просто укажите слово `missing` вместо имени устройства. Для [RAID-5](https://ru.wikipedia.org/wiki/RAID#RAID_5) это может быть только один диск; для [RAID-6](https://ru.wikipedia.org/wiki/RAID#RAID_6) — не более двух; для [RAID-1](https://ru.wikipedia.org/wiki/RAID#RAID_1) — сколько угодно, но должен быть как минимум один рабочий.



### Проверка правильности сборки

Убедиться, что RAID-массив проинициализирован корректно можно просмотрев файл `/proc/mdstat`. В этом файле отражается текущее состояние RAID-массива.

```console
cat /proc/mdstat
    Personalities : [raid1]
    read_ahead 1024 sectors
    md0 : active raid1 hdg1[2] hde1[1] hdf2[0]
        4120448 blocks level 1, 32k chunk, algorithm 3 [3/3] [UUU]

    unused devices: <none>
```

Обратите внимание на то, как называется новый RAID-массив. В нашем случае он называется `/dev/md0`. Мы будем обращаться к массиву по этому имени.


### Создание файловой системы поверх RAID-массива

Новый RAID-раздел нужно отформатировать, т.е. создать на нём файловую систему. Сделать это можно при помощи программы из семейства `mkfs`. Если мы будем создавать файловую систему `ext4`, воспользуемся программой `mkfs.ext4`

```console
mkfs.ext4 -b 4096 /dev/md0
```


### Создание mdadm.conf

Система сама не запоминает какие RAID-массивы ей нужно создать и какие компоненты в них входят. Эта информация находится в файле `mdadm.conf`.

Строки, которые следует добавить в этот файл, можно получить при помощи команды

 `mdadm --detail --scan`

Вот пример её использования:

```console
mdadm --detail --scan
ARRAY /dev/md/0 metadata=1.2 name=git-server:0 UUID=5e8844bd:5770bb76:87273e6c:2af1b698
```

Данный *выхлоп* является специально отформатированным в том формате, который используется для файла конфигурации `mdadm.conf`. Поэтому мы просто копируем данную строку в конфиг!
Более детально смотри: [mdadm.conf(5)](https://linux.die.net/man/5/mdadm.conf)


**Note**
 > Если реальная конфигурация не совпадает с той, которая записана в /etc/mdadm/mdadm.conf, то обязательно приведите этот файл в соответствие с реальной конфигурацией до перезагрузки, иначе в следующий раз массив не запустится.


Если файла `mdadm.conf` ещё нет, можно его создать:

```console
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
```

Если же он есть, то он выглядит как то так:

```console
# mdadm.conf
#
# !NB! Run update-initramfs -u after updating this file.
# !NB! This will ensure that initramfs has an uptodate copy.
#
# Please refer to mdadm.conf(5) for information about this file.
#

# by default (built-in), scan all partitions (/proc/partitions) and all
# containers for MD superblocks. alternatively, specify devices to scan, using
# wildcards if desired.
#DEVICE partitions containers

# automatically tag new arrays as belonging to the local system
HOMEHOST <none>

# instruct the monitoring daemon where to send mail alerts
MAILADDR skojnov@yandex.ru

# definitions of existing MD arrays
ARRAY /dev/md0 metadata=1.2 name=git-server:0 UUID=7343c978:1d7f0fc1:73c56c72:f9931025

# This configuration was auto-generated on Wed, 03 Oct 2018 10:57:29 +0400 by mkconf
```

Обратите внимание на `HOMEHOST <none>`

После изменения файла вызываем:
```console
sudo update-initramfs -u
```



## Автомонтирование RAID

Поскольку мы создали новую файловую систему, вероятно, нам понадобится и новая точка монтирования. Назовём её `/raid`.

```console
mkdir /raid
```

Для того чтобы файловая система, созданная на новом RAID-массиве автоматически монтировалась при загрузке, добавим соответствующую запись в файл `/etc/fstab` хранящий список автоматически монтируемых при загрузке файловых систем.

```console
   /dev/md0      /raid     ext4    defaults    0 2
```


Если мы объединяли в RAID-массив разделы, которые использовались раньше, нужно отключить их монтирование: удалить или закомментировать соответствующие строки в файле `/etc/fstab`. Закомментировать строку можно символом `#`


```console
    #/dev/hde1       /data1        ext4    defaults        1 2
    #/dev/hdf2       /data2        ext4    defaults        1 2
    #/dev/hdg1       /data3        ext4    defaults        1 2
```

Теперь после перезагрузки RAID будет автоматически пересобираться и монтироваться в `/raid`



## Обслуживание RAID


### Мониторинг состояния

Информация о всех RAID-массивах:

```console
cat /proc/mdstat
```

Если вместо [UU] видим [U_], то дело плохо, целостность одного из дисков нарушена - нужно менять диск.


Информация о конкретном дисковом разделе:
```console
mdadm -E /dev/sdb2
```


Чтобы получить подробную информацию, а также узнать, в каком состоянии находится массив, можно воспользоваться опцией `--detail` из режима misc утилиты `mdadm`. Ниже предоставлен пример вывода для массива RAID-1, состоящего из трёх дисков, который мы создавали.

```console
mdadm --detail /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Thu Jan 12 12:24:16 2012
     Raid Level : raid1
     Array Size : 8387572 (8.00 GiB 8.59 GB)
  Used Dev Size : 8387572 (8.00 GiB 8.59 GB)
   Raid Devices : 3
  Total Devices : 3
    Persistence : Superblock is persistent

    Update Time : Fri Jan 20 04:09:29 2012
          State : clean
 Active Devices : 3
Working Devices : 3
 Failed Devices : 0
  Spare Devices : 0

           Name : debian-test0:0  (local to host debian-test0)
           UUID : a51bea1f:59677b56:1a4a2cbe:8a258729
         Events : 196

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
```


Как видим, все три устройства являются активными и синхронизированными, иными словами всё хорошо. Теперь давайте представим (к сожалению, у меня нет возможности физически сломать одно из устройств, входящих в рассматриваемый массив), что один из дисков вышел из строя (вспомним, что для RAID-1/5/6 это допустимо). В случае «железных» проблем драйвер md автоматически пометит диск как сбойный и исключит его дальнейшее использование в массиве; в нашем же тестовом случае мы сделаем это программно. Итак, сделаем устройство `/dev/sdc` сбойным:

```console
mdadm --fail /dev/md0 /dev/sdc
mdadm: set /dev/sdc faulty in /dev/md0
```

И посмотрим, что изменилось:

```console
# mdadm --detail /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Thu Jan 12 12:24:16 2012
     Raid Level : raid1
     Array Size : 8387572 (8.00 GiB 8.59 GB)
  Used Dev Size : 8387572 (8.00 GiB 8.59 GB)
   Raid Devices : 3
  Total Devices : 3
    Persistence : Superblock is persistent

    Update Time : Fri Jan 20 04:26:25 2012
          State : clean, degraded
 Active Devices : 2
Working Devices : 2
 Failed Devices : 1
  Spare Devices : 0

           Name : debian-test0:0  (local to host debian-test0)
           UUID : a51bea1f:59677b56:1a4a2cbe:8a258729
         Events : 198

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       0        0        1      removed
       2       8       48        2      active sync   /dev/sdd

       1       8       32        -      faulty spare   /dev/sdc
```

Первое, что видим: массив стал неполным (`degraded`). хотя и продолжает функционировать (`clean`):

```console
State : clean, degraded
```

Сразу же оцениваем ситуацию. Вместо трёх активных устройств у нас осталось всего два:

```console
Active Devices : 2
Working Devices : 2
```

и один диск сбойный:

```console
Failed Devices : 1
```

В самом конце `mdadm` любезно предоставляет подробную информацию об устройствах, входящих массив, отметив что второй по счёту диск был удалён:

```console
0       8       16        0      active sync   /dev/sdb
1       0        0        1      removed
2       8       48        2      active sync   /dev/sdd
```

а после — информацию об удалённом диске:

```console
1       8       32        -      faulty spare   /dev/sdc
```

Из всего становится понятно, что наш RAID-1 работает на двух дисках и что надо-что-то решать с вышедшим из строя устройством. Прежде всего, его необходимо отключить от массива:

```console
# mdadm --manage --remove /dev/md0 /dev/sdc
mdadm: hot removed /dev/sdc from /dev/md0
```

Далее уже по обстоятельствам. Первым делом стоит изучить содержимое логов ядра и попытаться определить причину сбоя. Причины могут быть разные, начиная от проблем с интерфейсным кабелем или питанием, до полного выхода диска из строя. Если физически с диском всё порядке и ошибка была вызвана, например, некачественным кабелем, то после её устранения и подключения диска, необходимо вернуть его в массив:

```console
# mdadm --manage --re-add /dev/md0 /dev/sdc
mdadm: re-added /dev/sdc
```

Если всё в порядке, драйвер `md` тут же приступит к операции восстановления массива до «полного» состояния путём синхронизации данных на вернувшийся диск:

```console
# mdadm --detail /dev/md0
/dev/md0:
        Version : 1.2
  Creation Time : Thu Jan 12 12:24:16 2012
     Raid Level : raid1
     Array Size : 8387572 (8.00 GiB 8.59 GB)
  Used Dev Size : 8387572 (8.00 GiB 8.59 GB)
   Raid Devices : 3
  Total Devices : 3
    Persistence : Superblock is persistent

    Update Time : Fri Jan 20 04:57:37 2012
          State : clean, degraded, recovering
 Active Devices : 2
Working Devices : 3
 Failed Devices : 0
  Spare Devices : 1

 Rebuild Status : 3% complete

           Name : debian-test0:0  (local to host debian-test0)
           UUID : a51bea1f:59677b56:1a4a2cbe:8a258729
         Events : 206

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      spare rebuilding   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
```

И, в случае успешного восстановления, массив вернётся к своему нормальному состоянию, которое было приведено в начале заметки.

Если же устройство, которое вышло из строя, к жизни вернуть не представляется возможным, то после замены его новым, вместо опции `--re-add` следует использовать опцию `--add`:


```console
mdadm /dev/md0 --add /dev/sdc
mdadm: added /dev/sdc
```




### Замена сбойного диска

Перед установкой нового жесткого диска необходимо удалить из массива поврежденный диск. Для этого выполняем следующую последовательность команд:

#### 1. Пометка диска как сбойного

Диск в массиве можно условно сделать сбойным, ключ `--fail` (`-f`):

```console
mdadm /dev/md0 --fail /dev/hde1
```

#### 2. Удаление сбойного диска

Сбойный диск можно удалить с помощью ключа `--remove` (`-r`):

```console
mdadm /dev/md0 --remove /dev/hde1
```

#### 3. Выключаем машину, меняем диск

#### 4. Подготовка нового жесткого диска

Диски в массиве должны иметь абсолютно одинаковое разбиение. В зависимости от используемого типа таблицы разделов (`MBR` или `GPT`) необходимо использовать соответствующие утилиты для копирования таблицы разделов.

Для жесткого диска с `MBR` используем утилиту `sfdisk`:
```console
sfdisk -d /dev/sda | sfdisk --force /dev/sdb
```

где `/dev/sda` - диск источник, `/dev/sdb` - диск назначения.


Для жесткого диска с `GPT` используем утилиту `sgdisk` из `GPT fdisk`:

```console
sgdisk -R /dev/sdb /dev/sda
sgdisk -G /dev/sdb
```

где `/dev/sda` - диск источник, `/dev/sdb` - диск назначения. Вторая строка назначает новому жесткому диску случайный [UUID](https://ru.wikipedia.org/wiki/UUID).


#### 5. Добавление нового диска

Добавить новый диск в массив можно с помощью ключей `--add` (`-a`) и `--re-add`:

```console
mdadm /dev/md0 --add /dev/hde1
```

После этого начнется процесс синхронизации. Время синхронизации зависит от объема жесткого диска:

```console
cat /proc/mdstat

Personalities : [raid1]
md0 : active raid1 sdb4[1] sda4[0]
     1028096 blocks [2/2] [UU]
     [==========>..........]  resync =  50.0% (514048/1028096) finish=97.3min speed=65787K/sec
```


На этом все! Мы знаем как создать RAID массив, как посмотреть его состояние, и как заменить hdd в случае его отказа.



## Links

- [mdadm wiki](http://xgu.ru/wiki/mdadm)
- [Создание программного RAID массива в Ubuntu](https://help.ubuntu.ru/wiki/%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%BD%D1%8B%D0%B9_raid)
- [Создание программного RAID 1 зеркала в Ubuntu](https://4te.me/post/software-raid1-ubuntu/)
- [Замена жесткого диска в программном RAID1 в операционной системе Linux](http://www.sysadmin.in.ua/info/index/21/24/28)
- [Программный RAID в Linux. Тестирование и мониторинг](http://ashep.org/2012/programmnyj-raid-v-linux-testirovanie-i-monitoring/)
- [Замена сбойного диска в программном RAID массиве](http://avreg.net/howto_software-raid-replacing-faulty-drive.html)
