#!/bin/bash
# must provide one config file as an argument
config_file="$1"
shift
source ${config_file}

function authenticate_op () {
   eval $(echo "${op_password}" | op signin)
   [ -z "${username}" ] && username="$(op read "op://${op_entry_id}/username")"
   [ -z "${static_pass}" ] && static_pass="$(op read "op://${op_entry_id}/password")"
   if [ -z "${username}" ] || [ -z "${static_pass}" ]
   then echo "failed to authenticate with onepassword"
        exit 1
   fi
   if [ "$twofactor" == "true" ]
   then otp="$(op read "op://${op_entry_id}/one-time password?attribute=otp")"
        password="${static_pass}${otp}"
   else password="${static_pass}"
   fi
}

function authenticate_cli () { 
   username="$1"
   password="$2"
   if [ "$twofactor" == "true" ]
   then password+="$3"
   fi
}

function authenticate() {
   if [ "$auth_method" == "op" ]
   then authenticate_op
   elif [ "$auth_method" == "cli" ]
   then authenticate_cli $@
   elif [ "$auth_method" == "static" ]
   then if [[ -z "$username" || -z "$password" ]]
        then echo "Error must provide credentials when choosing static auth"
             exit 1
        fi
        if [ "$twofactor" == "true" ]
        then echo "Invalid setup, 2fa not available for static credentials"
             exit 1
        fi
   else echo "Unknown auth method: $auth_method for file ${config_file}"
        exit 1
   fi

}

while true
do authenticate $@
   osascript -e "display notification \"CONNECTING VPN ${config_file} @ $(date)\" with title \"CONNECTING VPN\""
   sleep 1
   > auth.txt
   chmod 600 auth.txt
   echo "$username" >> auth.txt
   echo "${password}" >> auth.txt
   sudo openvpn --config ${ovpn_conf_file} --auth-user-pass auth.txt
   osascript -e "display notification \"VPN DROPPED @ $(date)\" with title \"VPN DROPPED\""

   if [ "$auth_method" == "cli" ] && [ "$twofactor" == "true" ]
   then echo "VPN in manual mode, cant reconnect"
        exit 1
   fi

done
