#/bin/bash
cd ~

COINCLI=arcticcoin-cli
COIND=arcticcoind
COIN=arcticcoin

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIND$ALIAS.service
[Unit]
Description=$COIND$ALIAS service
After=network.target
 [Service]
User=root
Group=root
 Type=forking
#PIDFile=/root/.$COIN_$ALIAS/transcendenced.pid
 ExecStart=/root/bin/$COIND_$ALIAS.sh
ExecStop=-/root/bin/$COINCLI_$ALIAS.sh stop
 Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
 [Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 6
  crontab -l > cron$ALIAS
  echo "@reboot systemctl start $COIND$ALIAS" >> cron$ALIAS
  crontab cron$ALIAS
  rm cron$ALIAS
  systemctl start $COIND$ALIAS.service
}
IP4=$(curl -s4 api.ipify.org)
perl -i -ne 'print if ! $a{$_}++' /etc/network/interfaces
if [ ! -d "/root/bin" ]; then
 DOSETUP="y"
else
 DOSETUP="n"
fi
clear
echo "1 - Create new nodes"
echo "2 - Remove an existing node"
echo "3 - Upgrade an existing node"
echo "4 - List aliases"
echo "What would you like to do?"
read DO
echo ""
if [ $DO = "4" ]
then
ALIASES=$(find /root/.${COIN}_* -maxdepth 0 -type d | cut -c22-)
echo -e "${GREEN}${ALIASES}${NC}"
echo ""
echo "1 - Create new nodes"
echo "2 - Remove an existing node"
echo "3 - Upgrade an existing node"
echo "4 - List aliases"
echo "What would you like to do?"
read DO
echo ""
fi
if [ $DO = "3" ]
then
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc >/dev/null 2>&1
echo "Enter the alias of the node you want to upgrade"
read ALIAS
  echo -e "Upgrading ${GREEN}${ALIAS}${NC}. Please wait."
  sed -i '/$ALIAS/d' .bashrc
  sleep 1
  ## Config Alias
  echo "alias ${ALIAS}_status=\"$COINCLI -datadir=/root/.$COIN_$ALIAS masternode status\"" >> .bashrc
  echo "alias ${ALIAS}_stop=\"$COINCLI -datadir=/root/.$COIN_$ALIAS stop && systemctl stop $COIND$ALIAS\"" >> .bashrc
  echo "alias ${ALIAS}_start=\"/root/bin/$COIND_${ALIAS}.sh && systemctl start $COIND$ALIAS\""  >> .bashrc
  echo "alias ${ALIAS}_config=\"nano /root/.${COIN}_${ALIAS}/$COIN.conf\""  >> .bashrc
  echo "alias ${ALIAS}_getinfo=\"$COINCLI -datadir=/root/.$COIN_$ALIAS getinfo\"" >> .bashrc
  configure_systemd
  sleep 1
  source .bashrc
  echo -e "${GREEN}${ALIAS}${NC} Successfully upgraded."
