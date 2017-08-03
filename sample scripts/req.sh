i=0
while [ $i -lt 100 ] 
do
#host -t a www.google.com
curl 74.125.236.177
i=`expr $i + 1`
done
