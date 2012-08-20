#!/bin/bash
# http://docs.openstack.org/ -> 3rd one down
# http://docs.openstack.org/essex/openstack-compute/install/apt/content/

# Not suitable for production



# I'm serious!


echo LIST OF IPS ON THE SYSTEM
iplist=`ifconfig -a | grep "inet addr" | sed 's/^ *//g' | sed 's/inet addr://g' | cut -f 1 -d ' ' | grep -v 127.0.0.1`
echo $iplist
echo "(Enter nothing for:  `echo $iplist | head -n 1` )"
read ipaddress
if [ "$ipaddress" = "" ]; then
	ipaddress=`echo $iplist | head -n 1`
	if  [ "$ipaddress" = "" ]; then
		echo "Error, default ip is blank, exiting!"
		exit
	fi
fi
apt-get update
apt-get upgrade
apt-get -y install keystone python-yaml
rm /var/lib/keystone/keystone.db
apt-get -y install python-mysqldb mysql-server
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
apt-get -y install pwgen
keystonepassword=`pwgen -s 30 1 | tee keystone-password`
sed -i "s/keystone-password/$keystonepassword/g" mysql-create-keystone.sql

echo enter mysql root password to add keystone user + database
mysql -f -u root -p < mysql-create-keystone.sql
service mysql restart
sed -i "s#connection = sqlite:////var/lib/keystone/keystone.db#connection = mysql://keystone:$keystonepassword@$ipaddress/keystone#g" /etc/keystone/keystone.conf
sed -i "s/admin_token = ADMIN/admin_token = 012345SECRET99TOKEN012345/g" /etc/keystone/keystone.conf
service keystone restart
keystone-manage db_sync
apt-get -y install git
git clone https://github.com/nimbis/keystone-init.git
sed -i.bak s/192.168.206.130/$ipaddress/g keystone-init/config.yaml
keystone-init/keystone-init.py keystone-init/config.yaml

apt-get -y install glance
rm /var/lib/glance/glance.sqlite
glancepassword=`pwgen -s 30 1 | tee glance-password`
sed -i "s/glance-password/$glancepassword/g" mysql-create-glance.sql
sed -i "s/%SERVICE_USER%/glance/g" /etc/glance/*
sed -i "s/%SERVICE_PASSWORD%/glance/g" /etc/glance/*
sed -i "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/*
echo "[paste_deploy]
flavor = keystone" >> /etc/glance/glance-api.conf
service glance-api restart
echo "[paste_deploy]
flavor = keystone
" >> /etc/glance/glance-registry.conf
sed -i "s/pipeline = context registryapp/pipeline = authtoken auth-context context registryapp/g" /etc/glance/glance-registry-paste.ini
sed -i "s#sql_connection = sqlite:////var/lib/glance/glance.sqlite#sql_connection = mysql://keystone:$keystonepassword@$ipaddress/keystone#g" /etc/glance/glance-registry.conf
glance-manage version_control 0
glance-manage db_sync
service glance-registry restart
service glance-api restart
mkdir /tmp/testimage
cd /tmp/testimage
wget http://smoser.brickies.net/ubuntu/ttylinux-uec/ttylinux-uec-amd64-12.1_2.6.35-22_1.tar.gz
tar -zxvf ttylinux-uec-amd64-12.1_2.6.35-22_1.tar.gz

glance --os_username=adminUser --os_password=secretword --os_tenant=openstackDemo --os_auth_url=http://127.0.0.1:5000/v2.0 add name="tty-linux-kernel" disk_format=aki container_format=aki < ttylinux-uec-amd64-12.1_2.6.35-22_1-vmlinuz

glance --os_username=adminUser --os_password=secretword --os_tenant=openstackDemo --os_auth_url=http://127.0.0.1:5000/v2.0 add name="tty-linux-ramdisk" disk_format=ari container_format=ari < ttylinux-uec-amd64-12.1_2.6.35-22_1-loader

glance --os_username=adminUser --os_password=secretword --os_tenant=openstackDemo --os_auth_url=http://127.0.0.1:5000/v2.0 add name="tty-linux" disk_format=ami container_format=ami kernel_id=599907ff-296d-4042-a671-d015e34317d2 ramdisk_id=7d9f0378-1640-4e43-8959-701f248d999d < ttylinux-uec-amd64-12.1_2.6.35-22_1.img


glance --os_username=adminUser --os_password=secretword --os_tenant=openstackDemo --os_auth_url=http://127.0.0.1:5000/v2.0 index











apt-get install rabbitmq-server
apt-get install nova-compute nova-volume nova-vncproxy nova-api nova-ajax-console-proxy nova-cert nova-consoleauth nova-doc nova-scheduler nova-network

