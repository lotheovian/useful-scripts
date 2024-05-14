#!/bin/bash

# This script is setup with the following assumptions...
# You use 1Password for your vpn credentials and OTP generator in a vault called private with a entry named VPN
# You are using macos for osascript notifications

# Must define op_password and ovpn_conf_file
source .vpn.conf
function authenticate_op () {
   eval $(echo "${op_password}" | op signin)
   [ -z "${username}" ] && username="$(op read "op://Private/VPN/username")"
   [ -z "${password}" ] && password="$(op read "op://Private/VPN/password")"
   otp="$(op read "op://Private/VPN/one-time password?attribute=otp")"
}

while true
do authenticate_op
   osascript -e "display notification \"CONNECTING VPN @ $(date)\" with title \"CONNECTING VPN\""
   sleep 1
   echo "$username" > auth.txt
   echo "${password}${otp}" >> auth.txt
   sudo openvpn --config ${ovpn_conf_file} --auth-user-pass auth.txt
   osascript -e "display notification \"VPN DROPPED @ $(date)\" with title \"VPN DROPPED\""
done
