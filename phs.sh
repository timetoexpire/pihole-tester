#!/bin/bash

# pi-hole server
# not meant to be run localy

domain=$1
scriptname=$2
input_result=$3

if [ -z $domain ];
then
  echo "PHS: Need domain name"
  exit 1
fi

if [ -z $scriptname ];
then
  echo "PHS: Need script name"
  exit 1
fi

echo "*********************** $input_result"

function phs_option (){
  # Input [input_result]
  case $input_result in
    "1")
      echo " "
      echo "#> pihole -b $domain"
      pihole -b $domain
      ;;
    "2")
      echo " "
      echo "#> pihole -b -d $domain"
      pihole -b -d $domain
      ;;
#    "3")
#      black_enable
#      ;;
#    "4")
#      black_disable
#      ;;
    "5")
      echo " "
      echo "#> pihole -w $domain"
      pihole -w $domain
      ;;
    "6")
      echo " "
      echo "#> pihole -w -d $domain"
      pihole -w -d $domain
      ;;
#    "7")
#      white_enable
#      ;;
#    "8")
#      white_disable
#      ;;
    *)
      # This should never happen
      echo "PHS: Invaled selection [$input_result]"
      exit 1
      ;;
  esac
}


# ifconfig only works when /sbin/ifconfig
temp_arr=($(/sbin/ifconfig eth0 | grep "inet "))
ipvfour=${temp_arr[1]}

echo "Script [$scriptname] hostname [$HOSTNAME] ipv4 [$ipvfour] date [$(date '+%Y%m%d-%H%M%S')]"
echo "#> pihole -v -c"
pihole -v -c
echo "#> pihole status"
pihole status

if [ ! -z $input_result ];
then
  echo "input_result $input_result"
  phs_option
  sleep 2
fi

echo " "
echo "#> pihole -q $domain"
pihole -q $domain
echo " "
echo "#> pihole -w -l"
pihole -w -l
echo " "
echo "#> pihole -b -l"
pihole -b -l
