# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure(2) do |config|
  config.vm.box = "centos/7" 
  config.vm.box_version = "1905.1"

  config.vm.define "backuper", primary: true do |bkp|
    bkp.vm.hostname = "backuper"
    bkp.vm.network "private_network", ip: "192.168.13.11"
    bkp.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    bkp.vm.provision "shell", inline: <<-SHELL
      yum install epel-release -y
#      yum update -y
      yum install borgbackup -y
      useradd -m borg
      mkdir /home/borg/.ssh
      cat /vagrant/ssh-key/borg.pub >> /home/borg/.ssh/authorized_keys
      chown -R borg:borg /home/borg/.ssh
    SHELL
  end 
  config.vm.define "server", primary: true do |srv|
    srv.vm.hostname = "server"
    srv.vm.network "private_network", ip: "192.168.13.10"
    srv.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "512"]
      vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
    end
    srv.vm.provision "shell", inline: <<-SHELL
      yum install epel-release -y
#      yum update -y
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
  end
end
