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
 
borgbackup устанавливается из репозитория epel
резервные копии буду хранить под пользователем borg
ssh ключ копирую в authorized_keys
```bash
    bkp.vm.provision "shell", inline: <<-SHELL
      yum install epel-release -y
      yum install borgbackup -y
      useradd -m borg
      mkdir /home/borg/.ssh
      cat /vagrant/ssh-key/borg.pub >> /home/borg/.ssh/authorized_keys
      chown -R borg:borg /home/borg/.ssh
    SHELL
  end 
```

### Настройка server


```bash
    srv.vm.provision "shell", inline: <<-SHELL
      yum install epel-release -y
      yum install borgbackup -y
      mkdir /root/.ssh
      cp /vagrant/ssh-key/borg /root/.ssh/id_rsa
      cp /vagrant/config /root/.ssh/config
      chmod 600 /root/.ssh/id_rsa
      export BORG_PASSPHRASE="vagrant"
      borg init -e repokey borg@192.168.13.11:/home/borg/backup
      chmod +x /vagrant/backup.sh
      (crontab -l 2>/dev/null; echo "*/10 * * * * /vagrant/backup.sh") | crontab -
    SHELL
```

### скрипт для крона

```bash
```





