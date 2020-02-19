# Домашнее задание 13

[Vagrantfile](Vagrantfile)

## Задание
* Настроить резервное копирование папки /etc с одной виртуальной машины на другую по расписанию
* Настроить сжатие, шифрование, дедупликацию
## Решение

Стенд из 2 машин

backuper - для хранения резервных копий  
server - система, резервную копию "/etc" которой буду хранить  

сгенерированы ключи ssh  
borg.pub для backuper  
borg для server  

### Настройка backuper

в Vagrantfile сначала опишу конфиг для машины хранящей копии  

в секции provision  
borgbackup устанавливается из репозитория epel  
резервные копии буду хранить под пользователем borg  
публичный ssh ключ копирую в authorized_keys  
```bash
      yum install epel-release -y
      yum install borgbackup -y
      useradd -m borg
      mkdir /home/borg/.ssh
      cat /vagrant/ssh-key/borg.pub >> /home/borg/.ssh/authorized_keys
      chown -R borg:borg /home/borg/.ssh
```

### Настройка server

server будет запускать скрипт по крону и выполнять резервное копирование локальной папки /etc  

borgbackup устанавливается из репозитория epel  
приватный ssh ключ копирую в id_rsa  
копирую конфиг для ssh с отключением приверки ключа хоста  

```bash
      yum install epel-release -y
      yum install borgbackup -y
      mkdir /root/.ssh
      cp /vagrant/ssh-key/borg /root/.ssh/id_rsa
      cp /vagrant/config /root/.ssh/config
      chmod 600 /root/.ssh/id_rsa
```

использую переменную BORG_PASSPHRASE чтобы автоматически отвечать на запросы пароля от borg  
создаю репозиторий borg с ключом шифрования  
создаю расписание копирования в кроне  
```bash
      export BORG_PASSPHRASE="vagrant"
      borg init -e repokey borg@192.168.13.11:/home/borg/backup
      chmod +x /vagrant/backup.sh
      (crontab -l 2>/dev/null; echo "*/10 * * * * /vagrant/backup.sh") | crontab -
```

### скрипт для крона

экспорт пароля в переменную BORG_PASSPHRASE  
создание резервной копии со сжатием и выводом статистики  
с именем из названия папки и временем запуска копирования  
```bash
#!/bin/bash
export BORG_PASSPHRASE="vagrant"
borg create --list -v --stats --compression zlib,5  borg@192.168.13.11:/home/borg/backup::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
```

пример вывода команды borg create с параметрами из скрипта демонстрирует работу сжатия и дедупликации  
```bash
------------------------------------------------------------------------------
Archive name: etc-2020-02-19_12:10:02
Archive fingerprint: a1248d74168cca8abd0fead7e92b55e5c56b7b9ea80deec5ed5f39a985265ee2
Time (start): Wed, 2020-02-19 12:10:03
Time (end):   Wed, 2020-02-19 12:10:04
Duration: 1.21 seconds
Number of files: 1691
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               27.80 MB             13.25 MB                644 B
All archives:                7.20 GB              3.43 GB             12.07 MB

                       Unique chunks         Total chunks
Chunk index:                    1538               436674
------------------------------------------------------------------------------
```

Пример вывода borg list после создания нескольких копий  

```bash
[root@server ~]# borg list borg@192.168.13.11:/home/borg/backup
Enter passphrase for key ssh://borg@192.168.13.11/home/borg/backup:
etc-2020-02-18_14:45:02              Tue, 2020-02-18 14:45:03 [854f3cb91cdb461b21c172b46c8fa9119642c264cfe47d1dac983fa45995b7db]
...
...
etc-2020-02-19_11:50:01              Wed, 2020-02-19 11:50:03 [0b1de6e07e3b9b513a24238a8a6c6ff2e63f8fbaa681a6ffb3fc1fd8e0f0cb50]
etc-2020-02-19_12:00:01              Wed, 2020-02-19 12:00:03 [eaf4774ac165a748d46568a936cdda06071657c04a32d681da3b0ef86cb4aed4]
etc-2020-02-19_12:10:02              Wed, 2020-02-19 12:10:03 [a1248d74168cca8abd0fead7e92b55e5c56b7b9ea80deec5ed5f39a985265ee2]
```

