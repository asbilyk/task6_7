#! /bin/bash

source vm1.config
export $(cut -d= -f1 vm1.config)
envsubst < default '$HTTP_SERV_IP', '$HTTPS_PORT' > /etc/nginx/site-enabled/default


modprobe 8021q
vconfig add $INT_IF $VLAN_ID
ip addr add $VLAN_IP dev $INT_IF:$VLAN_ID
ip link set up $INT_IF:$VLAN_ID

sysctl net.ipv4.ip_forward=1

echo "nameserver 8.8.8.8" > /etc/resolv.conf

iptables -t nat -A POSTROUTING -o $EXT_IF -j MASQUERADE
ip addr add $EXT_IP dev $EXT_IF
ip link set up $EXT_IF
ip route add default via $GW_IP

apt-get install nginx -y -q

mkdir -p /etc/ssl/certs
openssl genrsa -out /etc/ssl/certs/root-ca.key 4096
openssl req -x509 -new -nodes -key /etc/ssl/certs/root-ca.key -sha256 -days 365 -out /etc/ssl/certs/root-ca.crt -subj "/C=UA/ST=Kharkiv/L=Kharkiv/CN=vm1/"
openssl genrsa -out /etc/ssl/certs/web.key 2048
openssl req -new -out /etc/ssl/certs/web.csr -key /etc/ssl/certs/web.key -subj "/C=UA/ST=Kharkiv/L=Kharkiv/CN=vm1/"
openssl req -x509 -in  /etc/ssl/certs/web.csr -CA /etc/ssl/certs/root-ca.crt -CAkey /etc/ssl/certs/root-ca.key -CAcreateserial -out /etc/ssl/certs/web.crt

cat /etc/ssl/certs/root-ca.crt /etc/ssl/certs/web.crt > /etc/ssl/certs/web-ca-cert

service nginx restart
