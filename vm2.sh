#! /bin/bash
apt-get update && apt-get install apache2 -y -q

source vm2.config
export $(cut -d= -f1 vm2.config)
envsubst < 000-default.conf 'HTTP_SERV_IP'> /etc/apache2/sites-enabled/000-default.conf

modprobe 8021q
vconfig add $INT_IF $VLAN_ID
ip addr add $HTTP_SERV_IP dev $INT_IF:$VLAN_ID
ip link set up $INT_IF:$VLAN_ID
ip route add default via $GW_IP