fi
if [ $DO = "2" ]
then
perl -i -ne 'print if ! $a{$_}++' /etc/monit/monitrc >/dev/null 2>&1
echo "Input the alias of the node that you want to delete"
read ALIASD
echo ""
echo -e "${GREEN}Deleting ${ALIASD}${NC}. Please wait."
## Removing service
systemctl stop $COIND$ALIASD >/dev/null 2>&1
systemctl disable $COIND$ALIASD >/dev/null 2>&1
rm /etc/systemd/system/${COIND}${ALIASD}.service >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
systemctl reset-failed >/dev/null 2>&1
## Stopping node
$COIND -datadir=/root/.$COIN_$ALIASD stop >/dev/null 2>&1
sleep 5
## Removing monit and directory
rm /root/.$COIN_$ALIASD -r >/dev/null 2>&1
sed -i '/$ALIASD/d' .bashrc >/dev/null 2>&1
sleep 1
sed -i '/$ALIASD/d' /etc/monit/monitrc >/dev/null 2>&1
monit reload >/dev/null 2>&1
sed -i '/$ALIASD/d' /etc/monit/monitrc >/dev/null 2>&1
crontab -l -u root | grep -v $COIND$ALIASD | crontab -u root - >/dev/null 2>&1
source .bashrc
echo -e "${ALIASD} Successfully deleted."
fi
if [ $DO = "1" ]
then
echo "1 - Easy mode"
echo "2 - Expert mode"
echo "Please select a option:"
read EE
echo ""
if [ $EE = "1" ] 
then
MAXC="32"
fi
if [ $EE = "2" ] 
then
echo ""
echo "Enter max connections value"
read MAXC
fi
if [ $DOSETUP = "y" ]
then
  echo -e "Installing ${GREEN}${COIN} dependencies${NC}. Please wait."
  sudo apt-get update 
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get update
  sudo apt-get install -y zip unzip bc curl nano
  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img 
  sudo swapon /var/swap.img 
  sudo free 
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd
 if [ ! -f Linux.zip ]
  then
  wget https://github.com/phoenixkonsole/transcendence/releases/download/v1.1.0.0/Linux.zip  
 fi
  unzip Linux.zip 
  chmod +x Linux/bin/* 
  sudo mv  Linux/bin/* /usr/local/bin
  rm -rf Linux.zip Windows Linux Mac
  sudo apt-get install -y ufw 
  sudo ufw allow ssh/tcp 
  sudo ufw limit ssh/tcp 
  sudo ufw logging on
  echo "y" | sudo ufw enable 
  mkdir -p ~/bin 
  echo 'export PATH=~/bin:$PATH' > ~/.bash_aliases
  source ~/.bashrc
  echo ""
fi
if [ ! -f DynamicChain.zip ]
then
wget https://github.com/Lagadsz/Transcendence-Dynamic-Chain/releases/download/v0.1/DynamicChain.zip
fi
IP4COUNT=$(find /root/.transcendence_* -maxdepth 0 -type d | wc -l)

echo -e "Telos nodes currently installed: ${GREEN}${IP4COUNT}${NC}"
echo ""
echo "How many nodes do you want to install on this server?"
read MNCOUNT
let COUNTER=0
let MNCOUNT=MNCOUNT+IP4COUNT
let COUNTER=COUNTER+IP4COUNT
while [  $COUNTER -lt $MNCOUNT ]; do
 PORT=22123
 PORTD=$((22123+$COUNTER))
 RPCPORTT=$(($PORT*10))
 RPCPORT=$(($RPCPORTT+$COUNTER))
  echo ""
  echo "Enter alias for new node"
  read ALIAS
  CONF_DIR=~/.transcendence_$ALIAS
  echo ""
  echo "Enter masternode private key for node $ALIAS"
  read PRIVKEY
  if [ $EE = "2" ] 
	then
	echo ""
	echo "Enter port for $ALIAS"
	read PORTD
  fi
  mkdir ~/.transcendence_$ALIAS
  unzip DynamicChain.zip -d ~/.transcendence_$ALIAS >/dev/null 2>&1
  echo '#!/bin/bash' > ~/bin/transcendenced_$ALIAS.sh
  echo "transcendenced -daemon -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendenced_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/transcendence-cli_$ALIAS.sh
  echo "transcendence-cli -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-cli_$ALIAS.sh
  echo '#!/bin/bash' > ~/bin/transcendence-tx_$ALIAS.sh
  echo "transcendence-tx -conf=$CONF_DIR/transcendence.conf -datadir=$CONF_DIR "'$*' >> ~/bin/transcendence-tx_$ALIAS.sh
  chmod 755 ~/bin/transcendence*.sh
  mkdir -p $CONF_DIR
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> transcendence.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> transcendence.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> transcendence.conf_TEMP
  echo "rpcport=$RPCPORT" >> transcendence.conf_TEMP
  echo "listen=1" >> transcendence.conf_TEMP
  echo "server=1" >> transcendence.conf_TEMP
  echo "daemon=1" >> transcendence.conf_TEMP
  echo "logtimestamps=1" >> transcendence.conf_TEMP
  echo "maxconnections=$MAXC" >> transcendence.conf_TEMP
  echo "masternode=1" >> transcendence.conf_TEMP
  echo "dbcache=50" >> transcendence.conf_TEMP
  echo "maxorphantx=10" >> transcendence.conf_TEMP
  echo "maxmempool=100" >> transcendence.conf_TEMP
  echo "banscore=10" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "" >> transcendence.conf_TEMP
  echo "port=$PORTD" >> transcendence.conf_TEMP
  echo "masternodeaddr=$IP4:$PORT" >> transcendence.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> transcendence.conf_TEMP
  sudo ufw allow 22123/tcp
  mv transcendence.conf_TEMP $CONF_DIR/transcendence.conf
  echo ""
  echo -e "Your ip is ${GREEN}$IP4:$PORT${NC}"
  COUNTER=$((COUNTER+1))
	echo "alias ${ALIAS}_status=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS masternode status\"" >> .bashrc
	echo "alias ${ALIAS}_stop=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS stop && systemctl stop transcendenced$ALIAS\"" >> .bashrc
	echo "alias ${ALIAS}_start=\"/root/bin/transcendenced_${ALIAS}.sh && systemctl start transcendenced$ALIAS\""  >> .bashrc
	echo "alias ${ALIAS}_config=\"nano /root/.transcendence_${ALIAS}/transcendence.conf\""  >> .bashrc
	echo "alias ${ALIAS}_getinfo=\"transcendence-cli -datadir=/root/.transcendence_$ALIAS getinfo\"" >> .bashrc
	## Config Systemctl
	configure_systemd
done
echo ""
echo "Commands:"
echo "ALIAS_start"
echo "ALIAS_status"
echo "ALIAS_stop"
echo "ALIAS_config"
echo "ALIAS_getinfo"
fi
echo ""
echo "Made by lobo with the help of all Transcendence team "
echo "Transcendence Address for donations: GWe4v6A6tLg9pHYEN5MoAsYLTadtefd9o6"
echo "Bitcoin Address for donations: 1NqYjVMA5DhuLytt33HYgP5qBajeHLYn4d"
exec bash
exit
