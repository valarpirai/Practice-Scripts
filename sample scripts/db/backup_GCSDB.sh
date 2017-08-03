#!/bin/bash

# Receiving command line arguments from user
host=$1		  		# MySQL server IP address
username=$2			# MySQL User name
password=$3			# MySQL Password
backuplocation=$4	# Destination Directory to store the .sql files
remotelocation=$5	# Remote machine to store the .sql files
remotepasswd=$6		# Remote machine password

function backup_db()
{
	local db_name="$1"
	local destination="$2"
	echo $db_name >> GCSDBLIST.txt
	mysqldump -h $host -u $username -p$password $db_name > $destination >> /tmp/$timestamp".log"
}

function scp_file()
{
	local source="$1"
	local destination="$2"
	local passwd="$3"

	expect -c "
	   set timeout 30
	   spawn scp $source $destination
	   expect yes/no { send yes\r ; exp_continue }
	   expect password: { send $passwd\r ; exp_continue }
	   expect 100%
	   sleep 1
	   exit
	"
}

echo "Script Started."
echo "Show databases"
all_databases=$(mysql -h $host -u $username -p$password -e "show databases")

declare -a myarr=(`echo "$all_databases" | sed 's/ / /g'`)
sort_listed=()
i=0

echo "Backup databases"
timestamp=$(date +"%Y%m%d")
timestamp="${timestamp##*( )}"
backuplocation=$backuplocation"/"$timestamp

mkdir -p $backuplocation 2>/tmp/$timestamp".log"
cd $backuplocation
mkdir -p $backuplocation"/GCS/"

for var in "${myarr[@]}"
do
	test=$(echo $var | grep "^GCS.*") # Check for the Database name starts with "GCS"
	if [ $? -eq "0" ]
	then
		#echo "true $var"
		sort_listed[$i]="$var"
		(( i++ ))
		out_file=$backuplocation"/GCS/"$var".sql"
		backup_db $var $out_file
	fi
	
	test=$(echo $var | grep "^MO_.*") # Check for the Database name starts with "MO_"
	if [ $? -eq "0" ]
	then
		#echo "true $var"
		sort_listed[$i]="$var"
		(( i++ ))
		
		serial=$(echo $var | sed s'/^MO_.*_\(.*\)/\1/g')	# Cut the serial number from Database name starts with "MO_(*)_"
		mkdir -p $backuplocation"/"$serial 2>/tmp/$timestamp".log"
		out_file=$backuplocation"/"$serial"/"$var".sql"
		backup_db $var $out_file
	fi
done

<<comment
printf "%s\n" "${sort_listed[@]}" >> GCSDBLIST.txt
for database in "${sort_listed[@]}"
do
	out_file=$backuplocation"/"$database".sql"
	#backup_db $database $out_file
	#mysqldump -h $host -u $username -p$password $database > $out_file
done
comment

compressed_file=$backuplocation".tar.bz2"
echo -e "Compress files.\nOutput File is at $compressed_file"

cd ..
tar -jcvf $compressed_file $timestamp >> /tmp/$timestamp".log"
scp_file $compressed_file $remotelocation $remotepasswd  >> /tmp/$timestamp".log" 2>>/tmp/$timestamp".log"

echo "Script Finished."
