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

пример вывода команды borg create с параметрами из скрипта  
```bash
------------------------------------------------------------------------------
Archive name: etc-2020-02-18_14:53:41
Archive fingerprint: b9a9e8d8a8707a79e79dc41dc2e89b5f98dbac5dd03ff5eea11c8b7d9b4f7943
Time (start): Tue, 2020-02-18 14:53:46
Time (end):   Tue, 2020-02-18 14:53:47
Duration: 1.17 seconds
Number of files: 1691
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               27.80 MB             13.27 MB                639 B
All archives:               83.39 MB             39.79 MB             11.75 MB

                       Unique chunks         Total chunks
Chunk index:                    1278                 5058
------------------------------------------------------------------------------
```

Пример вывода borg list после создания нескольких копий  

```bash
[root@server ~]# borg list borg@192.168.13.11:/home/borg/backup
Enter passphrase for key ssh://borg@192.168.13.11/home/borg/backup:
etc-2020-02-18_14:45:02              Tue, 2020-02-18 14:45:03 [854f3cb91cdb461b21c172b46c8fa9119642c264cfe47d1dac983fa45995b7db]
etc-2020-02-18_14:50:02              Tue, 2020-02-18 14:50:03 [82ce7185ad151335e4e589f70f2d2f7867f203bf63bdb9a1e403b867d922c417]
etc-2020-02-18_14:53:41              Tue, 2020-02-18 14:53:46 [b9a9e8d8a8707a79e79dc41dc2e89b5f98dbac5dd03ff5eea11c8b7d9b4f7943]
etc-2020-02-18_14:55:01              Tue, 2020-02-18 14:55:03 [a834cb774324e133302cea1994b886c8bf13b70676e2cd3b0c2f5f83a47489a0]
```

