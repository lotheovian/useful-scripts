#!/bin/bash
# Pseudo multithreading

declare cnt=0
declare -p cnt > /dev/shm/cnt
max_thread=25
inccnt() {
   . /dev/shm/cnt
   let cnt++
   declare -p cnt > /dev/shm/cnt
}
deccnt() {
   . /dev/shm/cnt
   let cnt--
   declare -p cnt > /dev/shm/cnt
}
threadWorker() {
   inccnt
   $*
   deccnt
}
scheduleThread () {
while [ true ]
do . /dev/shm/cnt
   if [ $cnt -lt $max_thread ]
   then threadWorker $* &
        break;
   fi
   sleep .1
done
}

i=0
for sleep_seconds in $(shuf -i 1-30 -n 100 -r)
do let i++
   . /dev/shm/cnt
   printf "thread #%s - %s - sleep for:%s\n" "$i" "$cnt" "$sleep_seconds"
   scheduleThread sleep "$sleep_seconds"
   sleep .25 
done
