#!/bin/bash
stty -echo
conf="$(echo ~/.go_config)"
line_max="$(wc -l ~/.go_config|awk '{print $1}')"

function do_search() {
  grep -i "$search" "$conf"
}

function reset_tty() {
   tput sgr0
   reset
   exit 1
}

trap 'reset_tty' SIGINT

function get_display() {
   body="$(do_search)"
   line_max="$(wc -l <<<"$body"|tr -d ' ')" 
   if [ "$sel_line" -le "0" ]
   then sel_line=1
   elif [ "$sel_line" -gt "$line_max" ]
   then sel_line="$line_max"
   fi
   tput sgr0
   tput clear
   printf "Search: $search"
   tput sc
   printf "\n\n" 
   cur_line=1
   echo "$body" | 
   cut -d '|' -f 1-3|
   while read -r line
   do if [ "$sel_line" == "$cur_line" ]
      then tput rev
      else tput sgr0
      fi
      echo "$line"
      let cur_line++
   done
   tput rc
}
tput civis

while : 
do sel_line=1
   ord=""
   search=""
   while :
   do selection="$(do_search | awk "NR == $sel_line")"
      case "$ord" in
          0) break;; # Exit the while loop
          4) exit;; # Exit the while loop
          27) read -t1 -n2 x
              ord="$( LC_CTYPE=C printf '%d' "'${x:1}")"
              case "$ord" in
   	       65) if [ "$sel_line" -gt "1" ]
                   then let sel_line--
                   else sel_line="$line_max"
                   fi;;
   	       66) if [ "$sel_line" -lt "$line_max" ]
                   then let sel_line++
                   else sel_line=1
                   fi;;
              esac;;
          127) search="${search::${#search}-1}";;
          *) search+="$x";;
      esac 
      output="$(get_display)"
      echo "$output"
      read -sn 1 x
      ord="$( LC_CTYPE=C printf '%d' "'$x")"
      if [ "$DEBUG" == 1 ]
      then tput clear
           printf "\nread:%s:%s\n\n" "$ord" "$x"
           read -p "Any key to continue" -n1
      fi
   done
   tput clear
   tput sgr0
   IFS='|' read -r USERNAME SERVER DESCRIPTION SSH_OPTIONS <<< "$selection"
   echo launching $DESCRIPTION
   echo "ssh $SSH_OPTIONS $USERNAME@$SERVER"
   stty echo
   ssh $SSH_OPTIONS $USERNAME@$SERVER
   stty -echo
done
