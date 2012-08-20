#!/bin/bash

ls ~/.vnc/*.pid |xargs -n1 cat |xargs kill
/usr/bin/lsof -u $( whoami )|grep \/.vnc\/ | cut -d" " -f2|sort -igub |xargs kill
ps -au $( whoami ) |grep -v ssh |grep -v bash | grep -v PID|cut -d " " -f1 |sort -igub |xargs kill
sleep 2
/usr/bin/lsof -u $( whoami )|grep \/.vnc\/ | cut -d" " -f2|sort -igub |xargs kill -9
ps -au $( whoami ) |grep -v ssh |grep -v bash | grep -v PID|cut -d " " -f1 |sort -igub |xargs kill -9
sleep 2
rm -rf ~/.vnc/

echo "Ok.. Killed"
