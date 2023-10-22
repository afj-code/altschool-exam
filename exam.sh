#!/bin/bash

#Create and move to directory to run vagrant from
mkdir /altschool_exam/
cd /altschool_exam/

#To begin, set vagrant var
vagrant_config="Vagrantfile"

#check if a previous Vagrant file exists
if [[ -f "$vagrant_config" ]]
then
        echo "Deleting previous vagrant configuration and writing new"
        rm Vagrantfile
else
        echo "No previous file found, writing vagrant configuration..."
        exit 1
fi

#Write vagrant config into new vagrant file
cat <<EOL> $vagrant_config
Vagrant.configure("2") do |config|
config.vm.box = "generic/ubuntu2204"

 #master VM config
 config.vm.define "master" do |master|
  master.vm.network "private_network", type: "dhcp"
  master.vm.hostname = "master"
  master.vm.network "forwarded_port", guest: 80, host: 8000
 end

 #slave VM config
 config.vm.define "slave" do |slave|
  slave.vm.network "private_network", type: "dhcp"
  slave.vm.hostname = "slave"
  slave.vm.network "forwarded_port", guest: 80, host: 9000
 end
end
EOL

#deploy vagrant
vagrant up

#Create deployment scripts in master node
vagrant ssh master
cat <<EOL> deploy.sh
#!/bin/bash
#Update libraries
sudo apt update

#Install apache
sudo apt install apache2 -y

#Make sure apache service is running
for i in {1..2}; do
        if systemctl is-enabled apache2 > /dev/null; then
                echo "apache enabled"
        else
                systemctl start apache2
                systemctl enable apache2
                echo "making sure apache is enabled"
        fi
done

#Restart apache
systemctl restart apache2

#install mySQL
sudo apt install mysql-server -y
sudo mysql_secure_installation
<<EOF
n
y
y
y
EOF

#setup mySQL
root_passwd="default001"
mysql -u root -p${root_passwd} -e "CREATE DATABASE \`mydb\`;"

#Create user and grant priviledges
mysql -u root -p${root_passwd} -e "CREATE USER 'conrad'@'localhost' IDENTIFIED BY 'conrad';"
mysql -u root -p${root_passwd} -e "GRANT ALL PRIVILEGES ON mydb.* TO 'conrad'@'localhost';"
mysql -u root -p${root_passwd} -e "FLUSH PRIVILEGES;"

echo "The root password for mySQL is default001. Please remember to change this accordingly."
echo "User and P/w is conrad"

#install php
sudo apt-get install php libapache2-mod-php php-mysql -y

#Create php info page
back=$(pwd)
a2dir=/var/www/html/
cd $a2dir
touch index.php
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/index.php
cd $back

#Restart apache
systemctl restart apache2

#Install Git
sudo apt-get install git -y

#Install ansible dependencies
sudo apt install -y software-properties-common python-apt
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update

#Install ansible
sudo apt-get install ansible

#Install SSH client
sudo apt install -y openssh-client

#Generate SSH keygen
echo '' | sudo ssh-keygen -N ""

#Create ansible dir
mkdir ansible
cd ansible


#Enter target location
cd $a2dir

#Clone Repo
sudo git clone https://github.com/laravel/laravel.git

#Restart apache
systemctl restart apache2

cd $back

EOL

#Make file executable
sudo chmod 755 deploy.sh

#Execute
sh deploy.sh

#Leave master node
exit

#assign slave ip addr
slave_ip=$(vagrant ssh slave -c "ip a show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'" | tr -d '\r')

#Copy the public key to slave's authorized keys
vagrant ssh master -c "cat ~/.ssh/id_rsa.pub" | vagrant ssh slave -c "cat >> ~/.ssh/authorized_keys"

#Re-enter master node
vagrant ssh master

#get deploy script path
deploy=$(pwd)

#Enter ansible dir
cd /ansible

#Create inventory file
touch host-inventory

#Copy slave ip addr to inventory file
echo $slave_ip >> host-inventory

#Establish initial server connection
echo "yes" | ansible all -i host-inventory -m ping

#Write ansible playbook
cat <<EOL> myansible.yml
---
- name: run script on slave node
  hosts: slave
  become: true

  tasks:
  - name: copy deploy.sh to slave node
    copy:
     src: $deploy/deploy.sh
     dest: ~/deploy.sh
    register: script_copy_result

  - name: run script
    command: sh ~/deploy.sh
    when: script_copy_result.changed
EOL

#Execute playbook
ansible-playbook myansible.yml -i host-inventory