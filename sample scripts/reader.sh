# /bin/bash

while true
do
  $ins=$(head -c1);
  cat $ins >> red.txt;
done

