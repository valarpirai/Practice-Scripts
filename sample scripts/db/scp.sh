#!/bin/bash

devpwd="np@123"

expect -c "
   set timeout 10
   spawn scp /tmp/20-Aug-2013w.tar.bz2 testcom@192.168.1.94:/tmp
   expect yes/no { send yes\r ; exp_continue }
   expect password: { send $devpwd\r }
   expect 100%
   sleep 1
   exit
"

echo $res
echo $devpwd
echo "Finished" 
