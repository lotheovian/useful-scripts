#!/bin/bash
stty -echo
conf="$(echo ~/.go_config)"
data_max="$(wc -l ~/.go_config|awk '{print $1}')"
display_max="$(( $(tput lines) - 2 ))"
sel_line=""

function do_search() {
  grep -i "$search" "$conf"
}

function reset_tty() {
   tput sgr0
   reset
   exit $1
}

trap 'reset_tty 1' SIGINT

function get_display() {
   # Determine Display Scope
   start_display=0
   end_display="$data_max"
   if [[ "$display_max" -lt "$data_max" ]]
   then # we need to shrink the display
        if [[ "$sel_line" -lt "$display_max" ]]
        then end_display="$display_max"
        else start_display="$(( $sel_line - $display_max))"
             end_display="$sel_line"
        fi
   fi
   # Render display
   tput sgr0
   tput clear
   printf "Search: $search"
   cur_line="$(( $start_display + 1 ))"
   echo "$body" |
   awk "NR <= $end_display"|
   awk "NR > $start_display"|
   cut -d '|' -f 1-3|
   while read -r line
   do if [ "$sel_line" == "$cur_line" ]
      then tput rev
      else tput sgr0
      fi
      printf "\n%02d: ${line}" "$cur_line"
      let cur_line++
   done
}
search=""
sel_line=1
while :
do ord=""
   while :
   do selection="$(do_search | awk "NR == $sel_line")"
      case "$ord" in
          0) break;; # exit the first while loop
          4) break 2;; # exit the second while loop
          27) read -t1 -n2 x
              ord="$( LC_CTYPE=C printf '%d' "'${x:1}")"
              case "$ord" in
   	       65) if [ "$sel_line" -gt "1" ]
                   then let sel_line--
                   else sel_line="$data_max"
                   fi;;
   	       66) if [ "$sel_line" -lt "$data_max" ]
                   then let sel_line++
                   else sel_line=1
                   fi;;
              esac;;
          127) search="${search::${#search}-1}";;
          *) search+="$x";;
      esac
      body="$(do_search)"
      data_max="$(wc -l <<<"$body"|tr -d ' ')"
      if [ "$sel_line" -le "0" ]
      then sel_line=1
      elif [ "$sel_line" -gt "$data_max" ] #data max might shrink after search
      then sel_line="$data_max"
      fi
      output="$(get_display)"
      echo "$output"
      tput cup -1 $(( ${#search} + 8 ))
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
reset_tty 0
