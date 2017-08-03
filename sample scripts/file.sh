#!/bin/sh -e
echo "Kanur don"
read va
echo "My name is $va"
read -p "Enter the value for a " a
read -p "Enter the value for b " b
c=`expr $a*$b`

echo "value of $a + $b = $c  `expr $a*$b`"
