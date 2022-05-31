#!/bin/bash
server="$1"
offset="$(echo $(tput lines)/3|bc)"
output="$(curl -s --location --request POST 'https://worldofwarcraft.com/graphql' --header 'Content-Type: application/json' --data-raw '{
    "operationName": "GetInitialRealmStatusData",
    "variables": {
        "input": {
            "compoundRegionGameVersionSlug": "us"
        }
    },
    "extensions": {
        "persistedQuery": {
            "version": 1,
            "sha256Hash": "9c7cc66367037fda3007b7f592201c2610edb2c9a9292975cd131a37bbe61930"
        }
    }
}'|jq --arg server "$server" '.data.Realms | .[] | select (.name == $server) | .name,.online' | tr '[a-z]' '[A-Z]' )"
while [[ $offset > 0 ]]
do let offset--
   echo
done
output="$(echo "$output"|sed -e 's/FALSE/OFFLINE/'|sed -e 's/TRUE/ONLINE/')"
figlet -c -t "$output"
figlet -c -t "$(date +%T)"
