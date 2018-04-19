#! /bin/bash

source vm2.config
export $(cut -d= -f1 vm2.config)

modprobe 8021q
vconfig add $INTERNAL_IF $VLAN
ip addr add $APACHE_VLAN_IP dev $INTERNAL_IF:$VLAN
ip link set up $INTERNAL_IF:$VLAN
ip route add default via $GW_IP
apt-get update && apt-get install apache2 -y -q $1>/dev/null
echo "
<VirtualHost *:80>
    ServerName $(hostname)
    DocumentRoot /var/www/html
<VirtualHost>" > /etc/apache2/sites-enable/000-default.conf

service apache2 restart

