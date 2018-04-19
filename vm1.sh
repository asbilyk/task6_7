#!/bin/bash

source vm1.config
export $(cut -d= -f1 vm1.config)

modprobe 8021q
vconfig add $INTERNAL_IF $VLAN
ip addr add $VLAN_IP dev $INTERNAL_IF:$VLAN
ip link set up $INTERNAL_IF:$VLAN

sysctl net.ipv4.ip_forward=1

echo "nameserver 8.8.8.8" > /etc/resolv.conf
ifup $INTERNAL_IF
ifup $EXTERNAL_IF

iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE
ip addr add $EXT_IP dev $EXTERNAL_IF
ip link set up $EXTERNAL_IF
ip route add default via $GW_IP

IP=$(ifconfig $EXTERNAL_IF|grep 'inet addr'|cut -d: -f2|awk '{print $1}')
apt-get update && apt-get install nginx -y -q

echo "
server {
        listen $IP:$NGINX_PORT ssl;
	ssl on;
	server_name $(hostname);
	ssl_certificate /etc/ssl/certs/root-ca.crt;
	ssl_certificate_key /etc/ssl/private/web.key;	 
	location / {
		proxy_pass http://$APACHE_VLAN_IP;	

	}
}" > /etc/nginx/site-available/default
mkdir -p /etc/ssl/certs
openssl genrsa -out /etc/ssl/certs/root-ca.key 4096
openssl req -x509 -new -nodes -key /etc/ssl/certs/root-ca.key -sha256 -days 365 -out /etc/ssl/certs/root-ca.crt -subj "/C=UA/ST=Kharkiv/L=Kharkiv/OU=Mirantis/CN=vm1/"
openssl genrsa -out /etc/ssl/certs/web.key 2048
openssl req -new -out /etc/ssl/certs/web.csr -key /etc/ssl/certs/web.key -subj "/C=UA/ST=Kharkiv/L=Kharkiv/OU=Mirantis/CN=vm1/"
openssl req -x509 -in  /etc/ssl/certs/web.csr -CA /etc/ssl/certs/root-ca.crt -CAkey /etc/ssl/certs/root-ca.key -CAcreateserial -out /etc/ssl/certs/web.crt

cat /etc/ssl/certs/root-ca.crt /etc/ssl/certs/web.crt > /etc/ssl/certs/web-ca-cert

service nginx restart
