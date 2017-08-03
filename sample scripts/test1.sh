#!/bin/bash
txfirst=`ifconfig eth0 | grep "TX bytes:" | cut -d ":" -f3 | cut -d " " -f1`
datefirst=`date +%s`
loop=1
while [ loop=1 ]
do
txnew=`ifconfig eth0 | grep "TX bytes:" | cut -d ":" -f3 | cut -d " " -f1`
datenew=`date +%s`
if [ $txnew -gt $txfirst ]
then
transferred=$((txnew-txfirst))
timelapsed=$((datenew-datefirst))
if [ $x > 0 ]
then
bytessec=$(($transferred/$timelapsed))
echo "$bytessec bytes/sec"
fi
txfirst=$((txnew))
datefirst=$((datenew))
else
txfirst=$((txnew))
datefirst=$((datenew))
fi
sleep 55
x=$(($x+1))
done
