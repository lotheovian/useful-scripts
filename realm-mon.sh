#!/bin/bash
server="$1"
offset="$(echo $(tput lines)/3|bc)"
output="$(curl -sq  'https://worldofwarcraft.blizzard.com/graphql' \
  -H 'authority: worldofwarcraft.blizzard.com' \
  -H 'accept: */*' \
  -H 'accept-language: en-US' \
  -H 'content-type: application/json' \
  -H 'origin: https://worldofwarcraft.blizzard.com' \
  -H 'referer: https://worldofwarcraft.blizzard.com/en-us/game/status/us' \
  -H 'sec-ch-ua: "Google Chrome";v="107", "Chromium";v="107", "Not=A?Brand";v="24"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36' \
  -H 'x-static: false' \
  --data-raw '{"operationName":"GetInitialRealmStatusData","variables":{"input":{"compoundRegionGameVersionSlug":"us"}},"extensions":{"persistedQuery":{"version":1,"sha256Hash":"9c7cc66367037fda3007b7f592201c2610edb2c9a9292975cd131a37bbe61930"}}}' \
  --compressed|jq --arg server "$server" '.data.Realms | .[] | select (.slug == $server) | .name,.online' | tr '[a-z]' '[A-Z]' )"
while [[ $offset > 0 ]]
do let offset--
   echo
done
output="$(echo "$output"|sed -e 's/FALSE/OFFLINE/'|sed -e 's/TRUE/ONLINE/')"
if grep -q "OFFLINE" <<< "$output"
then echo -en "\e[0;31m"
else echo -en "\e[0;32m"
fi
figlet -c -t "$output"
figlet -c -t "$(date +%T)"
