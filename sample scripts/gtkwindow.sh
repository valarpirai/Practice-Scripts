#!/bin/sh

#zenity --forms --title="Add Friend" \
#	--text="Enter information about your friend." \
#	--separator="," \
#	--add-entry="First Name" \
#	--add-entry="Family Name" \
#	--add-entry="Email" \
#	--add-calendar="Birthday" >> addr.csv

#case $? in
#    0)
#        echo "Friend added.";;
#    1)
#        echo "No friend added."
#	;;
#    -1)
#        echo "An unexpected error has occurred."
#	;;

#esac

FILE=`zenity --file-selection --title="Select a File"`

case $? in
         0)
		#echo "\"$FILE\" selected.";;
                zenity --info --text="\"$FILE\" selected.";;

         1)
		#echo "No file selected.";;
		zenity --info --text="No file selected.";;

        -1)
		#echo "An unexpected error has occurred.";;
		zenity --info --text="An unexpected error has occurred.";;
esac


function show_main_window(){


}
