#!/bin/bash

# Receiving command line arguments from user
host=$1		  		# MySQL server IP address
username=$2			# MySQL User name
password=$3			# MySQL Password
dump_file_location=$4	# Source Directory of the .tar.bz2 file. without the extension

function restore_db()
{
	local db_name="$1"
	local source_dump="$2"
	echo "Restoring ..... $db_name"
	mysql -h $host -u $username -p$password -e "create database $db_name" 2>>/dev/null
	mysql -h $host -u $username -p$password $db_name < $source_dump
}

all_files=$(tar xvjf $dump_file_location.tar.bz2 2>>/dev/null)

#printf "%s\n" "${all_files[@]}"

# Find the extracted files directory
arrIN=(${dump_file_location//\// })  # split string using "/"
#printf "%s\n" "${arrIN[@]}"
for var in "${arrIN[@]}"; do
	root_folder="$var"
done
#echo "Root folder : $root_folder"

# Reading all DB names from the GCSDBLIST.txt file
db_names=()
i=0
while read line
do           
	db_names[$i]="$line"
	(( i++ ))
done < $root_folder"/GCSDBLIST.txt"

# Getting the list of .sql file names
i=0
sql_file_names=()
for var in "${all_files[@]}"; do
	arrIN=(${var//\// })
	for var in "${arrIN[@]}"; do
		test=$(echo $var | grep "^.*sql")
		if [ $? -eq "0" ]
		then
			sql_file_names[$i]="$var"
			(( i++ ))
		fi
	done
done

#printf "%s\n" "${sql_file_names[@]}"

for sql_file in "${sql_file_names[@]}"; do
	for db_name in "${db_names[@]}"; do
		test=$(echo $sql_file | grep $db_name"\.sql")
		if [ $? -eq "0" ]
		then
			test=$(echo $sql_file | grep "^GCS.*") # Check for the Database name starts with "GCS"
			if [ $? -eq "0" ]
			then
				restore_db $db_name $root_folder"/GCS/"$sql_file
			fi

			test=$(echo $sql_file | grep "^MO_.*") # Check for the Database name starts with "MO_"
			if [ $? -eq "0" ]
			then
				serial=$(echo $db_name | sed s'/^MO_.*_\(.*\)/\1/g')
				restore_db $db_name $root_folder"/"$serial"/"$sql_file
			fi
		fi
	done
done
