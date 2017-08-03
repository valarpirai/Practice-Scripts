#!/bin/bash
 
echo "Shell Script To Get User Input";
 
while read inputline
do
what="$inputline"
echo $what;
 
if [ -z "${what}" ];
then
exit
fi
 
done
