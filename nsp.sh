#!/bin/bash

domain=$1

if [ -z $domain ];
then
  echo "NSP: Need domain name"
  exit 1
fi

echo "#> nslookup $domain"
nslookup $domain

echo " "
echo "#> ping $domain -c 1 -4 "
ping $domain -c 1 -4
#ping $domain -c 1

echo " "
echo "#> ping $domain -c 1 -6 "
ping $domain -c 1 -6
#ping6 $domain -c 1

echo " "
echo "#> tail /etc/resolv.conf"
#tail /etc/resolv.conf
   head -n3 /etc/resolv.conf
