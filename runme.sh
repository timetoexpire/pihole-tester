#!/bin/bash

# You might need to install (sshpass)
# sudo apt install sshpass
# You might need to install (nslookup)
# sudo apt install dnsutils
# You might need to install (nmcli) 
# sudo apt install network-manager

# You might need to authorise ssh fingerprint ie pi@pi-hole.local
# ssh -o "StrictHostKeyChecking no" pi@pi-hole.local

domain=$1
if [ -z $domain ];
then
  echo "Need domain name"
  exit 1
fi

let frame=0
starttime=$(date '+%Y%m%d-%H%M%S')

rpiholescript="./phs.sh" # pi-hole server
rpiholelocal="./nsp.sh" # local host nameserver ping

rpiholehost="pi-hole.local"
#rpiholehost="10.1.1.2"

rpiholeuser="pi"
rpiholepass="abc1234567890"

rpiholerefreshdelay=15

rpiholedirectory="./PHT-$starttime/"

if [ ! -f $rpiholescript ];
then
  echo "file does not exist rpiholescript: $rpiholescript"
  exit 1
fi

if [ ! -f $rpiholelocal ];
then
  echo "file does not exist rpiholelocal: $rpiholelocal"
  exit 1
fi

mkdir $rpiholedirectory
if [ ! -d $rpiholedirectory ];
then
  # this should never happen, might be due chown issue
  echo "Unable to find directory $rpiholedirectory"
  exit 1
fi

# https://github.com/timetoexpire/shelltoolset/blob/main/keypress_timeout.sh
function input_keypressed (){
  read -n1 -s -t$char_timeout input_result
}

function input_notice (){
  if [ ! -z "$input_echo" ];
  then
    echo "$input_echo"
  fi
  input_output=""
}

function input_isnull (){
  if [ -z "$input_result" ];
  then
    echo "the silent treatment"
  else
    echo "You press [$input_result]"
  fi
}

function input_check (){
  # Input [input_echo]
  # Output [input_result]
  input_notice
  input_keypressed
}


function get_date (){
  # Output [date_unix]
  date_unix=$(date '+%s')
}

function set_timeout (){
  # Input [timeout_amount]
  # Output [timeout_result]
  get_date
  timeout_result=$(( $date_unix + $timeout_amount ))
}

function hold_timeout_key (){
  # Input [timout_amount]
  # Output [input_result]
  set_timeout
  input_result=""
  until [[ $timeout_result -lt $date_unix ]] || [[ ! -z "$input_result" ]]
  do
    input_check
    get_date
  done
}

function exiting_script (){
  echo "EXITING SCRIPT, Please Wait..."
  temp_scriptname="./temp_pi_hole.sh"
  if [ -f "$temp_scriptname" ];
  then
    echo "already exists: $temp_scriptname, you need to delete it"
  else
    echo "#!/bin/bash" >$temp_scriptname
    echo "mkdir '/home/$rpiholeuser/piholelog-$starttime/'" >>$temp_scriptname
    echo "pihole logging off" >>$temp_scriptname
    echo "pihole debug" >>$temp_scriptname
    echo "echo 'Short break'" >>$temp_scriptname
    echo "sleep 3" >>$temp_scriptname
    echo "sudo cp /var/log/pihole/*.log /home/$rpiholeuser/piholelog-$starttime/" >>$temp_scriptname
    echo "sudo chown $rpiholeuser:$rpiholeuser /home/$rpiholeuser/piholelog-$starttime/*.log" >>$temp_scriptname
    echo "tar -cjf /home/$rpiholeuser/piholelogs-$starttime.tar.gz /home/$rpiholeuser/piholelog-$starttime/" >>$temp_scriptname
    sshpass -p $rpiholepass ssh $rpiholeuser@$rpiholehost 'bash -s' < $temp_scriptname
    rm $temp_scriptname
    echo "There logs file on Pi-Hole /home/$rpiholeuser/piholelogs-$starttime.tar.gz"
  fi
  tar -cjf ./PHT-$starttime.tar.gz $rpiholedirectory
  echo "Created archive of frames at ./PHT-$starttime.tar.gz"
  exit 0
}


function keypressed_option (){
  # Input [input_result]
  case $input_result in
    "1")
      :
#      black_add
      ;;
    "2")
      :
#      black_remove
      ;;
#    "3")
#      black_enable
#      ;;
#    "4")
#      black_disable
#      ;;
    "5")
      :
#      white_add
      ;;
    "6")
      :
#      white_remove
      ;;
#    "7")
#      white_enable
#      ;;
#    "8")
#      white_disable
#      ;;
    "Q")
      exiting_script
      ;;
    *)
      echo "Invaled selection [$input_result]"
      input_result=""
      sleep 1
      ;;
  esac

}

function ssh_command_fun (){
  if [ -z "$ssh_command" ];
  then
    echo "ssh_single_command ssh_command=null"
    exit 1
  fi
  sshpass -p $rpiholepass ssh -t $rpiholeuser@$rpiholehost 'bash ' $ssh_command
  ssh_command=""
}

echo "Seting PI-Hole logging, Please Wait"
ssh_command="pihole flush"
ssh_command_fun
ssh_command="pihole logging on"
ssh_command_fun

while :
do
  let frame++
  leadingzeroframe=$(printf %05d $frame)
  clear
  teefilename=$rpiholedirectory"report-"$leadingzeroframe"-"$starttime
  echo "hostname [$HOSTNAME] domain [$domain] frame $leadingzeroframe at [$(date '+%Y%m%d-%H%M%S')] start at [$starttime]" | tee $teefilename
  if [ ! -f $teefilename ];
  then
    echo "** UNABLE TO CREATE REPORT FILE $teefilename **"
    #exit 1
  fi
#  echo "#> [sshpass -p $rpiholepass ssh $rpiholeuser@$rpiholehost 'bash -s' < $rpiholescript $domain $rpiholescript $input_result]"
  echo "*** [CONNECTING] SSH $rpiholeuser@$rpiholehost" | tee -a $teefilename
  sshpass -p $rpiholepass ssh $rpiholeuser@$rpiholehost 'bash -s' < $rpiholescript $domain $rpiholescript $input_result| tee -a $teefilename
  echo "*** [EXITING] SSH $rpiholeuser@$rpiholehost" | tee -a $teefilename

  echo "*** [TESTING] localhost $rpiholelocal" | tee -a $teefilename

  /bin/bash $rpiholelocal $domain | tee -a $teefilename

  echo "*** [TESTED] localhost $rpiholelocal" | tee -a $teefilename

  char_timeout=0.2
  timeout_amount=$rpiholerefreshdelay
  echo "Blacklist: 1=Add 2=Remove " #3=Enable 4=Disable" These actions are not possiable
  echo "Whitelist: 5=Add 6=Remove " #7=Enable 8=Disable" These actions are not possibale
  echo "Quit Q"
  hold_timeout_key
  if [ ! -z "$input_result" ];
  then
    echo "Keypressed [$input_result]" | tee -a $teefilename
    keypressed_option
    sleep 1
  fi
done

