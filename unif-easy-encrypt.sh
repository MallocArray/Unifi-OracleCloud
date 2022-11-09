#!/bin/bash

# UniFi Easy Encrypt script.
# Version  | 2.1.4
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header() {
  clear
  clear
  echo -e "${GREEN}#########################################################################${RESET}\\n"
}

header_red() {
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

if ! grep -iq "udm" /usr/lib/version &> /dev/null; then
  if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8"; then
    header
    echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
    echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script..."
    export LC_ALL=C &> /dev/null
    set_lc_all=true
    sleep 3
  fi
fi

abort() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!\\n"
  echo -e "${WHITE_R}#${RESET} Creating support file..."
  mkdir -p "/tmp/EUS/support" &> /dev/null
  if dpkg -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; fi
  df -h &> "/tmp/EUS/support/df"
  free -hm &> "/tmp/EUS/support/memory"
  uname -a &> "/tmp/EUS/support/uname"
  dpkg -l | grep "mongo\\|oracle\\|openjdk\\|unifi" &> "/tmp/EUS/support/unifi-packages"
  dpkg -l &> "/tmp/EUS/support/dpkg-list"
  dpkg --print-architecture &> "/tmp/EUS/support/architecture"
  # shellcheck disable=SC2129
  sed -n '3p' "${script_location}" &>> "/tmp/EUS/support/script"
  grep "# Version" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  echo "${server_fqdn}" &>> "/tmp/EUS/support/fqdn"
  echo "${server_ip}" &>> "/tmp/EUS/support/ip"
  if dpkg -l tar 2> /dev/null | grep -iq "^ii\\|^hi"; then
    tar -cvf /tmp/eus_support.tar.gz "/tmp/EUS" "${eus_dir}" &> /dev/null && support_file="/tmp/eus_support.tar.gz"
  elif dpkg -l zip 2> /dev/null | grep -iq "^ii\\|^hi"; then
    zip -r /tmp/eus_support.zip "/tmp/EUS/*" "${eus_dir}/*" &> /dev/null && support_file="/tmp/eus_support.zip"
  fi
  if [[ -n "${support_file}" ]]; then echo -e "${WHITE_R}#${RESET} Support file has been created here: ${support_file} \\n"; fi
  if [[ -f "/root/EUS/eus-le-retry.sh" ]]; then
    number_of_aborts=$(head -n1 "${eus_dir}/retries_aborts")
    echo "$((number_of_aborts+1))" &> "${eus_dir}/retries_aborts"
  fi
  if [[ "${script_option_retry}" == 'true' && "${script_option_fqdn}" == 'true' ]]; then
    echo -e "${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Scheduling retry scripts!\\n"
    mkdir -p /root/EUS
    cp "${0}" /root/EUS/unifi-easy-encrypt.sh
    echo "0" &> "${eus_dir}/retries_aborts"
  # shellcheck disable=SC1117
    tee /root/EUS/eus-le-retry.sh &>/dev/null << SCRIPT
#/bin/bash
# Script created by EUS.
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
number_of_retries=\$(head -n1 "${eus_dir}/retries")
echo "\$((number_of_retries-1))" &> "${eus_dir}/retries"
number_of_aborts=\$(head -n1 "${eus_dir}/retries_aborts")
sed -i '/--retry/d' /tmp/EUS/script_options &> /dev/null
if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "\$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi
# shellcheck disable=SC2068
$(command -v bash) /root/EUS/unifi-easy-encrypt.sh \${script_options[@]}
number_of_aborts_2=\$(head -n1 "${eus_dir}/retries_aborts")
if [[ "\${number_of_aborts}" == "\${number_of_aborts_2}" ]]; then echo "# Script is no longer aborting! \\n# Removing the scripts..." &>> "${eus_dir}/logs/unattended.log"; abort_message="true"; number_of_retries='0'; fi
if [[ "\${number_of_retries}" == '0' ]]; then if [[ "\${abort_message}" != 'true' ]]; then echo "# Number of retries hit 0" &>> "${eus_dir}/logs/unattended.log"; fi; rm --force /root/EUS/eus-le-retry.sh &> /dev/null; rm --force /etc/cron.d/eus_lets_encrypt_retry &> /dev/null; rm --force "${eus_dir}/retries*" &> /dev/null; fi
SCRIPT
    tee /etc/cron.d/eus_lets_encrypt_retry &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/15 * * * * root $(command -v bash) /root/EUS/eus-le-retry.sh
EOF
  fi
  exit 1
}

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${script_option_skip}" == 'true' ]]; then
    echo -e "\\n${WHITE_R}#########################################################################${RESET}\\n"
  else
    header
  fi
  echo -e "${WHITE_R}#${RESET} Cancelling the script!\\n\\n"
  exit 0
}

if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
  eus_dir='/srv/EUS'
  is_cloudkey=true
  if grep -iq "UCKP" /usr/lib/version; then is_cloudkey_gen2_plus=true; fi
elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
  eus_dir='/srv/EUS'
  is_cloudkey=true
  if grep -iq "UCKP" /usr/lib/version; then is_cloudkey_gen2_plus=true; fi
else
  eus_dir='/usr/lib/EUS'
  is_cloudkey=false
  is_cloudkey_gen2_plus=false
fi

check_dig_curl() {
  if [[ "${run_ipv6}" == 'true' ]]; then
    dig_option='AAAA'
    curl_option='-6'
  else
    dig_option='A'
    curl_option='-4'
  fi
}

create_remove_files() {
  script_location="${BASH_SOURCE[0]}"
  script_name=$(basename "${BASH_SOURCE[0]}")
  rm --force "${eus_dir}/other_domain_records" &> /dev/null
  rm --force "${eus_dir}/le_domain_list" &> /dev/null
  rm --force "${eus_dir}/fqdn_option_domains" &> /dev/null
  mkdir -p "${eus_dir}/logs" &> /dev/null
  mkdir -p "${eus_dir}/checksum" &> /dev/null
  mkdir -p /tmp/EUS/keys &> /dev/null
}
create_remove_files

script_logo() {
  cat << "EOF"

  _______________ ___ _________   _____________________
  \_   _____|    |   /   _____/   \_   _____\_   _____/
   |    __)_|    |   \_____  \     |    __)_ |    __)_ 
   |        |    |  //        \    |        \|        \
  /_______  |______//_______  /   /_______  /_______  /
          \/                \/            \/        \/ 

EOF
}

start_script() {
  header
  script_logo
  echo -e "    UniFi Easy Encrypt Script!"
  echo -e "\\n${WHITE_R}#${RESET} Starting the UniFi Easy Encrypt Script..."
  echo -e "${WHITE_R}#${RESET} Thank you for using my UniFi Easy Encrypt Script :-)\\n\\n"
  sleep 4
}
start_script

help_script() {
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${WHITE_R}----${RESET}\\n"; fi
  echo -e "    UniFi Easy Encrypt script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_name} [options]
  
  Script options:
    --skip                                  Skip any kind of manual input.
    --skip-network-application              Skip importing certificates into the Network application
                                            on a UniFi OS Console.
    --v6                                    Run the script in IPv6 mode instead of IPv4.
    --email [argument]                      Specify what email address you want to use
                                            for renewal notifications.
                                            example:
                                            --email glenn@glennr.nl
    --fqdn [argument]                       Specify what domain name ( FQDN ) you want to use, you
                                            can specify multiple domain names with : as seperator, see
                                            the example below:
                                            --fqdn glennr.nl:www.glennr.nl
    --server-ip [argument]                  Specify the server IP address manually.
                                            example:
                                            --server-ip 1.1.1.1
    --retry [argument]                      Retry the unattended script if it aborts for X times.
                                            example:
                                            --retry 5
    --external-dns [argument]               Use external DNS server to resolve the FQDN.
                                            example:
                                            --external-dns 1.1.1.1
    --force-renew                           Force renew the certificates.
    --dns-challenge                         Run the script in DNS mode instead of HTTP.
    --private-key [argument]                Specify path to your private key (paid certificate)
                                            example:
                                            --private-key /tmp/PRIVATE.key
	--signed-certificate [argument]         Specify path to your signed certificate (paid certificate)
                                            example:
                                            --signed-certificate /tmp/SSL_CERTIFICATE.cer
    --chain-certificate [argument]          Specify path to your chain certificate (paid certificate)
                                            example:
                                            --chain-certificate /tmp/CHAIN.cer
    --intermediate-certificate [argument]   Specify path to your intermediate certificate (paid certificate)
                                            example:
                                            --intermediate-certificate /tmp/INTERMEDIATE.cer
    --own-certificate                       Requirement if you want to import your own paid certificates
                                            with the use of --skip.
    --restore                               Restore previous certificate/config files.
    --help                                  Shows this information :) \\n\\n"
  exit 0
}

rm --force /tmp/EUS/le_script_options &> /dev/null
rm --force /tmp/EUS/script_options &> /dev/null
script_option_list=(-skip --skip --skip-network-application --install-script --v6 --ipv6 --email --mail --fqdn --domain-name --server-ip --server-address --retry --external-dns --force-renew --renew --dns --dns-challenge --priv-key --private-key --signed-crt --signed-certificate --chain-crt --chain-certificate --intermediate-crt --intermediate-certificate --own-certificate --restore --help)

while [ -n "$1" ]; do
  case "$1" in
  -skip | --skip)
       old_certificates=all
       script_option_skip=true
       echo "--skip" &>> /tmp/EUS/script_options;;
  --skip-network-application)
       if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
         script_option_skip_network_application=true
         echo "--skip-network-application" &>> /tmp/EUS/script_options
       fi;;
  --install-script)
       install_script=true
       echo "--install-script" &>> /tmp/EUS/script_options;;
  --v6 | --ipv6)
       run_ipv6=true
       echo "--v6" &>> /tmp/EUS/script_options;;
  --email | --mail)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       le_user_mail="$2"
       email_reg='^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$'
       if ! [[ "${le_user_mail}" =~ ${email_reg} ]]; then email="--register-unsafely-without-email"; else email="--email ${le_user_mail}"; fi
       script_option_email=true
       echo "--email ${2}" &>> /tmp/EUS/script_options
       shift;;
  --fqdn | --domain-name)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "$2" &> "${eus_dir}/fqdn_option_le.tmp"
       sed $'s/:/\\\n/g' < "${eus_dir}/fqdn_option_le.tmp" &> "${eus_dir}/fqdn_option_le"
       rm --force "${eus_dir}/fqdn_option_le.tmp"
       awk '!a[$0]++' "${eus_dir}/fqdn_option_le" >> "${eus_dir}/fqdn_option_domains" && rm --force "${eus_dir}/fqdn_option_le"
       script_option_fqdn=true
       echo "--fqdn ${2}" &>> /tmp/EUS/script_options
       shift;;
  --server-ip | --server-address)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       server_ip="$2"
       echo "${server_ip}" &> "${eus_dir}/server_ip"
       manual_server_ip="true"
       echo "--server-ip ${2}" &>> /tmp/EUS/script_options
       shift;;
  --retry)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ "${2}" =~ ^[0-9]+$ ]]; then header_red; echo -e "${WHITE_R}#${RESET} '${2}' is not a valid command argument for ${1}... \\n\\n"; help_script; fi
       retries="$2"
       echo "${retries}" &> "${eus_dir}/retries"
       script_option_retry="true"
       echo "--retry ${2}" &>> /tmp/EUS/script_options
       shift;;
  --external-dns)
       if [[ -n "${2}" ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; echo -ne "\\r${WHITE_R}#${RESET} Checking if '${2}' is a valid DNS server..."; if [[ "${2}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then if [[ "$(echo "${2}" | cut -d'.' -f1)" -le '255' && "$(echo "${2}" | cut -d'.' -f2)" -le '255' && "$(echo "${2}" | cut -d'.' -f3)" -le '255' && "$(echo "${2}" | cut -d'.' -f4)" -le '255' ]]; then ip_valid=true; elif [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi; fi
       if [[ "${ip_valid}" == 'true' ]]; then if ping -c 1 "${2}" > /dev/null; then ping_ok=true; external_dns_server="@${2}"; elif [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi
       if [[ "${ping_ok}" == 'true' ]]; then check_dig_curl; if dig +short "${dig_option}" google.com "${external_dns_server}" &> /dev/null; then custom_external_dns_server_provided=true; elif [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi
       if [[ "${custom_external_dns_server_provided}" == 'true' ]]; then echo "--external-dns ${2}" &>> /tmp/EUS/script_options; echo -ne "\\r${GREEN}#${RESET} '${2}' is a valid DNS server! The script will use '${2}' for DNS! \\n\\n${WHITE_R}----${RESET}\\n"; sleep 2; else echo "--external-dns" &>> /tmp/EUS/script_options; if [[ -n "${2}" ]]; then echo -ne "\\r${RED}#${RESET} '${2}' is not a valid DNS server, the script will use '1.1.1.1'... \\n\\n${WHITE_R}----${RESET}\\n"; sleep 2; fi; if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111'; else external_dns_server='@1.1.1.1'; fi; fi;;
  --force-renew | --renew)
       script_option_renew=true
       run_force_renew=true
       echo "--force-renew" &>> /tmp/EUS/script_options;;
  --dns | --dns-challenge)
       script_option_skip=false
       unset old_certificates
       prefer_dns_challenge=true
       echo "--dns" &>> /tmp/EUS/script_options;;
  --priv-key | --private-key)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       priv_key="$2"
       echo "--private-key ${2}" &>> /tmp/EUS/script_options
       shift;;
  --signed-crt | --signed-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       signed_crt="$2"
       echo "--signed-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --chain-crt | --chain-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       chain_crt="$2"
       echo "--chain-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --intermediate-crt | --intermediate-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       intermediate_crt="$2"
       echo "--intermediate-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --own-certificate)
       own_certificate=true
       echo "--own-certificate" &>> /tmp/EUS/script_options;;
  --restore)
       script_option_skip=false
       echo "--restore" &>> /tmp/EUS/script_options;;
  --help)
       script_option_help=true
       help_script;;
  esac
  shift
done

get_script_options() {
  if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi
}
get_script_options

# Cleanup EUS logs
find "${eus_dir}/logs/" -printf "%f\\n" | grep '.*.log' | awk '!a[$0]++' &> /tmp/EUS/log_files
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/${log_file}" ]]; then
    log_file_size=$(stat -c%s "${eus_dir}/logs/${log_file}")
    if [[ "${log_file_size}" -gt "10485760" ]]; then
      tail -n1000 "${eus_dir}/logs/${log_file}" &> "${log_file}.tmp"
      mv "${eus_dir}/logs/${log_file}.tmp" "${eus_dir}/logs/${log_file}"
    fi
  fi
done < /tmp/EUS/log_files
rm --force /tmp/EUS/log_files

# Cleanup lets encrypt challenge logs ( keep last 5 )
# shellcheck disable=SC2010
ls -t "${eus_dir}/logs/" | grep -i "lets_encrypt_[0-9].*.log" | tail -n+6 &>> /tmp/EUS/challenge_log_cleanup
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/${log_file}" ]]; then
    rm --force "${eus_dir}/logs/${log_file}" &> /dev/null
  fi
done < /tmp/EUS/challenge_log_cleanup
rm --force /tmp/EUS/challenge_log_cleanup &> /dev/null

# Remove obsolete log files
# shellcheck disable=SC2010
if ls "${eus_dir}/logs/" | grep -qi "lets_encrypt_import_[0-9].*.log"; then
  # shellcheck disable=SC2010
  ls -t "${eus_dir}/logs/" | grep -i "lets_encrypt_import_[0-9].*.log" &> /tmp/EUS/obsolete_logs
  while read -r log_file; do
    rm --force "${eus_dir}/logs/${log_file}" &> /dev/null
  done < /tmp/EUS/obsolete_logs
  rm --force /tmp/EUS/obsolete_logs &> /dev/null
fi

christmass_new_year() {
  date_d=$(date '+%d' | sed "s/^0*//g; s/\.0*/./g")
  date_m=$(date '+%m' | sed "s/^0*//g; s/\.0*/./g")
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} GlennR wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message=true
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message=true
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message=true
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message=true
  fi
}

run_apt_get_update() {
  if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi
  if ! [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    if [[ "${hide_apt_update}" == 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} Running apt-get update..."
      if apt-get update &> /tmp/EUS/keys/apt_update; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during running apt-get update! \\n"; fi
      unset hide_apt_update
    else
      apt-get update 2>&1 | tee /tmp/EUS/keys/apt_update
    fi
    grep -o 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/keys/missing_keys
  fi
  if [[ -f /tmp/EUS/keys/missing_keys && -s /tmp/EUS/keys/missing_keys ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Some keys are missing.. The script will try to add the missing keys."
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    while read -r key; do
      echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
      http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
      if [[ -n "$http_proxy" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
      elif [[ -f /etc/apt/apt.conf ]]; then
        apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
        if [[ -n "${apt_http_proxy}" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
        fi
      else
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key=true
      fi
      if [[ "${fail_key}" == 'true' ]]; then
        echo -e "${RED}#${RESET} Failed to add key ${key}!"
        echo -e "${WHITE_R}#${RESET} Trying different method to get key: ${key}"
        gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/keys/failed_key
        debug_key=$(grep "KS_GET" /tmp/EUS/keys/failed_key | grep -io "0x.*")
        wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" -O- | gpg --dearmor > "/tmp/EUS/keys/EUS-${key}.gpg"
        mv "/tmp/EUS/keys/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/ && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n"
      fi
      sleep 1
    done < /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/missing_keys
    rm --force /tmp/EUS/keys/apt_update
    header
    echo -e "${WHITE_R}#${RESET} Running apt-get update again.\\n\\n"
    sleep 2
    apt-get update &> /tmp/EUS/keys/apt_update
    if grep -qo 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update; then
      run_apt_get_update
    fi
  fi
}

author() {
  header
  echo -e "${WHITE_R}#${RESET} The script successfully ended, enjoy your secure setup!\\n"
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; else echo -e "\\n"; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}"
  echo -e "\\n\\n"
}

# Get distro.
get_distro() {
  if [[ -z "$(command -v lsb_release)" ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        if [[ -z "${os_codename}" ]]; then
          os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        fi
      fi
    fi
  else
    os_codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
    if [[ "${os_codename}" == 'n/a' ]]; then
      os_codename=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    fi
  fi
  if [[ "${os_codename}" =~ (precise|maya|luna) ]]; then repo_codename=precise; os_codename=precise
  elif [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa|freya) ]]; then repo_codename=trusty; os_codename=trusty
  elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then repo_codename=xenial; os_codename=xenial
  elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then repo_codename=bionic; os_codename=bionic
  elif [[ "${os_codename}" =~ (focal|ulyana|ulyssa|uma|una) ]]; then repo_codename=focal; os_codename=focal
  elif [[ "${os_codename}" =~ (jammy|vanessa) ]]; then repo_codename=jammy; os_codename=jammy
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then repo_codename=stretch; os_codename=stretch
  elif [[ "${os_codename}" =~ (buster|debbie|parrot|engywuck-backports|engywuck|deepin) ]]; then repo_codename=buster; os_codename=buster
  elif [[ "${os_codename}" =~ (bullseye|kali-rolling|elsie) ]]; then repo_codename=bullseye; os_codename=bullseye
  else
    repo_codename="${os_codename}"
    os_codename="${os_codename}"
  fi
}
get_distro

if [[ $(echo "${PATH}" | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  #PATH=$PATH:/usr/sbin
  PATH=$PATH:/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
fi

if ! [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|jessie|stretch|continuum|buster|bullseye|bookworm) ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} This script is not made for your OS..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums if you believe this is an error."
  echo -e "\\nOS_CODENAME = ${os_codename}\\n\\n"
  exit 1
fi

dpkg_locked_message() {
  header_red
  echo -e "${WHITE_R}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE_R}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!\\n\\n"
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  header
  echo -e "${WHITE_R}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE_R}#${RESET} Would you like to force remove the lock?\\n\\n"
}

# Check if dpkg is locked
if dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            killall apt apt-get 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
  done;
else
  dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  while [[ "${dpkg_locked}" == 'true'  ]]; do
    unset dpkg_locked
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            pgrep "apt" >> /tmp/EUS/apt
            while read -r glennr_apt; do
              kill -9 "$glennr_apt" 2> /dev/null
            done < /tmp/EUS/apt
            rm --force /tmp/EUS/apt 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null;;
          [Nn]*) dpkg_wait=true;;
      esac
    fi
    dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  done;
  rm --force /tmp/glennr_dpkg_lock 2> /dev/null
fi

script_online_version_dots=$(curl https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh -s | grep "# Version" | head -n 1 | awk '{print $4}')
script_local_version_dots=$(grep "# Version" "${script_location}" | head -n 1 | awk '{print $4}')
script_online_version="${script_online_version_dots//./}"
script_local_version="${script_local_version_dots//./}"

# Script version check.
if [[ "${script_online_version::3}" -gt "${script_local_version::3}" ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
  echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Let's Encrypt Script..\\n\\n"
  sleep 3
  rm --force "${script_location}" 2> /dev/null
  rm --force unifi-easy-encrypt.sh 2> /dev/null
  # shellcheck disable=SC2068
  wget https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh && bash unifi-easy-encrypt.sh ${script_options[@]}; exit 0
fi

required_service=no
if [[ "${is_cloudkey}" == 'true' ]]; then required_service=yes; fi
if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then required_service=yes; fi
if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then required_service=yes; fi
if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then if docker ps -a | grep -iq 'ubnt/eot'; then required_service=yes; fi; fi
if [[ "${required_service}" == 'no' ]]; then
  echo -e "${RED}#${RESET} Please install one of the following controllers/applications first, then retry this script again!"
  echo -e "${RED}-${RESET} UniFi Network Application"
  echo -e "${RED}-${RESET} UniFi Video NVR"
  echo -e "${RED}-${RESET} UniFi LED Controller\\n\\n"
  exit 1
fi

# Check if UniFi is already installed.
unifi_status=$(systemctl status unifi | grep -i 'Active:' | awk '{print $2}')
if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${unifi_status}" == 'inactive' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} UniFi is not active ( running ), starting the application now."
    systemctl start unifi
    unifi_status=$(systemctl status unifi | grep -i 'Active:' | awk '{print $2}')
    if [[ "${unifi_status}" == 'active' ]]; then
      echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application!"
      sleep 2
    else
      echo -e "${RED}#${RESET} Failed to start the UniFi Network Application!"
      echo -e "${RED}#${RESET} Please check the logs in '/usr/lib/unifi/logs/'"
      sleep 2
    fi
  fi
fi

check_dig_curl

certbot_auto_permission_check() {
  if [[ -f "${eus_dir}/certbot-auto" || -s "${eus_dir}/certbot-auto" ]]; then
    if [[ $(stat -c "%a" "${eus_dir}/certbot-auto") != "755" ]]; then
      chmod 0755 "${eus_dir}/certbot-auto"
    fi
    if [[ $(stat -c "%U" "${eus_dir}/certbot-auto") != "root" ]] ; then
      chown root "${eus_dir}/certbot-auto"
    fi
  fi
}

download_certbot_auto() {
  if [[ "${use_older_certbot_auto_script}" == 'true' ]]; then
    curl -s https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto -o "${eus_dir}/certbot-auto"
  else
    curl -s https://raw.githubusercontent.com/certbot/certbot/v1.17.0/certbot-auto -o "${eus_dir}/certbot-auto"
    #curl -s https://dl.eff.org/certbot-auto -o "${eus_dir}/certbot-auto"
  fi
  chown root "${eus_dir}/certbot-auto"
  chmod 0755 "${eus_dir}/certbot-auto"
  downloaded_certbot=true
  certbot_auto_permission_check
  if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then abort; fi
}

remove_certbot() {
  if dpkg -l certbot 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    apt-get remove certbot -y
    apt-get autoremove -y
    apt-get autoclean -y
  fi
}

if [[ "${os_codename}" == "jessie" ]]; then
  if dpkg -l | grep ^"ii" | awk '{print $2}' | grep -q "^certbot\\b"; then
    header_red
    echo -e "${RED}#${RESET} Your certbot version is to old, we will switch to certbot-auto..\\n\\n"
    remove_certbot
  fi
fi

# Check openSSL version, if version 3.x.x, use -legacy for pkcs12
openssl_version=$(openssl version | awk '{print $2}' | sed -e 's/[a-zA-Z]//g')
first_digit_openssl=$(echo "${openssl_version}" | cut -d'.' -f1)
#second_digit_openssl=$(echo "${openssl_version}" | cut -d'.' -f2)
#third_digit_openssl=$(echo "${openssl_version}" | cut -d'.' -f3)
if [[ "${first_digit_openssl}" -ge "3" ]]; then
  openssl_legacy_flag="-legacy"
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

apt_get_install_package() {
  hide_apt_update=true
  run_apt_get_update
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/required.log"
  echo -e "${WHITE_R}#${RESET} Trying to install ${required_package}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/required.log"; then echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to install ${required_package}... \\n"; abort; fi
  unset required_package
}

certbot_repositories() {
  if [[ "${repo_codename}" =~ (xenial|bionic|cosmic) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ppa.launchpad.net/certbot/certbot/ubuntu ${repo_codename} main") -eq 0 ]]; then
      echo -e "deb http://ppa.launchpad.net/certbot/certbot/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http://ppa.launchpad.net/certbot/certbot/ubuntu disco main") -eq 0 ]]; then
      echo deb http://ppa.launchpad.net/certbot/certbot/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm) ]]; then
    if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
      echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  fi
  if [[ "${certbot_repository_add_key}" == 'true' ]]; then
    echo "8C47BE8E75BCA694" &>> /tmp/EUS/keys/missing_keys
  fi
  hide_apt_update=true
  run_apt_get_update
  echo -e "${WHITE_R}#${RESET} Trying to install certbot..."
  echo -e "\\n------- certbot installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/required.log"
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install certbot &>> "${eus_dir}/logs/required.log"; then echo -e "${GREEN}#${RESET} Successfully installed certbot! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to install certbot... \\n"; abort; fi
}

check_certbot_version() {
  certbot_version_1=$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f1)
  certbot_version_2=$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f2)
  if [[ -n "${certbot_version_2}" ]] && [[ "${certbot_version_1}" -le '0' ]] && [[ "${certbot_version_2}" -lt '27' ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Making sure your certbot version is on the latest release.\\n\\n"
    certbot_repositories
    certbot_version_1=$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f1)
    certbot_version_2=$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\\b" | awk '{print $2}' | cut -d'.' -f2)
    if [[ -n "${certbot_version_2}" ]] && [[ "${certbot_version_1}" -le '0' ]] && [[ "${certbot_version_2}" -lt '27' ]]; then
      header_red
      echo -e "${RED}#${RESET} Your certbot version is to old, we will switch to certbot-auto..\\n\\n"
      remove_certbot
      download_certbot_auto
    fi
  fi
}

install_required_packages() {
  installing_required_package=yes
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages..\\n"
  hide_apt_update=true
  run_apt_get_update
  sleep 2
}
if ! dpkg -l dnsutils 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing dnsutils..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dnsutils &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install dnsutils in the first run...\\n"
    if [[ "${repo_codename}" == "xenial" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="dnsutils"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed dnsutils! \\n" && sleep 2
  fi
fi
if ! dpkg -l net-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing net-tools..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install net-tools &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install net-tools in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="net-tools"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed net-tools! \\n" && sleep 2
  fi
fi
if ! dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing curl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu ${repo_codename}-security main") -eq 0 ]]; then
        echo -e "deb http://security.ubuntu.com/ubuntu ${repo_codename}-security main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://nl.archive.ubuntu.com/ubuntu ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://security.debian.org/debian-security ${repo_codename}/updates main") -eq 0 ]]; then
        echo -e "deb http://security.debian.org/debian-security ${repo_codename}/updates main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm) ]]; then
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian ${repo_codename} main") -eq 0 ]]; then
        echo -e "deb http://ftp.nl.debian.org/debian ${repo_codename} main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    required_package="curl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed curl! \\n" && sleep 2
  fi
fi
certbot_install_function() {
  if [[ "${own_certificate}" != "true" ]]; then
    if [[ "${os_codename}" == "jessie" ]]; then
      if [[ "${os_codename}" == "jessie" ]]; then
        if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then download_certbot_auto; fi
        if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then abort; fi
      fi
    else
      if ! dpkg -l certbot 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        if dpkg -l | awk '{print$2}' | grep -iq "^snapd$" && [[ "${try_snapd}" != 'false' ]]; then
          if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
          echo -e "\\n------- update ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/snapd.log"
          echo -e "${WHITE_R}#${RESET} Updating snapd..."
          if snap install core &>> "${eus_dir}/logs/snapd.log"; snap refresh core &>> "${eus_dir}/logs/snapd.log"; then
            echo -e "${GREEN}#${RESET} Successfully updated snapd! \\n" && sleep 2
            echo -e "\\n------- certbot installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/snapd.log"
            echo -e "${WHITE_R}#${RESET} Installing certbot via snapd..."
            if snap install --classic certbot &>> "${eus_dir}/logs/snapd.log"; then
              echo -e "${GREEN}#${RESET} Successfully installed certbot via snapd! \\n" && sleep 2
              if ! [[ -L "/usr/bin/certbot" ]]; then
                echo -e "${WHITE_R}#${RESET} Creating symlink for certbot..."
                if ln -s /snap/bin/certbot /usr/bin/certbot; then echo -e "${GREEN}#${RESET} Successfully created symlink for certbot! \\n"; else echo -e "${RED}#${RESET} Failed to create symlink for certbot... \\n"; abort; fi
              fi
	        else
              echo -e "${RED}#${RESET} Failed to install certbot via snapd... \\n"
              echo -e "${WHITE_R}#${RESET} Trying to remove cerbot snapd..."
              echo -e "\\n------- certbot removal ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/snapd.log"
              if snap remove certbot &>> "${eus_dir}/logs/snapd.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed certbot! \\n"
                echo -e "${WHITE_R}#${RESET} Trying the classic way of using certbot..."
                try_snapd=false
                certbot_install_function
              fi
            fi
	      else
            echo -e "${RED}#${RESET} Failed to update snapd... \\n"
            abort
          fi
        else
          if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
          echo -e "\\n------- certbot installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/required.log"
          echo -e "${WHITE_R}#${RESET} Installing certbot..."
          if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install certbot &>> "${eus_dir}/logs/required.log"; then
            echo -e "${GREEN}#${RESET} Successfully installed certbot! \\n" && sleep 2
	      else
            echo -e "${RED}#${RESET} Failed to install certbot in the first run... \\n"
            certbot_repositories
          fi
          check_certbot_version
        fi
      else
        check_certbot_version
      fi
    fi
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

certbot_auto_install_run() {
  header
  echo -e "${WHITE_R}#${RESET} Running script in certbot-auto mode, installing more required packages..."
  echo -e "${WHITE_R}#${RESET} This may take a while, depending on the device."
  echo -e "${WHITE_R}#${RESET} certbot-auto verbose log is saved here: ${eus_dir}/logs/certbot_auto_install.log\\n\\n${WHITE_R}----${RESET}\\n"
  sleep 2
  if [[ "${os_codename}" =~ (jessie) ]]; then
    if ! dpkg -l | awk '{print$2}' | grep -iq "libssl-dev"; then
      echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list
      echo -e "${WHITE_R}#${RESET} Running apt-get update..."
      if apt-get update -o Acquire::Check-Valid-Until=false &>> "${eus_dir}/logs/required.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during apt-get update...\\n"; fi
      echo -e "${WHITE_R}#${RESET} Installing a required package..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports libssl-dev -y &>> "${eus_dir}/logs/required.log"; then echo -e "${GREEN}#${RESET} Successfully installed the required package! \\n"; else echo -e "${RED}#${RESET} Failed to install required package...\\n"; abort; fi
      sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
    fi
  fi
  certbot_auto_permission_check
  if ${eus_dir}/certbot-auto --non-interactive --install-only --verbose "${certbot_auto_flags}" 2>&1 | tee "${eus_dir}/logs/certbot_auto_install.log"; then
    if grep -ioq "Your system is not supported by certbot-auto anymore" "${eus_dir}/logs/certbot_auto_install.log"; then
      header_red
      echo -e "${YELLOW}#${RESET} certbot-auto no longer supports your system..."
      echo -e "${YELLOW}#${RESET} We will try an older version of the certbot-auto script..."
      sleep 5
      use_older_certbot_auto_script=true
      download_certbot_auto
      certbot_auto_flags="--no-self-upgrade"
      certbot_auto_install_run
      return
    elif grep -ioq "Certbot is installed" "${eus_dir}/logs/certbot_auto_install.log"; then
      return
    else
      abort
    fi
  else
    abort
  fi
  if [[ -f "${eus_dir}/logs/certbot_auto_install.log" ]]; then
    certbot_auto_install_log_size=$(du -sc "${eus_dir}/logs/certbot_auto_install.log" | grep total$ | awk '{print $1}')
    if [[ "${certbot_auto_install_log_size}" -gt '50' ]]; then
      tail -n100 "${eus_dir}/logs/certbot_auto_install.log" &> "${eus_dir}/logs/certbot_auto_install_tmp.log"
      cp "${eus_dir}/logs/certbot_auto_install_tmp.log" "${eus_dir}/logs/certbot_auto_install.log" && rm --force "${eus_dir}/logs/certbot_auto_install_tmp.log"
    fi
  fi
}

if [[ "${os_codename}" =~ (jessie) || "${downloaded_certbot}" == 'true' ]]; then
  certbot="${eus_dir}/certbot-auto"
  certbot_auto=true
else
  certbot="certbot"
fi

manual_fqdn='no'
run_uck_scripts='no'
if [[ "${run_force_renew}" == 'true' ]]; then
  renewal_option="--force-renewal"
else
  renewal_option="--keep-until-expiring"
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Unattended                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

fqdn_option() {
  header
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/unattended.log"
  server_fqdn=$(head -n1 "${eus_dir}/fqdn_option_domains" | tr '[:upper:]' '[:lower:]')
  if [[ "${server_ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    if ! [[ "$(echo "${server_ip}" | cut -d'.' -f1)" -le '255' && "$(echo "${server_ip}" | cut -d'.' -f2)" -le '255' && "$(echo "${server_ip}" | cut -d'.' -f3)" -le '255' && "$(echo "${server_ip}" | cut -d'.' -f4)" -le '255' ]]; then
      manual_server_ip="false"
    fi
  fi
  while read -r line; do
    if [[ "${manual_server_ip}" == 'true' ]]; then server_ip=$(head -n1 "${eus_dir}/server_ip"); else server_ip=$(curl -s "${curl_option}" https://ip.glennr.nl/); fi
    echo -e "${WHITE_R}#${RESET} Checking if '${line}' resolves to '${server_ip}'" | tee -a "${eus_dir}/logs/unattended.log"
    domain_record=$(dig +short "${dig_option}" "${line}" "${external_dns_server}" &>> "${eus_dir}/domain_records")
    if grep -xq "${server_ip}" "${eus_dir}/domain_records"; then domain_record="${server_ip}"; fi
    if grep -xq "connection timed out" "${eus_dir}/domain_records"; then echo -e "${RED}#${RESET} Timed out when reaching DNS server... \\n${RED}#${RESET} Please confirm that the system can reach the specified DNS server. \\n" | tee -a "${eus_dir}/logs/unattended.log"; abort; fi
    if [[ -f "${eus_dir}/domain_records" ]]; then resolved_ip=$(grep "..*\\..*\\..*\\..*" "${eus_dir}/domain_records"); fi
    rm --force "${eus_dir}/domain_records" &> /dev/null
    if [[ "${server_ip}" != "${domain_record}" ]]; then echo -e "${RED}#${RESET} '${line}' does not resolve to '${server_ip}', it resolves to '${resolved_ip}' instead... \\n" | tee -a "${eus_dir}/logs/unattended.log"; if [[ "${server_fqdn}" == "${line}" ]]; then abort; fi; else echo -e "${GREEN}#${RESET} Successfully resolved '${line}' ( '${server_ip}' ) \\n" | tee -a "${eus_dir}/logs/unattended.log"; if [[ "${server_fqdn}" != "${domain_record}" ]]; then echo "${line}" &>> "${eus_dir}/other_domain_records"; fi; fi
    sleep 2
  done < "${eus_dir}/fqdn_option_domains"
  rm --force "${eus_dir}/fqdn_option_domains" &> /dev/null
  if [[ $(grep -c "" "${eus_dir}/other_domain_records" 2> /dev/null) -eq "0" ]]; then echo -e "${RED}#${RESET} None of the FQDN's resolved correctly... \\n" | tee -a "${eus_dir}/logs/unattended.log"; abort; fi
  if [[ $(grep -c "" "${eus_dir}/other_domain_records" 2> /dev/null) -ge "1" ]]; then multiple_fqdn_resolved="true"; fi
  if [[ "${install_script}" == 'true' ]]; then echo "${server_fqdn}" &> "${eus_dir}/server_fqdn_install"; fi
  sleep 2
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Script                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

delete_certs_question() {
  header
  echo -e "${WHITE_R}#${RESET} What would you like to do with the old certificates?\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Keep all certificates. ( default )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Keep last 3 certificates."
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel script."
  echo -e "\\n"
  read -rp $'Your choice | \033[39m' choice
  case "$choice" in
     1|"") old_certificates=all;;
     2) old_certificates=last_three;;
     3) cancel_script;;
	 *) 
        header_red
        echo -e "${WHITE_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        delete_certs_question;;
  esac
}

time_date=$(date +%Y%m%d_%H%M)

timezone() {
  if ! [[ -f "${eus_dir}/timezone_correct" ]]; then
    if [[ -f /etc/timezone && -s /etc/timezone ]]; then
      time_zone=$(awk '{print $1}' /etc/timezone)
    else
      time_zone=$(timedatectl | grep -i "time zone" | awk '{print $3}')
    fi
    header
    echo -e "${WHITE_R}#${RESET} Your timezone is set to ${time_zone}."
    read -rp $'\033[39m#\033[0m Is your timezone correct? (Y/n) ' yes_no
    case "${yes_no}" in
       [Yy]*|"") touch "${eus_dir}/timezone_correct";;
       [Nn]*|*)
          header
          echo -e "${WHITE_R}#${RESET} Let's change your timezone!" && sleep 3; mkdir -p /tmp/EUS/
          dpkg-reconfigure tzdata && clear
          if [[ -f /etc/timezone && -s /etc/timezone ]]; then
            time_zone=$(awk '{print $1}' /etc/timezone)
          else
            time_zone=$(timedatectl | grep -i "time zone" | awk '{print $3}')
          fi
          rm --force /tmp/EUS/timezone 2> /dev/null
          header
          # shellcheck disable=SC2086
          read -rp $'\033[39m#\033[0m Your timezone is now set to "'${time_zone}'", is that correct? (Y/n) ' yes_no
          case "${yes_no}" in
             [Yy]*|"") touch "${eus_dir}/timezone_correct";;
             [Nn]*|*) timezone;;
          esac;;
    esac
  fi
}

domain_name() {
  if [[ "${manual_fqdn}" == 'no' ]]; then
    if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      server_fqdn=$(mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" | grep '"hostname"' | awk '{print $3}' | sed 's/[",]//g')
    else
      if [[ -f "${eus_dir}/server_fqdn" ]]; then
        server_fqdn=$(head -n1 ${eus_dir}/server_fqdn)
      else
        server_fqdn='unifi.yourdomain.com'
      fi
      no_unifi=yes
    fi
    current_server_fqdn="$server_fqdn"
  fi
  header
  echo -e "${WHITE_R}#${RESET} Your FQDN is set to '${server_fqdn}'"
  read -rp $'\033[39m#\033[0m Is the domain name/FQDN above correct? (Y/n) ' yes_no
  case "${yes_no}" in
     [Yy]*|"") le_resolve;;
     [Nn]*|*) le_manual_fqdn;;
  esac
}

multiple_fqdn_resolve() {
  header
  other_fqdn=$(echo "${other_fqdn}" | tr '[:upper:]' '[:lower:]')
  echo -e "${WHITE_R}#${RESET} Trying to resolve '${other_fqdn}'"
  other_domain_records=$(dig +short "${dig_option}" "${other_fqdn}" "${external_dns_server}" &>> "${eus_dir}/other_domain_records_tmp")
  if grep -xq "${server_ip}" "${eus_dir}/other_domain_records_tmp"; then other_domain_records="${server_ip}"; fi
  if grep -xq "connection timed out" "${eus_dir}/other_domain_records_tmp"; then echo -e "${RED}#${RESET} Timed out when reaching DNS server... \\n${RED}#${RESET} Please confirm that the system can reach the specified DNS server. \\n"; abort; fi
  resolved_ip=$(grep "..*\\..*\\..*\\..*" "${eus_dir}/other_domain_records_tmp")
  rm --force "${eus_dir}/other_domain_records_tmp" &> /dev/null
  sleep 3
  if [[ "${server_ip}" != "${other_domain_records}" ]]; then
    header
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' does not resolve to '${server_ip}', it resolves to '${resolved_ip}' instead... \\n"
    echo -e "${WHITE_R}#${RESET} Please make an A record pointing to your server's ip."
    echo -e "${WHITE_R}#${RESET} If you are using Cloudflare, please disable the orange cloud.\\n"
    echo -e "${GREEN}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Please take an option below.\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Skip and continue script. ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Try a different FQDN."
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel Script."
    echo -e "\\n\\n"
    read -rp $'Your choice | \033[39m' le_resolve_question
    case "${le_resolve_question}" in
       1*|"") ;;
       2*) multiple_fqdn;;
       3*) cancel_script;;
       *) unknown_option;;
    esac
  elif [[ "${server_fqdn}" == "${other_fqdn}" ]]; then
    header
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' is the same as '${server_fqdn}' and already entered..."
    read -rp $'\033[39m#\033[0m Do you want to add another FQDN? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  elif grep -ixq "${other_fqdn}" "${eus_dir}/other_domain_records" &> /dev/null; then
    header
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' was already entered..."
    read -rp $'\033[39m#\033[0m Do you want to add another FQDN? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  else
    multiple_fqdn_resolved=true
    echo "${other_fqdn}" | tr '[:upper:]' '[:lower:]' &>> "${eus_dir}/other_domain_records"
    echo -e "${WHITE_R}#${RESET} '${other_fqdn}' resolved correctly!"
    echo -e "\\n${GREEN}---${RESET}\\n"
    read -rp $'\033[39m#\033[0m Do you want to add more FQDNs? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  fi
}

multiple_fqdn() {
  header
  echo -e "${WHITE_R}#${RESET} Please enter the other FQDN of your setup below."
  read -rp $'\033[39m#\033[0m ' other_fqdn
  multiple_fqdn_resolve
}

le_resolve() {
  header
  server_fqdn=$(echo "${server_fqdn}" | tr '[:upper:]' '[:lower:]')
  echo -e "${WHITE_R}#${RESET} Trying to resolve '${server_fqdn}'"
  if [[ "${manual_server_ip}" == 'true' ]]; then
    server_ip=$(head -n1 "${eus_dir}/server_ip")
  else
    server_ip=$(curl -s "${curl_option}" https://ip.glennr.nl/)
  fi
  domain_record=$(dig +short "${dig_option}" "${server_fqdn}" "${external_dns_server}" &>> "${eus_dir}/domain_records")
  if grep -xq "${server_ip}" "${eus_dir}/domain_records"; then
    domain_record="${server_ip}"
  fi
  rm --force "${eus_dir}/domain_records" 2> /dev/null
  sleep 3
  if [[ "${server_ip}" != "${domain_record}" ]]; then
    header
    echo -e "${WHITE_R}#${RESET} '${server_fqdn}' does not resolve to '${server_ip}'"
    echo -e "${WHITE_R}#${RESET} Please make an A record pointing to your server's ip."
    echo -e "${WHITE_R}#${RESET} If you are using Cloudflare, please disable the orange cloud."
    echo -e "\\n${GREEN}---${RESET}\\n\\n${WHITE_R}#${RESET} Please take an option below.\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Try to resolve your FQDN again. ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Resolve with a external DNS server."
    if [[ "${manual_server_ip}" == 'true' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Manually set the server IP. ( for users with multiple IP addresses )"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Automatically get server IP."
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel Script."
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Manually set the server IP. ( for users with multiple IP addresses )"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel Script."
    fi
    echo ""
    echo ""
    echo ""
    read -rp $'Your choice | \033[39m' le_resolve_question
    case "${le_resolve_question}" in
       1*|"") le_manual_fqdn;;
       2*) 
          header
          echo -e "${WHITE_R}#${RESET} What external DNS server would you like to use?"
          echo ""
          if [[ "${run_ipv6}" == 'true' ]]; then
            echo -e " [   ${WHITE_R}1${RESET}   ]  |  Google          ( 2001:4860:4860::8888 )"
            echo -e " [   ${WHITE_R}2${RESET}   ]  |  Google          ( 2001:4860:4860::8844 )"
            echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cloudflare      ( 2606:4700:4700::1111 )"
            echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cloudflare      ( 2606:4700:4700::1001 )"
            echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cisco Umbrella  ( 2620:119:35::35 )"
            echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cisco Umbrella  ( 2620:119:53::53 )"
          else
            echo -e " [   ${WHITE_R}1${RESET}   ]  |  Google          ( 8.8.8.8 )"
            echo -e " [   ${WHITE_R}2${RESET}   ]  |  Google          ( 8.8.4.4 )"
            echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cloudflare      ( 1.1.1.1 )"
            echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cloudflare      ( 1.0.0.1 )"
            echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cisco Umbrella  ( 208.67.222.222 )"
            echo -e " [   ${WHITE_R}6${RESET}   ]  |  Cisco Umbrella  ( 208.67.220.220 )"
          fi
          echo -e " [   ${WHITE_R}7${RESET}   ]  |  Don't use external DNS servers."
          echo -e " [   ${WHITE_R}8${RESET}   ]  |  Cancel script"
          echo ""
          echo ""
          echo ""
          read -rp $'Your choice | \033[39m' le_resolve_question
          case "${le_resolve_question}" in
             1*|"") if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2001:4860:4860::8888' && le_resolve; else external_dns_server='@8.8.8.8' && le_resolve; fi;;
             2*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2001:4860:4860::8844' && le_resolve; else external_dns_server='@8.8.4.4' && le_resolve; fi;;
             3*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1111' && le_resolve; else external_dns_server='@1.1.1.1' && le_resolve; fi;;
             4*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2606:4700:4700::1001' && le_resolve; else external_dns_server='@1.0.0.1' && le_resolve; fi;;
             5*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2620:119:35::35' && le_resolve; else external_dns_server='@208.67.222.222' && le_resolve; fi;;
             6*) if [[ "${run_ipv6}" == 'true' ]]; then external_dns_server='@2620:119:53::53' && le_resolve; else external_dns_server='@208.67.220.220' && le_resolve; fi;;
             7*) le_resolve;;
             8*) cancel_script;;
             *) unknown_option;;
          esac;;
       3*) le_manual_server_ip;;
       4*) if [[ "${manual_server_ip}" == 'true' ]]; then rm --force "${eus_dir}/server_fqdn" &> /dev/null; manual_server_ip=false; le_resolve; else cancel_script; fi;;
       5*) if [[ "${manual_server_ip}" == 'true' ]]; then cancel_script; else unknown_option; fi;;
       *) unknown_option;;
    esac
  else
    echo -e "${WHITE_R}#${RESET} '${server_fqdn}' resolved correctly!"
    if [[ "${install_script}" == 'true' ]]; then echo "${server_fqdn}" &> "${eus_dir}/server_fqdn_install"; fi
    echo -e "\\n${GREEN}---${RESET}\\n"
    read -rp $'\033[39m#\033[0m Do you want to add more FQDNs? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") multiple_fqdn;;
       [Nn]*) ;;
    esac
  fi
}

change_application_hostname() {
  if [[ "${manual_fqdn}" == 'true' && "${run_ipv6}" != 'true' ]] && dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    header
    echo -e "${WHITE_R}#${RESET} Your current UniFi Network Application FQDN is set to '${current_server_fqdn}' in the settings..."
    echo -e "${WHITE_R}#${RESET} Would you like to change it to '${server_fqdn}'?"
    echo ""
    echo ""
    read -rp $'\033[39m#\033[0m Would you like to apply the change? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"")
          if ! mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" | grep -iq "override_inform_host.* true"; then
	        # shellcheck disable=SC2016,SC2086
            if mongo --quiet --port 27117 ace --eval 'db.setting.update({"hostname":"'${current_server_fqdn}'"}, {$set: {"hostname":"'${server_fqdn}'"}})' | grep -iq '"nModified".*:.*1'; then
              header
              echo -e "${GREEN}#${RESET} Successfully changed the UniFi Network Application Hostname to '${server_fqdn}'"
              sleep 2
            fi
          fi;;
       [Nn]*) ;;
    esac
  fi
}

unknown_option() {
  header_red
  echo -e "${WHITE_R}#${RESET} '${le_resolve_question}' is not a valid option..." && sleep 2
  le_resolve
}

le_manual_server_ip() {
  manual_server_ip=true
  header
  echo -e "${WHITE_R}#${RESET} Please enter your Server/WAN IP below."
  read -rp $'\033[39m#\033[0m ' server_ip
  if [[ -f "${eus_dir}/server_ip" ]]; then rm --force "${eus_dir}/server_ip" &> /dev/null; fi
  echo "$server_ip" >> "${eus_dir}/server_ip"
  le_resolve
}

le_manual_fqdn() {
  manual_fqdn=true
  header
  echo -e "${WHITE_R}#${RESET} Please enter the FQDN of your setup below."
  read -rp $'\033[39m#\033[0m ' server_fqdn
  if [[ "${no_unifi}" == 'yes' ]]; then
    if [[ -f "${eus_dir}/server_fqdn" ]]; then rm --force "${eus_dir}/server_fqdn" &> /dev/null; fi
    echo "$server_fqdn" >> "${eus_dir}/server_fqdn"
  fi
  le_resolve
}

le_email() {
  email_reg='^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$'
  header
  if [[ "${skip_email_question}" != 'yes' ]]; then
    read -rp $'\033[39m#\033[0m Do you want to setup a email address for renewal notifications? (Y/n) ' yes_no
  fi
  case "$yes_no" in
     [Yy]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Please enter the email address below."
        read -rp $'\033[39m#\033[0m ' le_user_mail
        if ! [[ "${le_user_mail}" =~ ${email_reg} ]]; then
          header_red
          echo -e "${RED}#${RESET} ${le_user_mail} is an invalid email address..."
          read -rp $'\033[39m#\033[0m Do you want to try another email address? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"")
                skip_email_question=yes
                le_email
                return;;
             [Nn]*|*)
                email="--register-unsafely-without-email";;
          esac
        else
          email="--email ${le_user_mail}"
        fi;;
     [Nn]*|*)
        email="--register-unsafely-without-email";;
  esac
}

le_pre_hook() {
  if ! [[ -d /etc/letsencrypt/renewal-hooks/pre/ ]]; then
    mkdir -p /etc/letsencrypt/renewal-hooks/pre/
  fi
  # shellcheck disable=SC1117
  tee "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" &>/dev/null <<EOF
#!/bin/bash
rm --force "${eus_dir}/le_http_service" 2> /dev/null
if [[ -d "${eus_dir}/logs" ]]; then mkdir -p "${eus_dir}/logs"; fi
if [[ -d "${eus_dir}/checksum" ]]; then mkdir -p "${eus_dir}/checksum"; fi
if [[ \${log_date} != 'true' ]]; then
  echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/http_service.log"
  log_date=true
fi
netstat -tulpn | grep ":80 " | awk '{print \$7}' | sed 's/[0-9]*\///' | sed 's/://' &>> "${eus_dir}/le_http_service_temp"
awk '!a[\$0]++' "${eus_dir}/le_http_service_temp" >> "${eus_dir}/le_http_service" && rm --force "${eus_dir}/le_http_service_temp"
while read -r service; do
  echo " '\${service}' is running on port 80." &>> "${eus_dir}/logs/http_service.log"
  if systemctl stop "\${service}" 2> /dev/null; then 
    echo " Successfully stopped '\${service}'." &>> "${eus_dir}/logs/http_service.log"
    echo "systemctl:\${service}" &>> "${eus_dir}/le_stopped_http_service"
  else
    echo " Failed to stop '\${service}'." &>> "${eus_dir}/logs/http_service.log"
    if dpkg -l | awk '{print \$2}' | grep -iq "^docker.io\\|^docker-ce"; then
      docker_http=\$(docker ps --filter publish=80 --quiet)
      if [[ -n "\${docker_http}" ]]; then
        if docker stop "\${docker_http}" &> /dev/null; then
          echo " Successfully stopped docker container '\${docker_http}'." &>> "${eus_dir}/logs/http_service.log"
          echo "docker:\${docker_http}" &>> "${eus_dir}/le_stopped_http_service"
        else
          echo " Failed to stop docker container '\${docker_http}'." &>> "${eus_dir}/logs/http_service.log"
        fi
      fi
    fi
    if command -v snap &> /dev/null; then
      pid_http_service=\$(netstat -tulpn | grep ":80 " | awk '{print \$7}' | sed 's/\/.*//g')
        if [[ -n "\${pid_http_service}" ]]; then
        pid_http_service_2=\$(ls -l "/proc/\${pid_http_service}/exe" | grep -io "snap.*/" | cut -d'/' -f1-2)
        if echo \${pid_http_service_2} | grep -iq 'snap'; then
          snap_detail=\$(echo \${pid_http_service_2} | cut -d'/' -f2)
          if snap stop \${snap_detail}; then
            echo " Successfully stopped snap '\${snap_detail}'." &>> "${eus_dir}/logs/http_service.log"
            echo "snap\${snap_detail}" &>> "${eus_dir}/le_stopped_http_service"
          else
            echo " Failed to stop snap '\${snap_detail}'." &>> "${eus_dir}/logs/http_service.log"
          fi
        fi
      fi
    fi
  fi
done < "${eus_dir}/le_http_service"
if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then
  echo " 'uas' is running on port 80." &>> "${eus_dir}/logs/http_service.log"
  if systemctl stop uas; then echo " Successfully stopped 'uas'." &>> "${eus_dir}/logs/http_service.log"; else echo " Failed to stop 'uas'." &>> "${eus_dir}/logs/http_service.log"; fi
  echo "systemctl:uas" &>> "${eus_dir}/le_stopped_http_service"
fi
if dpkg -l | grep -iq unifi-core; then
  echo " 'unifi-core' is running." &>> "${eus_dir}/logs/http_service.log"
  if systemctl stop unifi-core; then echo " Successfully stopped 'unifi-core'." &>> "${eus_dir}/logs/http_service.log"; else echo " Failed to stop 'unifi-core'." &>> "${eus_dir}/logs/http_service.log"; fi
  echo "systemctl:unifi-core" &>> "${eus_dir}/le_stopped_http_service"
fi
rm --force "${eus_dir}/le_http_service" 2> /dev/null
if dpkg -l ufw 2> /dev/null | grep -q "^ii\\|^hi"; then
  if ufw status verbose | awk '/^Status:/{print \$2}' | grep -xq "active"; then
    if ! ufw status verbose | grep "^80\\b\\|^80/tcp\\b" | grep -iq "ALLOW IN"; then
      ufw allow 80 &> /dev/null && echo -e " Port 80 is now set to 'ALLOW IN'." &>> "${eus_dir}/logs/http_service.log"
      touch "${eus_dir}/ufw_add_http"
    fi
  fi
fi
EOF
  chmod +x "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh"
}

le_post_hook() {
  if ! [[ -d /etc/letsencrypt/renewal-hooks/post/ ]]; then
    mkdir -p /etc/letsencrypt/renewal-hooks/post/
  fi
  # shellcheck disable=SC1117
  tee "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" &>/dev/null <<EOF
#!/bin/bash
old_certificates="${old_certificates}"
skip_network_application="${script_option_skip_network_application}"
if [[ -f "${eus_dir}/le_stopped_http_service" && -s "${eus_dir}/le_stopped_http_service" ]]; then
  mv "${eus_dir}/le_stopped_http_service" "${eus_dir}/le_stopped_http_service_temp"
  awk '!a[\$0]++' "${eus_dir}/le_stopped_http_service_temp" >> "${eus_dir}/le_stopped_http_service" && rm --force "${eus_dir}/le_stopped_http_service_temp"
  while read -r line; do
    command=\$(echo "\${line}" | cut -d':' -f1)
    id=\$(echo "\${line}" | cut -d':' -f2)
    if "\${command}" start "\${id}" 2> /dev/null; then
      echo " Successfully started \${command} '\${id}'." &>> "${eus_dir}/logs/http_service.log"
      systemctl_status=\$(\${command} status "\${id}" | grep -i 'Active:' | awk '{print \$2}')
      if [[ "\${systemctl_status}" == 'inactive' ]]; then
        echo " '\${id}' is still inactive, attempting to stop/start again." &>> "${eus_dir}/logs/http_service.log"
        if ! "\${command}" stop "\${id}" 2> /dev/null; then
          echo " Failed to stop \${command} '\${id}' (second attempt)." &>> "${eus_dir}/logs/http_service.log"
        fi
        sleep 3
        if "\${command}" start "\${id}" 2> /dev/null; then
          echo " Successfully started \${command} '\${id}' (second attempt)." &>> "${eus_dir}/logs/http_service.log"
        else
          echo " Failed to start \${command} '\${id}' (second attempt)." &>> "${eus_dir}/logs/http_service.log"
        fi
      fi
    else
      echo " Failed to start \${command} '\${id}'." &>> "${eus_dir}/logs/http_service.log"
    fi
  done < "${eus_dir}/le_stopped_http_service"
  rm --force "${eus_dir}/le_stopped_http_service" 2> /dev/null
fi
if [[ -f "${eus_dir}/ufw_add_http" ]]; then
  ufw delete allow 80 &> /dev/null
  rm --force "${eus_dir}/ufw_add_http" 2> /dev/null
fi
# shellcheck disable=SC2034
server_fqdn="${server_fqdn}"
if ls "${eus_dir}/logs/lets_encrypt_[0-9]*.log" &>/dev/null && [[ -d "/etc/letsencrypt/live/${server_fqdn}" ]]; then
  # shellcheck disable=SC2012,SC2010
  last_le_log=\$(ls "${eus_dir}/logs/lets_encrypt_[0-9]*.log" | tail -n1)
  le_var_log=\$(grep -i "/etc/letsencrypt/live/${server_fqdn}" "\${last_le_log}" | awk '{print \$1}' | head -n1 | sed 's/\/etc\/letsencrypt\/live\///g' | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
  # shellcheck disable=SC2012,SC2010
  le_var_dir=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g")
  if [[ "\${le_var_log}" != "\${le_var_dir}" ]]; then
    le_var="\${le_var_dir}"
  else
    le_var="\${le_var_log}"
  fi
else
  # shellcheck disable=SC2012,SC2010
  if [[ -d /etc/letsencrypt/live/ ]]; then le_var=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g"); fi
fi
if ! [[ -f "${eus_dir}/checksum/fullchain.sha256sum" && -s "${eus_dir}/checksum/fullchain.sha256sum" && -f "${eus_dir}/checksum/fullchain.md5sum" && -s "${eus_dir}/checksum/fullchain.md5sum" ]]; then
  touch "${eus_dir}/temp_file"
  sha256sum "${eus_dir}/temp_file" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.sha256sum"
  md5sum "${eus_dir}/temp_file" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.md5sum"
  rm --force "${eus_dir}/temp_file"
fi
if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" && -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
  current_sha256sum=\$(sha256sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" | awk '{print \$1}')
  current_md5sum=\$(md5sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" 2> /dev/null | awk '{print \$1}')
  if [[ "\${current_sha256sum}" != "\$(cat "${eus_dir}/checksum/fullchain.sha256sum")" && "\${current_md5sum}" != "\$(cat "${eus_dir}/checksum/fullchain.md5sum")" ]]; then
    echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    sha256sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.sha256sum" && echo "Successfully updated sha256sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    md5sum "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" 2> /dev/null | awk '{print \$1}' &> "${eus_dir}/checksum/fullchain.md5sum" && echo "Successfully updated md5sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    if dpkg -l unifi-core 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
      if grep -ioq "udm" /usr/lib/version; then udm_device=true; fi
      if dpkg -l uid-agent 2> /dev/null | grep -iq "^ii\\|^hi"; then uid_agent=\$(curl -s http://localhost:11081/api/controllers | jq '.[] | select(.name == "uid-agent").isConfigured'); fi
      # shellcheck disable=SC2012
      if [[ ! -d /data/eus_certificates/ ]]; then mkdir -p /data/eus_certificates/; fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" /data/eus_certificates/unifi-os.crt
      fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /data/eus_certificates/unifi-os.key
      fi
      if [[ ! -f /data/unifi-core/config.yaml ]]; then
        tee /data/unifi-core/config.yaml &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
      else
        if ! [[ -d "${eus_dir}/unifi-os/config_backups" ]]; then mkdir -p "${eus_dir}/unifi-os/config_backups"; fi
        cp /data/unifi-core/config.yaml "${eus_dir}/unifi-os/config_backups/config.yaml_\$(date +%Y%m%d_%H%M)"
        if ! grep -iq "ssl:" /data/unifi-core/config.yaml; then
          tee -a /data/unifi-core/config.yaml &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
        else
          unifi_os_crt_file=\$(grep -i "crt:" /data/unifi-core/config.yaml | awk '{print\$2}' | sed "s/'//g")
          unifi_os_key_file=\$(grep -i "key:" /data/unifi-core/config.yaml | awk '{print\$2}' | sed "s/'//g")
          sed -i "s#\${unifi_os_crt_file}#/data/eus_certificates/unifi-os.crt#g" /data/unifi-core/config.yaml
          sed -i "s#\${unifi_os_key_file}#/data/eus_certificates/unifi-os.key#g" /data/unifi-core/config.yaml
        fi
      fi
      systemctl restart unifi-core
      time_date=\$(date +%Y%m%d_%H%M)
      if [[ "\${udm_device}" == 'true' && "\${uid_agent}" != 'true' ]]; then
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "ls -la /mnt/data/udapi-config/raddb/certs/" | grep -iq "server.pem\\|server-key.pem" && [[ -f "${eus_dir}/radius/true" ]]; then
          if ! [[ -d "/data/eus_certificates/raddb" ]]; then mkdir -p /data/eus_certificates/raddb &> /dev/null; fi
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server.pem /data/eus_certificates/raddb/original_server_\${time_date}.pem" &>> "${eus_dir}/logs/radius.log"
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server-key.pem /data/eus_certificates/raddb/original_server-key_\${time_date}.pem" &>> "${eus_dir}/logs/radius.log"
          if [[ -f "/data/eus_certificates/unifi-os.crt" ]]; then
            raddb_cert_file="/data/eus_certificates/unifi-os.crt"
          else
            cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /data/eus_certificates/raddb-server.pem
            raddb_cert_file="/data/eus_certificates/raddb-server.pem"
          fi
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp \${raddb_cert_file} /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/radius.log"
          if [[ -f "/data/eus_certificates/unifi-os.key" ]]; then
            raddb_key_file="/data/eus_certificates/unifi-os.key"
          else
            cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /data/eus_certificates/raddb-server-key.pem
            raddb_key_file="/data/eus_certificates/raddb-server-key.pem"
          fi
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp \${raddb_key_file} /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/radius.log"
          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/radius.log"
        fi
      fi
    fi
    if dpkg -l unifi 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi" && [[ "\${skip_network_application}" != 'true' ]]; then
      # shellcheck disable=SC2012
      if [[ "\${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/network/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      mkdir -p "${eus_dir}/network/keystore_backups" && cp /usr/lib/unifi/data/keystore "${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)"
      # shellcheck disable=SC2129
      openssl pkcs12 -export -inkey "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" -out "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/lets_encrypt_import.log"
      keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/lets_encrypt_import.log"
      keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/lets_encrypt_import.log"
      chown -R unifi:unifi /usr/lib/unifi/data/keystore &> /dev/null
      systemctl restart unifi
    fi
    if [[ -f "${eus_dir}/cloudkey/cloudkey_management_ui" ]]; then
      mkdir -p "${eus_dir}/cloudkey/certs_backups"
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cp /etc/ssl/private/cloudkey.crt "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)"
      cp /etc/ssl/private/cloudkey.key "${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)"
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /etc/ssl/private/cloudkey.key
      fi
      systemctl restart nginx
      if dpkg -l unifi-protect 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
        unifi_protect_status=\$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print \$2}')
        if [[ \${unifi_protect_status} == 'active' ]]; then
          systemctl restart unifi-protect
        fi
      fi
    fi
    if [[ -f "${eus_dir}/cloudkey/cloudkey_unifi_led" ]]; then
      systemctl restart unifi-led
    fi
    if [[ -f "${eus_dir}/cloudkey/cloudkey_unifi_talk" ]]; then
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/talk/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      mkdir -p "${eus_dir}/talk/certs_backups" && cp /usr/share/unifi-talk/app/certs/server.pem "${eus_dir}/talk/certs_backups/server.pem_\$(date +%Y%m%d_%H%M)"
      cat "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" > /usr/share/unifi-talk/app/certs/server.pem
      systemctl restart unifi-talk
    fi
    if [[ -f "${eus_dir}/cloudkey/uas_management_ui" ]]; then
      mkdir -p "${eus_dir}/uas/certs_backups/"
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cp /etc/uas/uas.crt "${eus_dir}/uas/certs_backups/uas.crt_\$(date +%Y%m%d_%H%M)"
      cp /etc/uas/uas.key "${eus_dir}/uas/certs_backups/uas.key_\$(date +%Y%m%d_%H%M)"
      systemctl stop uas
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" /etc/uas/uas.crt
      fi
      if [[ -f "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" ]]; then
        cp "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" /etc/uas/uas.key
      fi
      systemctl start uas
    fi
    if [[ -f "${eus_dir}/eot/uas_unifi_led" ]]; then
      mkdir -p "${eus_dir}/eot/certs_backups"
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/eot/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cat "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" > "${eus_dir}/eot/eot_docker_container.pem"
      eot_container=\$(docker ps -a | grep -i 'ubnt/eot' | awk '{print \$1}')
      eot_container_name="ueot"
      if [[ -n "\${eot_container}" ]]; then
        docker cp "\${eot_container}:/app/certs/server.pem" "${eus_dir}/eot/certs_backups/server.pem_\$(date +%Y%m%d_%H%M)"
        docker cp "${eus_dir}/eot/eot_docker_container.pem" "\${eot_container}:/app/certs/server.pem"
        docker restart \${eot_container_name}
      fi
    fi
    if [[ -f "${eus_dir}/video/unifi_video" ]]; then
      mkdir -p /usr/lib/unifi-video/data/certificates
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      # shellcheck disable=SC2012
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/ufv-truststore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      openssl pkcs8 -topk8 -nocrypt -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem" -outform DER -out /usr/lib/unifi-video/data/certificates/ufv-server.key.der
      openssl x509 -outform der -in "/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem" -out /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
      chown -R unifi-video:unifi-video /usr/lib/unifi-video/data/certificates
      systemctl stop unifi-video
      mkdir -p "${eus_dir}/video/keystore_backups"
      mv /usr/lib/unifi-video/data/keystore "${eus_dir}/video/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)"
      mv /usr/lib/unifi-video/data/ufv-truststore "${eus_dir}/video/keystore_backups/ufv-truststore_\$(date +%Y%m%d_%H%M)"
      if ! grep -iq "^ufv.custom.certs.enable=true" /usr/lib/unifi-video/data/system.properties; then
        echo "ufv.custom.certs.enable=true" &>> /usr/lib/unifi-video/data/system.properties
      fi
      systemctl start unifi-video
    fi
  else
    echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/lets_encrypt_import.log"
    echo -e "Checksums are the same.. certificate didn't renew." &>> "${eus_dir}/logs/lets_encrypt_import.log"
    if grep -A40 -i "\$(date '+%d %b %Y %H')" /var/log/letsencrypt/letsencrypt.log | grep -A6 '"error":' | grep -io "detail.*" | grep -iq "firewall"; then
      echo -e "Certificates didn't renew due to a firewall issue ( likely )..." &>> "${eus_dir}/logs/lets_encrypt_import.log"
    fi
  fi
fi
if ! [[ -d "/tmp/EUS" ]]; then mkdir -p /tmp/EUS; fi
ls -t "${eus_dir}/logs/" | grep -i "lets_encrypt_[0-9].*.log" | tail -n+6 &>> /tmp/EUS/challenge_log_cleanup
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/\${log_file}" ]]; then
    rm --force "${eus_dir}/logs/\${log_file}" &> /dev/null
  fi
done < /tmp/EUS/challenge_log_cleanup
rm --force /tmp/EUS/challenge_log_cleanup &> /dev/null
EOF
  chmod +x "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh"
}

le_import_failed() {
  if [[ "${prefer_dns_challenge}" == 'true' ]]; then header_red; fi
  echo -e "${RED}#${RESET} Failed to imported SSL certificate for '${server_fqdn}'"
  echo -e "${RED}#${RESET} Cleaning up files and restarting the application service(s)...\\n"
  echo -e "${RED}#${RESET} Feel free to reach out to GlennR ( AmazedMender16 ) on the Ubiquiti Community Forums"
  echo -e "${RED}#${RESET} Log file is saved here: ${eus_dir}/logs/lets_encrypt_${time_date}.log"
  if [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]]; then
    if grep -iq 'timeout during connect' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      script_timeout_http=true
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Timed out..."
      echo -e "${RED}#${RESET} Your Firewall or ISP does not allow port 80, please verify that your Firewall/Port Fordwarding settings are correct.\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'timeout after connect' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      script_timeout_http=true
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Timed out... Your server may be slow or overloaded"
      echo -e "${RED}#${RESET} Please try to run the script again and make sure there is no firewall blocking port 80.\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'No TXT record found' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} No TXT records found for \"_acme-challenge.${server_fqdn}\"\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'too many certificates already issued for exact set of domains' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} There were too many certificates issued for ${server_fqdn}\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'live directory exists' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} A live directory exists for ${server_fqdn}\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Problem binding to port 80' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo -e "\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Script failed to stop the service running on port 80, please manually stop it and run the script again!\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Incorrect TXT record' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo ""
      echo -e "${RED}---${RESET}\\n\\n${RED}#${RESET} The TXT record you created was incorrect..\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Account creation on ACMEv1 is disabled' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      echo ""
      echo -e "${RED}---${RESET}\\n\\n${RED}#${RESET} Account creation on ACMEv1 is disabled..\\n\\n${RED}---${RESET}"
    fi
    if grep -iq 'Invalid response from' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
      header_red
      echo -e "${RED}#${RESET} Invalid response from \"http://${server_fqdn}/.well-known/acme-challenge/xxxxxxxxxxxxxxxxxxx\"..."
      echo -e "${RED}#${RESET} Please make sure that your domain name was entered correctrly and that the DNS A/AAAA record(s) for that domain contain(s) the right IP address..."
      abort
    fi
    if [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'Keystore was tampered with, or password was incorrect' "${eus_dir}/logs/lets_encrypt_import.log"; then
      echo ""
      echo -e "${RED}#${RESET} Please clear your browser cache if you're seeing connection errors.\\n\\n${RED}---${RESET}\\n\\n${RED}#${RESET} Keystore was tampered with, or password was incorrect\\n\\n${RED}---${RESET}"
      if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        rm --force /usr/lib/unifi/data/keystore 2> /dev/null && systemctl restart unifi
      fi
    fi
  fi
  rm --force "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" &> /dev/null
  rm --force "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" &> /dev/null
  run_uck_scripts=no
  exit 1
}

cloudkey_management_ui() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/cloudkey/certs_backups" && touch "${eus_dir}/cloudkey/cloudkey_management_ui"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the Cloudkey User Interface..."
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/cloudkey/certs_backups/cloudkey.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cp /etc/ssl/private/cloudkey.crt "${eus_dir}/cloudkey/certs_backups/cloudkey.crt_$(date +%Y%m%d_%H%M)"
  cp /etc/ssl/private/cloudkey.key "${eus_dir}/cloudkey/certs_backups/cloudkey.key_$(date +%Y%m%d_%H%M)"
  if [[ "${paid_cert}" == "true" ]]; then
    if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
      cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /etc/ssl/private/cloudkey.crt
    fi
    if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
      cp "${eus_dir}/paid-certificates/eus_key_file.key" /etc/ssl/private/cloudkey.key
    fi
  else
    if [[ -f "${fullchain_pem}.pem" ]]; then
      cp "${fullchain_pem}.pem" /etc/ssl/private/cloudkey.crt
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /etc/ssl/private/cloudkey.crt
    fi
    if [[ -f "${priv_key_pem}.pem" ]]; then
      cp "${priv_key_pem}.pem" /etc/ssl/private/cloudkey.key
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /etc/ssl/private/cloudkey.key
    fi
  fi
  if systemctl restart nginx; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the Cloudkey User Interface!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into the Cloudkey User Interface... \\n"; sleep 2; fi
  if dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    unifi_protect_status=$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print $2}')
    if [[ "${unifi_protect_status}" == 'active' ]]; then
      echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Protect..."
      if systemctl restart unifi-protect; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Protect!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-Protect... \\n"; sleep 2; fi
    fi
  fi
}

cloudkey_unifi_led() {
  mkdir -p "${eus_dir}/cloudkey/" && touch "${eus_dir}/cloudkey/cloudkey_unifi_led"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED..."
  if systemctl restart unifi-led; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-LED... \\n"; sleep 2; fi
}

cloudkey_unifi_talk() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/cloudkey/" && touch "${eus_dir}/cloudkey/cloudkey_unifi_talk"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Talk..."
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/talk/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mkdir -p "${eus_dir}/talk/certs_backups" && cp /usr/share/unifi-talk/app/certs/server.pem "${eus_dir}/talk/certs_backups/server.pem_$(date +%Y%m%d_%H%M)"
  if [[ "${paid_cert}" == "true" ]]; then
    cp "${eus_dir}/paid-certificates/eus_certificates_file.pem" /usr/share/unifi-talk/app/certs/server.pem
  else
    cat "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" > /usr/share/unifi-talk/app/certs/server.pem
  fi
  if systemctl restart unifi-talk; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Talk!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-Talk... \\n"; sleep 2; fi
}

unifi_core() {
  # shellcheck disable=SC2012
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the ${unifi_core_device} running UniFi OS..."
  if [[ ! -d /data/eus_certificates/ ]]; then mkdir -p /data/eus_certificates/; fi
  if [[ "${paid_cert}" == "true" ]]; then
    if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
      cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /data/eus_certificates/unifi-os.crt
    fi
    if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
      cp "${eus_dir}/paid-certificates/eus_key_file.key" /data/eus_certificates/unifi-os.key
    fi
  else
    if [[ -f "${fullchain_pem}.pem" ]]; then
      cp "${fullchain_pem}.pem" /data/eus_certificates/unifi-os.crt
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /data/eus_certificates/unifi-os.crt
    fi
    if [[ -f "${priv_key_pem}.pem" ]]; then
      cp "${priv_key_pem}.pem" /data/eus_certificates/unifi-os.key
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /data/eus_certificates/unifi-os.key
    fi
  fi
  if [[ ! -f /data/unifi-core/config.yaml ]]; then
    tee /data/unifi-core/config.yaml &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
  else
    if ! [[ -d "${eus_dir}/unifi-os/config_backups" ]]; then mkdir -p "${eus_dir}/unifi-os/config_backups"; fi
    cp /data/unifi-core/config.yaml "${eus_dir}/unifi-os/config_backups/config.yaml_$(date +%Y%m%d_%H%M)"
    if ! grep -iq "ssl:" /data/unifi-core/config.yaml; then
      tee -a /data/unifi-core/config.yaml &>/dev/null << SSL
# File created by EUS ( Easy UniFi Scripts ).
ssl:
  crt: '/data/eus_certificates/unifi-os.crt'
  key: '/data/eus_certificates/unifi-os.key'
SSL
    else
      unifi_os_crt_file=$(grep -i "crt:" /data/unifi-core/config.yaml | awk '{print$2}' | sed "s/'//g")
      unifi_os_key_file=$(grep -i "key:" /data/unifi-core/config.yaml | awk '{print$2}' | sed "s/'//g")
      sed -i "s#${unifi_os_crt_file}#/data/eus_certificates/unifi-os.crt#g" /data/unifi-core/config.yaml
      sed -i "s#${unifi_os_key_file}#/data/eus_certificates/unifi-os.key#g" /data/unifi-core/config.yaml
    fi
  fi
  if systemctl restart unifi-core; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi OS running on your ${unifi_core_device}!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi OS running on your ${unifi_core_device}..."; sleep 2; fi
  if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${script_option_skip_network_application}" != 'true' ]]; then
    unifi_status=$(systemctl status unifi | grep -i 'Active:' | awk '{print $2}')
    if [[ "${unifi_status}" == 'active' ]]; then
      unifi_network_application
    fi
  fi
  if [[ "${udm_device}" == 'true' && "${uid_agent}" != 'true' ]]; then
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "ls -la /mnt/data/udapi-config/raddb/certs/" | grep -iq "server.pem\\|server-key.pem" && [[ "${script_option_skip}" != 'true' ]]; then
      echo -e "\\n${YELLOW}#${RESET} ATTENTION, please backup your system before continuing!!"
      # shellcheck disable=2086
      read -rp $'\033[39m#\033[0m Do you want to apply the same certificates to RADIUS on your "'${unifi_core_device}'"? (y/N) ' yes_no
      case "$yes_no" in
          [Yy]*)
              mkdir -p /data/eus_certificates/raddb
              echo -e "\\n${WHITE_R}#${RESET} Backing up original server.pem certificate..."
              if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server.pem /data/eus_certificates/raddb/original_server_${time_date}.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully backed up server.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to backup RADIUS certificate... \\n"; sleep 5; return; fi
              echo -e "${WHITE_R}#${RESET} Backing up original server-key.pem certificate..."
              if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /mnt/data/udapi-config/raddb/certs/server-key.pem /data/eus_certificates/raddb/original_server-key_${time_date}.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully backed up server-key.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to backup RADIUS certificate... \\n"; sleep 5; return; fi
              echo -e "${WHITE_R}#${RESET} Applying new server.pem certificate..."
              if [[ -f "/data/eus_certificates/unifi-os.crt" ]]; then
                raddb_cert_file="/data/eus_certificates/unifi-os.crt"
              else
                cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /data/eus_certificates/raddb-server.pem
                raddb_cert_file="/data/eus_certificates/raddb-server.pem"
              fi
              if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp ${raddb_cert_file} /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully applied the new server.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to apply the new RADIUS certificate... \\n"; sleep 5; return; fi
              echo -e "${WHITE_R}#${RESET} Applying new server-key.pem certificate..."
              if [[ -f "/data/eus_certificates/unifi-os.key" ]]; then
                raddb_key_file="/data/eus_certificates/unifi-os.key"
              else
                cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /data/eus_certificates/raddb-server-key.pem
                raddb_key_file="/data/eus_certificates/raddb-server-key.pem"
              fi
              if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp ${raddb_key_file} /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully applied the new server-key.pem ( RADIUS certificate )! \\n"; else echo -e "${RED}#${RESET} Failed to apply the new RADIUS certificate... \\n"; sleep 5; return; fi
              echo -e "${WHITE_R}#${RESET} Restarting udapi-server..."
              if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/radius.log"; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort; fi
              sleep 3;;
          [Nn]*|"") ;;
      esac
    fi
  fi
}

uas_management_ui() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/uas/certs_backups/" && touch "${eus_dir}/uas/uas_management_ui"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Application Server User Interface..."
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.crt_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/uas/certs_backups/uas.key_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cp /etc/uas/uas.crt "${eus_dir}/uas/certs_backups/uas.crt_$(date +%Y%m%d_%H%M)"
  cp /etc/uas/uas.key "${eus_dir}/uas/certs_backups/uas.key_$(date +%Y%m%d_%H%M)"
  systemctl stop uas
  if [[ "${paid_cert}" == "true" ]]; then
    if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
      cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /etc/uas/uas.crt
    fi
    if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
      cp "${eus_dir}/paid-certificates/eus_key_file.key" /etc/uas/uas.key
    fi
  else
    if [[ -f "${fullchain_pem}.pem" ]]; then
      cp "${fullchain_pem}.pem" /etc/uas/uas.crt
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" /etc/uas/uas.crt
    fi
    if [[ -f "${priv_key_pem}.pem" ]]; then
      cp "${priv_key_pem}.pem" /etc/uas/uas.key
    elif [[ -f "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" ]]; then
      cp "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" /etc/uas/uas.key
    fi
  fi
  if systemctl start uas; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Application Server User Interface!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Application Server User Interface..."; sleep 2; fi
}

uas_unifi_led() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/eot/certs_backups" && touch "${eus_dir}/eot/uas_unifi_led"
  if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED on your UniFi Application Server..."; else echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED..."; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/eot/certs_backups/server.pem_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cat "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" > "${eus_dir}/eot/eot_docker_container.pem"
  eot_container=$(docker ps -a | grep -i "ubnt/eot" | awk '{print $1}')
  eot_container_name="ueot"
  if [[ -n "${eot_container}" ]]; then
    docker cp "${eot_container}:/app/certs/server.pem" "${eus_dir}/eot/certs_backups/server.pem_$(date +%Y%m%d_%H%M)"
    if [[ "${paid_cert}" == "true" ]]; then
      docker cp "${eus_dir}/paid-certificates/eus_certificates_file.pem" "${eot_container}:/app/certs/server.pem"
    else
      docker cp "${eus_dir}/eot/eot_docker_container.pem" "${eot_container}:/app/certs/server.pem"
    fi
    docker restart "${eot_container_name}" &>> "${eus_dir}/eot/ueot_container_restart" && if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server"; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED on your UniFi Application Server..." || echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-LED on your UniFi Application Server... \\n"; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED!" || echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-LED... \\n"; fi && sleep 2
  else
    rm --force "${eus_dir}/eot/uas_unifi_led" 2> /dev/null
    echo -e "${RED}#${RESET} Couldn't find UniFi LED container..." && sleep 2
  fi
}

unifi_video() {
  # shellcheck disable=SC2012
  mkdir -p "${eus_dir}/video/keystore_backups" && touch "${eus_dir}/video/unifi_video"
  echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Video..."
  mkdir -p /usr/lib/unifi-video/data/certificates
  mkdir -p /var/lib/unifi-video/certificates
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/video/keystore_backups/ufv-truststore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mv /usr/lib/unifi-video/data/keystore "${eus_dir}/video/keystore_backups/keystore_$(date +%Y%m%d_%H%M)"
  mv /usr/lib/unifi-video/data/ufv-truststore "${eus_dir}/video/keystore_backups/ufv-truststore_$(date +%Y%m%d_%H%M)"
  if [[ "${paid_cert}" == "true" ]]; then
    cp "${eus_dir}/paid-certificates/ufv-server.key.der" /usr/lib/unifi-video/data/certificates/ufv-server.key.der
    cp "${eus_dir}/paid-certificates/ufv-server.cert.der" /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
  else
    openssl pkcs8 -topk8 -nocrypt -in "/etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem" -outform DER -out /usr/lib/unifi-video/data/certificates/ufv-server.key.der
    openssl x509 -outform der -in "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" -out /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
  fi
  chown -R unifi-video:unifi-video /usr/lib/unifi-video/data/certificates
  systemctl stop unifi-video
  if ! grep -iq "^ufv.custom.certs.enable=true" /usr/lib/unifi-video/data/system.properties; then
    echo "ufv.custom.certs.enable=true" &>> /usr/lib/unifi-video/data/system.properties
  fi
  if systemctl start unifi-video; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Video!"; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into UniFi-Video..."; sleep 2; fi
}

unifi_network_application() {
  if [[ "${unifi_core_system}" == 'true' ]]; then echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Application running on your ${unifi_core_device}..."; else echo -e "\\n${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Application..."; fi
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/lets_encrypt_import.log"
  if sha256sum "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" 2> /dev/null | awk '{print $1}' &> "${eus_dir}/checksum/fullchain.sha256sum"; then echo "Successfully updated sha256sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"; fi
  if md5sum "/etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem" 2> /dev/null | awk '{print $1}' &> "${eus_dir}/checksum/fullchain.md5sum"; then echo "Successfully updated md5sum" &>> "${eus_dir}/logs/lets_encrypt_import.log"; fi
  # shellcheck disable=SC2012
  if [[ "${old_certificates}" == 'last_three' ]]; then ls -t "${eus_dir}/network/keystore_backups/keystore_*" 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mkdir -p "${eus_dir}/network/keystore_backups" && cp /usr/lib/unifi/data/keystore "${eus_dir}/network/keystore_backups/keystore_$(date +%Y%m%d_%H%M)"
  # shellcheck disable=SC2012,SC2129
  if [[ "${paid_cert}" == "true" ]]; then
    keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/paid_certificate_import.log"
    keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${eus_dir}/paid-certificates/eus_unifi.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/paid_certificate_import.log"
  else
    openssl pkcs12 -export -inkey "${priv_key_pem}.pem" -in "${fullchain_pem}.pem" -out "${fullchain_pem}.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/lets_encrypt_import.log"
    keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/lets_encrypt_import.log"
    keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${fullchain_pem}.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/lets_encrypt_import.log"
  fi
  chown -R unifi:unifi /usr/lib/unifi/data/keystore &> /dev/null
  if systemctl restart unifi; then
    if [[ "${unifi_core_system}" == 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Application running on your ${unifi_core_device}!"; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Application!"; fi
  else
    if [[ "${unifi_core_system}" == 'true' ]]; then echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Network Application running on your ${unifi_core_device}..."; else echo -e "${RED}#${RESET} Failed to import the SSL certificates into the UniFi Network Application..."; fi
    sleep 2
  fi
  if [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'Keystore was tampered with, or password was incorrect' "${eus_dir}/logs/lets_encrypt_import.log"; then
    if ! [[ -f "${eus_dir}/network/failed" ]]; then
      echo -e "${RED}#${RESET} Importing into the UniFi Network Application failed.. let's clean up some files and try it one more time."
      rm --force /usr/lib/unifi/data/keystore 2> /dev/null && systemctl restart unifi
      rm --force "${eus_dir}/logs/lets_encrypt_import.log" 2> /dev/null
      mkdir -p "${eus_dir}/network/" && touch "${eus_dir}/network/failed"
	  unifi_network_application
    else
      le_import_failed
    fi
  fi
}

import_ssl_certificates() {
  header
  if [[ "${prefer_dns_challenge}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Performing the DNS challenge!"
    echo ""
    if [[ "${certbot_auto}" == 'true' ]]; then
      # shellcheck disable=2086
      ${certbot} certonly --manual --agree-tos --preferred-challenges dns ${server_fqdn_le} ${email} ${renewal_option} --manual-public-ip-logging-ok "${certbot_auto_flags}" 2>&1 | tee -a "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_certbot_success=true
    else
      # shellcheck disable=2086
      ${certbot} certonly --manual --agree-tos --preferred-challenges dns ${server_fqdn_le} ${email} ${renewal_option} --manual-public-ip-logging-ok 2>&1 | tee -a "${eus_dir}/logs/lets_encrypt_${time_date}.log" && dns_certbot_success=true
    fi
  else
    if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${renewal_option}" == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates and importing them into UniFi OS running on your ${unifi_core_device}..."
      else
        echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi OS running on your ${unifi_core_device}..."
      fi
    elif dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if [[ "${renewal_option}" == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates and importing them into the UniFi Network Application..."
      else
        echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Application..."
      fi
    else
      if [[ "${renewal_option}" == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates"
      else
        echo -e "${WHITE_R}#${RESET} Creating the certificates!"
      fi
    fi
    if [[ "${certbot_auto}" == 'true' ]]; then
      # shellcheck disable=2086
      ${certbot} certonly --standalone --agree-tos --preferred-challenges http --pre-hook "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${server_fqdn_le} ${email} ${renewal_option} --non-interactive "${certbot_auto_flags}" &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && certbot_success=true
    else
      # shellcheck disable=2086
      ${certbot} certonly --standalone --agree-tos --preferred-challenges http --pre-hook "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" --post-hook "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" ${server_fqdn_le} ${email} ${renewal_option} --non-interactive &> "${eus_dir}/logs/lets_encrypt_${time_date}.log" && certbot_success=true
    fi
  fi
  if [[ "${certbot_success}" == 'true' ]] || [[ "${dns_certbot_success}" == 'true' ]]; then
    if [[ "${certbot_success}" == 'true' ]] || [[ "${dns_certbot_success}" == 'true' ]]; then
      if [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'Keystore was tampered with, or password was incorrect' "${eus_dir}/logs/lets_encrypt_import.log"; then
        mkdir -p "${eus_dir}/network/" && touch "${eus_dir}/network/failed"
        unifi_network_application
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'Incorrect TXT record' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} The created TXT record is incorrect..."
        rm --force "${eus_dir}/txt_record" &> /dev/null
        dig +short TXT "_acme-challenge.${server_fqdn}" "${external_dns_server}" &>> "${eus_dir}/txt_record"
        txt_dig=$(head -n1 "${eus_dir}/txt_record")
        echo -e "${RED}#${RESET} TXT record for _acme-challenge.${server_fqdn} is '${txt_dig}'."
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && grep -iq 'No TXT record found' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        le_import_failed
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'Dns problem' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} There is an error looking up DNS record _acme-challenge.${server_fqdn}..."
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'Invalid response from' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} Invalid response from \"http://${server_fqdn}/.well-known/acme-challenge/xxxxxxxxxxxxxxxxxxx\"..."
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_${time_date}.log" ]] && grep -iq 'too many requests' "${eus_dir}/logs/lets_encrypt_${time_date}.log"; then
        header_red
        echo -e "${RED}#${RESET} There have been to many requests for ${server_fqdn}... \\n${RED}#${RESET} See https://letsencrypt.org/docs/rate-limits/ for more details..."
        abort
      elif [[ -f "${eus_dir}/logs/lets_encrypt_import.log" ]] && tail -n5 "${eus_dir}/logs/lets_encrypt_import.log" | grep -iq 'Error'; then
        header_red
        echo -e "${RED}#${RESET} An unknown error occured..."
        abort
      else
        if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi OS! \\n"; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Application! \\n"; fi
        if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi
      fi
      if ls "${eus_dir}/logs/lets_encrypt_[0-9]*.log" &>/dev/null; then
        le_var=$(grep -i "/etc/letsencrypt/live/${server_fqdn}" "${eus_dir}/logs/lets_encrypt_${time_date}.log" | awk '{print $1}' | head -n1 | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
      fi
    fi
    if [[ "${dns_certbot_success}" == 'true' ]]; then
      header
      echo -e "${GREEN}#${RESET} Successfully created the SSL Certificates!"
      if [[ "${certbot_auto}" == 'true' ]]; then
        # shellcheck disable=2086
        ${certbot} certificates --domain "${server_fqdn}" "${certbot_auto_flags}" &>> "${eus_dir}/certificates"
      else
        # shellcheck disable=2086
        ${certbot} certificates --domain "${server_fqdn}" &>> "${eus_dir}/certificates"
      fi
      le_fqdn=$(grep -io "${server_fqdn}.*" "${eus_dir}/certificates" | cut -d'/' -f1 | tail -n1)
      fullchain_pem=$(grep -i "Certificate Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $3}' | sed 's/.pem//g' | tail -n1)
      priv_key_pem=$(grep -i "Private Key Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $4}' | sed 's/.pem//g' | tail -n1)
      if [[ "${unifi_core_system}" == 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi OS? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
              unifi_core
              if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
           [Nn]*) ;;
        esac
      elif dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi Network Application has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Network Application? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
              unifi_network_application
              if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
           [Nn]*) ;;
        esac
      fi
    fi
    if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
      if [[ "${is_cloudkey_gen2_plus}" == 'true' ]] && dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface and UniFi-Protect? (Y/n) ' yes_no; fi
      else
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface? (Y/n) ' yes_no; fi
      fi
      case "$yes_no" in
         [Yy]*|"")
            cloudkey_management_ui
            run_uck_scripts=true;;
         [Nn]*) ;;
      esac
      if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
            cloudkey_unifi_led
            run_uck_scripts=true;;
           [Nn]*) ;;
        esac
      fi
      if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Talk? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"")
            cloudkey_unifi_talk
            run_uck_scripts=true;;
           [Nn]*) ;;
        esac
      fi
    fi
    if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Application Server User Interface? (Y/n) ' yes_no; fi
      case "$yes_no" in
         [Yy]*|"") uas_management_ui;;
         [Nn]*) ;;
      esac
      if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
        if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
          if docker ps -a | grep -iq 'ubnt/eot'; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
            case "$yes_no" in
                [Yy]*|"") uas_unifi_led;;
                [Nn]*) ;;
            esac
          fi
        fi
      fi
    fi
    if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Video? (Y/n) ' yes_no; fi
      case "$yes_no" in
         [Yy]*|"") unifi_video;;
         [Nn]*) ;;
      esac
    fi
    if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce" && [[ "${unifi_core_system}" != 'true' ]]; then
      if docker ps -a | grep -iq 'ubnt/eot'; then
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
        if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
        case "$yes_no" in
           [Yy]*|"") uas_unifi_led;;
           [Nn]*) ;;
        esac
      fi
    fi
    if [[ "${dns_certbot_success}" == 'true' ]]; then
      rm --force "${eus_dir}/expire_date" &> /dev/null
      rm --force "/etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh" &> /dev/null
      rm --force "/etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh" &> /dev/null
      certbot certificates --domain "${server_fqdn}" &>> "${eus_dir}/expire_date"
      if grep -iq "${server_fqdn}" "${eus_dir}/expire_date"; then
        expire_date=$(grep -i "Expiry Date:" "${eus_dir}/expire_date" | awk '{print $3}')
      fi
      rm --force "${eus_dir}/expire_date" &> /dev/null
      if [[ -n "${expire_date}" ]]; then
         echo -e "\\n${GREEN}---${RESET}\\n"
         echo -e "${WHITE_R}#${RESET} Your SSL certificates will expire at '${expire_date}'"
         echo -e "${WHITE_R}#${RESET} Please run this script again before '${expire_date}' to renew your certificates"
      fi
    fi
  else
    le_import_failed
  fi
}

import_existing_ssl_certificates() {
  case "$yes_no" in
     [Yy]*|"")
        if [[ "${unifi_core_system}" == 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi OS? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"")
                unifi_core
                if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
             [Nn]*) ;;
          esac
        fi
        if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} UniFi Network Application has been detected!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Network Application? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"")
                unifi_network_application
                if [[ "${is_cloudkey}" == 'true' ]]; then run_uck_scripts=true; fi;;
             [Nn]*) ;;
          esac
        fi
        if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
          if [[ "${is_cloudkey_gen2_plus}" == 'true' ]] && dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface and UniFi-Protect? (Y/n) ' yes_no; fi
          else
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface? (Y/n) ' yes_no; fi
          fi
          case "$yes_no" in
             [Yy]*|"")
                  cloudkey_management_ui
                  run_uck_scripts=true;;
             [Nn]*) ;;
          esac
          if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
            case "$yes_no" in
               [Yy]*|"")
                  cloudkey_unifi_led
                  run_uck_scripts=true;;
               [Nn]*) ;;
            esac
          fi
          if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Talk? (Y/n) ' yes_no; fi
            case "$yes_no" in
               [Yy]*|"")
                  cloudkey_unifi_talk
                  run_uck_scripts=true;;
               [Nn]*) ;;
            esac
          fi
        fi
        if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Application Server User Interface? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"") uas_management_ui;;
             [Nn]*) ;;
          esac
          if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
            if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
              if docker ps -a | grep -iq 'ubnt/eot'; then
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
                if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
                case "$yes_no" in
                    [Yy]*|"") uas_unifi_led;;
                    [Nn]*) ;;
                esac
              fi
            fi
          fi
        fi
        if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
          if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Video? (Y/n) ' yes_no; fi
          case "$yes_no" in
             [Yy]*|"") unifi_video;;
             [Nn]*) ;;
          esac
        fi
        if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce" && [[ "${unifi_core_system}" != 'true' ]]; then
          if docker ps -a | grep -iq 'ubnt/eot'; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no; fi
            case "$yes_no" in
               [Yy]*|"") uas_unifi_led;;
               [Nn]*) ;;
            esac
          fi
        fi;;
     [Nn]*) ;;
  esac
}

restore_previous_certs() {
  case "$yes_no" in
     [Yy]*)
        if [[ "${unifi_core_system}" == 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/unifi-os/config_backups/" ]]; then unifi_os_previous_config=$(ls -t "${eus_dir}/unifi-os/config_backups/" | awk '{print$1}' | head -n1); fi
          if [[ -n "${unifi_os_previous_config}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore the certificates to original state? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous certificate configuration? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  if [[ "${restore_original_state}" == 'true' ]]; then
                    echo -e "\\n${WHITE_R}#${RESET} Restoring UniFi OS certificates to original state..."
                    if [[ -f "/data/unifi-core/config.yaml" ]]; then
                      if sed -i -e "/File created by EUS/d" -e "/ssl:/d" -e "/crt:/d" -e "/key:/d" /data/unifi-core/config.yaml &>> "${eus_dir}/logs/restore.log"; then
                        if ! [[ -s "/data/unifi-core/config.yaml" ]]; then rm --force "/data/unifi-core/config.yaml" &> /dev/null; fi
                        echo -e "${GREEN}#${RESET} Successfully restored UniFi OS certificates to original state! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                        if systemctl restart unifi-core; then
                          echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                        else
                          echo -e "${RED}#${RESET} Failed to restart UniFi OS... \\n"; abort
                        fi
                      else
                        echo -e "${RED}#${RESET} Failed to restore UniFi OS certificates to original state..."; abort
                      fi
                    else
                      echo -e "${YELLOW}#${RESET} UniFi OS is already in default state..."
                    fi
                  else
                    echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}\"..."
                    if cp "${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}" /data/unifi-core/config.yaml &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}\"! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                      if systemctl restart unifi-core; then
                        echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                      else
                        echo -e "${RED}#${RESET} Failed to restart UniFi OS... \\n"; abort
                      fi
                    else
                      echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/unifi-os/config_backups/${unifi_os_previous_config}\"..."; abort
                    fi
                  fi;;
               [Nn]*) ;;
            esac
          else
            if [[ -f "/data/unifi-core/config.yaml" ]]; then
              echo -e "\\n${WHITE_R}----${RESET}\\n"
              echo -e "${WHITE_R}#${RESET} UniFi OS on your ${unifi_core_device} has been detected!"
              read -rp $'\033[39m#\033[0m Do you want to restore to the default UniFi OS certificates? (Y/n) ' yes_no
              case "$yes_no" in
                 [Yy]*|"")
                    restore_done=yes
                    echo -e "\\n${WHITE_R}#${RESET} Restoring to default UniFi OS certificates..."
                    if rm --force "/data/unifi-core/config.yaml" &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored default UniFi OS certificates! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting UniFi OS..."
                      if systemctl restart unifi-core; then
                        echo -e "${GREEN}#${RESET} Successfully restarted UniFi OS! \\n"
                      else
                        echo -e "${RED}#${RESET} Failed to restart UniFi OS... \\n"; abort
                      fi
                    else
                      echo -e "${RED}#${RESET} Failed to restore default UniFi OS certificates..."; abort
                    fi;;
                 [Nn]*) ;;
              esac
            fi
          fi
          # shellcheck disable=SC2012
          if [[ -d "/data/eus_certificates/raddb/" ]]; then radius_previous_crt=$(ls -t /data/eus_certificates/raddb/ | awk '{print$1}' | grep ".*server_.*.pem" | head -n1); radius_previous_key=$(ls -t /data/eus_certificates/raddb/ | awk '{print$1}' | grep ".*server-key_.*.pem" | head -n1); fi
          if [[ -n "${radius_previous_key}" && -n "${radius_previous_crt}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} You seem to have replaced the default RADIUS certificates on your ${unifi_core_device}!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore to the default certificates? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous RADIUS certificates? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                    restore_done=yes
                    if [[ "${restore_original_state}" == 'true' ]]; then
                      echo -e "\\n${WHITE_R}#${RESET} Restoring to the default RADIUS certificates..."
                      if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "rm /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/restore.log" && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "rm /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored to the default RADIUS certificates! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting udapi-server..."
                        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/restore.log"; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort; fi
                      else
                        echo -e "${RED}#${RESET} Failed to restore to the default RADIUS certificates..."; abort
                      fi
                    else
                      echo -e "\\n${WHITE_R}#${RESET} Restoring \"/data/eus_certificates/raddb/${radius_previous_crt}\" and \"/data/eus_certificates/raddb/${radius_previous_key}\"..."
                      if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /data/eus_certificates/raddb/${radius_previous_crt} /mnt/data/udapi-config/raddb/certs/server.pem" &>> "${eus_dir}/logs/restore.log" && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "cp /data/eus_certificates/raddb/${radius_previous_key} /mnt/data/udapi-config/raddb/certs/server-key.pem" &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored \"/data/eus_certificates/raddb/${radius_previous_crt}\" and \"/data/eus_certificates/raddb/${radius_previous_key}\"! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting udapi-server..."
                        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "/etc/init.d/S45ubios-udapi-server restart" &>> "${eus_dir}/logs/restore.log"; then echo -e "${GREEN}#${RESET} Successfully restarted udapi-server! \\n"; else echo -e "${RED}#${RESET} Failed to restart udapi-server... \\n${RED}#${RESET} Please reboot your UDM ASAP!\\n"; abort; fi
                      else
                        echo -e "${RED}#${RESET} Failed to restore \"/data/eus_certificates/raddb/${radius_previous_crt}\" and \"/data/eus_certificates/raddb/${radius_previous_key}\"..."; abort
                      fi
                    fi;;
               [Nn]*) ;;
            esac
          fi
        fi
        if dpkg -l unifi 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/network/keystore_backups/" ]]; then unifi_network_previous_keystore=$(ls -t "${eus_dir}/network/keystore_backups/" | awk '{print$1}' | head -n1); fi
          if [[ -n "${unifi_network_previous_keystore}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi Network Application has been detected!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore to default keystore? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous keystore? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  if [[ "${restore_original_state}" == 'true' ]]; then
                    echo -e "\\n${WHITE_R}#${RESET} Restoring UniFi Network Application to default keystore..."
                    if rm --force /usr/lib/unifi/data/keystore &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored UniFi Network Application to default keystore! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting the UniFi Network Application..."
                      if systemctl restart unifi; then
                        echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"
                      else
                        echo -e "${RED}#${RESET} Failed to restart the UniFi Network Application... \\n"; abort
                      fi
                    else
                      echo -e "${RED}#${RESET} Failed to restore UniFi Network Application to default keystore..."; abort
                    fi
                  else
                    echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}\"..."
                    if cp "${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}" /usr/lib/unifi/data/keystore &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}\"! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting the UniFi Network Application..."
                      if systemctl restart unifi; then
                        echo -e "${GREEN}#${RESET} Successfully restarted the UniFi Network Application! \\n"
                      else
                        echo -e "${RED}#${RESET} Failed to restart the UniFi Network Application... \\n"; abort
                      fi
                    else
                      echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/network/keystore_backups/${unifi_network_previous_keystore}\"..."; abort
                    fi
                  fi;;
               [Nn]*) ;;
            esac
          fi
        fi
        if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/cloudkey/certs_backups/" ]]; then cloudkey_previous_crt=$(ls -t "${eus_dir}/cloudkey/certs_backups/" | awk '{print$1}' | grep "cloudkey.crt" | head -n1); cloudkey_previous_key=$(ls -t "${eus_dir}/cloudkey/certs_backups/" | awk '{print$1}' | grep "cloudkey.key" | head -n1); fi
          if [[ -n "${cloudkey_previous_crt}" && -n "${cloudkey_previous_key}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
            if [[ "${restore_original_state}" == 'true' ]]; then
              read -rp $'\033[39m#\033[0m Do you want to restore to the default certificates? (Y/n) ' yes_no
            else
              read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
            fi
            case "$yes_no" in
               [Yy]*|"")
                    restore_done=yes
                    if [[ "${restore_original_state}" == 'true' ]]; then
                      echo -e "\\n${WHITE_R}#${RESET} Restoring Cloudkey Web Interface to default certificates..."
                      if rm --force /etc/ssl/private/cloudkey.crt &>> "${eus_dir}/logs/restore.log" && rm --force /etc/ssl/private/cloudkey.key &>> "${eus_dir}/logs/restore.log" && rm --force /etc/ssl/private/unifi.keystore.jks &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored Cloudkey Web Interface to default certificates! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting the Cloudkey Web Interface..."
                        if systemctl restart ubnt-unifi-setup nginx; then
                          echo -e "${GREEN}#${RESET} Successfully restarted Cloudkey Web Interface! \\n"
                        else
                          echo -e "${RED}#${RESET} Failed to restart the Cloudkey Web Interface... \\n"; abort
                        fi
                        if dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi Protect..."
                             if systemctl restart unifi-protect; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi Protect! \\n"
                            else
                              echo -e "${RED}#${RESET} Failed to restart UniFi Protect... \\n"; abort
                            fi
                          fi
                        fi
                        if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-led | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi LED..."
                            if systemctl restart unifi-led; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi LED! \\n"
                            else
                              echo -e "${RED}#${RESET} Failed to restart UniFi LED... \\n"; abort
                            fi
                          fi
                        fi
                      else
                        echo -e "${RED}#${RESET} Failed to restore Cloudkey Web Interface to default certificates..."; abort
                      fi
                    else
                      echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}\" and \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}\"..."
                      if cp "${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}" /etc/ssl/private/cloudkey.crt &>> "${eus_dir}/logs/restore.log" && cp "${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}" /etc/ssl/private/cloudkey.key &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}\" and \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}\"! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting the Cloudkey Web Interface..."
                        if systemctl restart nginx; then
                          echo -e "${GREEN}#${RESET} Successfully restarted Cloudkey Web Interface! \\n"
                        else
                          echo -e "${RED}#${RESET} Failed to restart the Cloudkey Web Interface... \\n"; abort
                        fi
                        if dpkg -l unifi-protect 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-protect | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi Protect..."
                             if systemctl restart unifi-protect; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi Protect! \\n"
                            else
                              echo -e "${RED}#${RESET} Failed to restart UniFi Protect... \\n"; abort
                            fi
                          fi
                        fi
                        if dpkg -l unifi-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
                          unifi_protect_status=$(systemctl status unifi-led | grep -i 'Active:' | awk '{print $2}')
                          if [[ "${unifi_protect_status}" == 'active' ]]; then
                            echo -e "${WHITE_R}#${RESET} Restarting UniFi LED..."
                            if systemctl restart unifi-led; then
                              echo -e "${GREEN}#${RESET} Successfully restarted UniFi LED! \\n"
                            else
                              echo -e "${RED}#${RESET} Failed to restart UniFi LED... \\n"; abort
                            fi
                          fi
                        fi
                      else
                        echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_crt}\" and \"${eus_dir}/cloudkey/certs_backups/${cloudkey_previous_key}\"..."; abort
                      fi
                    fi;;
               [Nn]*) ;;
            esac
            if dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' && "${restore_original_state}" != 'true' ]]; then
              # shellcheck disable=SC2012
              if [[ -d "${eus_dir}/talk/certs_backups/" ]]; then cloudkey_talk_previous_server_pem=$(ls -t "${eus_dir}/talk/certs_backups/" | awk '{print$1}' | grep "server.pem" | head -n1); fi
              if [[ -n "${cloudkey_talk_previous_server_pem}" ]]; then
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
                read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificate? (Y/n) ' yes_no
                case "$yes_no" in
                   [Yy]*|"")
                      restore_done=yes
                      echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}\"..."
                      if cp "${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}" /usr/share/unifi-talk/app/certs/server.pem &>> "${eus_dir}/logs/restore.log"; then
                        echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}\"! \\n"
                        echo -e "${WHITE_R}#${RESET} Restarting UniFi Talk..."
                        if systemctl restart unifi-talk; then
                          echo -e "${GREEN}#${RESET} Successfully restarted UniFi Talk! \\n"
                        else
                          echo -e "${RED}#${RESET} Failed to restart the UniFi service... \\n"; abort
                        fi
                      else
                        echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/talk/certs_backups/${cloudkey_talk_previous_server_pem}\"..."; abort
                      fi;;
                   [Nn]*) ;;
                esac
              fi
            fi
          fi
        fi
        if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' && "${restore_original_state}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/uas/certs_backups/" ]]; then uas_previous_crt=$(ls -t "${eus_dir}/uas/certs_backups/" | awk '{print$1}' | grep "uas.crt" | head -n1); uas_previous_key=$(ls -t "${eus_dir}/uas/certs_backups/" | awk '{print$1}' | grep "uas.key" | head -n1); fi
          if [[ -n "${uas_previous_crt}" && -n "${uas_previous_key}" ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
            read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/uas/certs_backups/${uas_previous_crt}\" and \"${eus_dir}/uas/certs_backups/${uas_previous_key}\"..."
                  if cp "${eus_dir}/uas/certs_backups/${uas_previous_crt}" /etc/uas/uas.crt &>> "${eus_dir}/logs/restore.log" && cp "${eus_dir}/uas/certs_backups/${uas_previous_key}" /etc/uas/uas.key &>> "${eus_dir}/logs/restore.log"; then
                    echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/uas/certs_backups/${uas_previous_crt}\" and \"${eus_dir}/uas/certs_backups/${uas_previous_key}\"! \\n"
                    echo -e "${WHITE_R}#${RESET} Restarting the UAS Web Interface..."
                    if systemctl restart uas; then
                      echo -e "${GREEN}#${RESET} Successfully restarted UAS Web Interface! \\n"
                    else
                      echo -e "${RED}#${RESET} Failed to restart the UAS Web Interface... \\n"; abort
                    fi
                  else
                    echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/uas/certs_backups/${uas_previous_crt}\" and \"${eus_dir}/uas/certs_backups/${uas_previous_key}\"..."; abort
                  fi;;
               [Nn]*) ;;
            esac
            if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
              # shellcheck disable=SC2012
              if [[ -d "${eus_dir}/eot/certs_backups/" ]]; then uas_led_previous_server_pem=$(ls -t "${eus_dir}/eot/certs_backups/" | awk '{print$1}' | grep "server.pem" | head -n1); fi
              if [[ -n "${uas_led_previous_server_pem}" ]]; then
                if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
                  if docker ps -a | grep -iq 'ubnt/eot'; then
                    echo -e "\\n${WHITE_R}----${RESET}\\n"
                    echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
                    read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
                    case "$yes_no" in
                        [Yy]*|"")
                           restore_done=yes
                           eot_container=$(docker ps -a | grep -i "ubnt/eot" | awk '{print $1}')
                           eot_container_name="ueot"
                           if [[ -n "${eot_container}" ]]; then
                             echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"..."
                             if docker cp "${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}" "${eot_container}:/app/certs/server.pem" &>> "${eus_dir}/logs/restore.log"; then
                               echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"! \\n"
                               echo -e "${WHITE_R}#${RESET} Restarting the UniFi LED container..."
                               if docker restart "${eot_container_name}" &>> "${eus_dir}/eot/ueot_container_restart"; then
                                 echo -e "${GREEN}#${RESET} Successfully restarted the UniFi LED container! \\n"
                               else
                                 echo -e "${RED}#${RESET} Failed to restart the UniFi LED container... \\n"; abort
                               fi
                             else
                               echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"..."; abort
                             fi
                           else
                             echo -e "${RED}#${RESET} Couldn't find UniFi LED container..."; abort
                           fi;;
                        [Nn]*) ;;
                    esac
                  fi
                fi
              fi
            fi
          fi
        fi
        if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/video/keystore_backups/" ]]; then unifi_video_previous_cert=$(ls -t "${eus_dir}/video/keystore_backups/" | awk '{print$1}' | grep "keystore" | head -n1); unifi_video_previous_key=$(ls -t "${eus_dir}/video/keystore_backups/" | awk '{print$1}' | grep "ufv-truststore" | head -n1); fi
          if [[ -n "${unifi_video_previous_cert}" && -n "${unifi_video_previous_key}" && "${restore_original_state}" != 'true' ]]; then
            echo -e "\\n${WHITE_R}----${RESET}\\n"
            echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
            read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  restore_done=yes
                  echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}\" and \"${eus_dir}/video/keystore_backups/${unifi_video_previous_key}\"..."
                  if cp "${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}" /usr/lib/unifi-video/data/certificates/ufv-server.cert.der &>> "${eus_dir}/logs/restore.log" && cp "${eus_dir}/video/keystore_backups/${unifi_video_previous_key}" /usr/lib/unifi-video/data/certificates/ufv-server.key.der &>> "${eus_dir}/logs/restore.log"; then
                    echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}\" and \"${eus_dir}/video/keystore_backups/${unifi_video_previous_key}\"! \\n"
                    echo -e "${WHITE_R}#${RESET} Restarting UniFi video..."
                    if systemctl restart uas; then
                      echo -e "${GREEN}#${RESET} Successfully restarted UniFi video! \\n"
                    else
                      echo -e "${RED}#${RESET} Failed to restart UniFi video... \\n"; abort
                    fi
                  else
                    echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/video/keystore_backups/${unifi_video_previous_cert}\" and \"${eus_dir}/video/keystore_backups/${unifi_video_previous_key}\"..."; abort
                  fi;;
               [Nn]*) ;;
            esac
          else
            if grep -iq "^ufv.custom.certs.enable=true" /usr/lib/unifi-video/data/system.properties; then
              echo -e "\\n${WHITE_R}----${RESET}\\n"
              echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
              read -rp $'\033[39m#\033[0m Do you want to restore to the default SSL certificates? (Y/n) ' yes_no
              case "$yes_no" in
                 [Yy]*|"")
                    restore_done=yes
                    echo -e "\\n${WHITE_R}#${RESET} Restoring to default UniFi Video certificates..."
                    if sed -i "s/ufv.custom.certs.enable=true/ufv.custom.certs.enable=false/g" /usr/lib/unifi-video/data/system.properties &>> "${eus_dir}/logs/restore.log"; then
                      echo -e "${GREEN}#${RESET} Successfully set custom certificates for UniFi Video to false! \\n"
                      echo -e "${WHITE_R}#${RESET} Restarting UniFi Video..."
                      if systemctl restart unifi-video; then
                        echo -e "${GREEN}#${RESET} Successfully restarted UniFi Video! \\n"
                      else
                        echo -e "${RED}#${RESET} Failed to restart UniFi Video... \\n"; abort
                      fi
                    else
                      echo -e "${RED}#${RESET} Failed to change custom certificate value for UniFi Video..."; abort
                    fi;;
                 [Nn]*) ;;
              esac
            fi
          fi
        fi
        if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce" && [[ "${unifi_core_system}" != 'true' && "${restore_original_state}" != 'true' ]]; then
          # shellcheck disable=SC2012
          if [[ -d "${eus_dir}/eot/certs_backups/" ]]; then uas_led_previous_server_pem=$(ls -t "${eus_dir}/eot/certs_backups/" | awk '{print$1}' | grep "server.pem" | head -n1); fi
          if [[ -n "${uas_led_previous_server_pem}" ]]; then
            if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then
              if docker ps -a | grep -iq 'ubnt/eot'; then
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
                read -rp $'\033[39m#\033[0m Do you want to restore the previous SSL certificates? (Y/n) ' yes_no
                case "$yes_no" in
                    [Yy]*|"")
                       restore_done=yes
                       eot_container=$(docker ps -a | grep -i "ubnt/eot" | awk '{print $1}')
                       eot_container_name="ueot"
                       if [[ -n "${eot_container}" ]]; then
                         echo -e "\\n${WHITE_R}#${RESET} Restoring \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"..."
                         if docker cp "${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}" "${eot_container}:/app/certs/server.pem" &>> "${eus_dir}/logs/restore.log"; then
                           echo -e "${GREEN}#${RESET} Successfully restored \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"! \\n"
                           echo -e "${WHITE_R}#${RESET} Restarting the UniFi LED container..."
                           if docker restart "${eot_container_name}" &>> "${eus_dir}/eot/ueot_container_restart"; then
                             echo -e "${GREEN}#${RESET} Successfully restarted the UniFi LED container! \\n"
                           else
                             echo -e "${RED}#${RESET} Failed to restart the UniFi LED container... \\n"; abort
                           fi
                         else
                           echo -e "${RED}#${RESET} Failed to restore \"${eus_dir}/eot/certs_backups/${uas_led_previous_server_pem}\"..."; abort
                         fi
                       else
                         echo -e "${RED}#${RESET} Couldn't find UniFi LED container..."; abort
                       fi;;
                    [Nn]*) ;;
                esac
              fi
            fi
          fi
        fi;;
     [Nn]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Canceling restore certificates... \\n"
        author
        exit 0;;
  esac
  if [[ "${restore_done}" != 'yes' ]]; then
    header
    echo -e "${YELLOW}#${RESET} Nothing has been restored... \\n"
    author
    exit 0
  else
    header
    echo -e "${GREEN}#${RESET} The script successfully restored your certificates/configs! \\n"
    author
    exit 0
  fi
}

if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  unifi_core_system=true
  if grep -ioq "udm" /usr/lib/version; then udm_device=true; fi
  if dpkg -l uid-agent 2> /dev/null | grep -iq "^ii\\|^hi"; then uid_agent=$(curl -s http://localhost:11081/api/controllers | jq '.[] | select(.name == "uid-agent").isConfigured'); fi
  if [[ -f /proc/ubnthal/system.info ]]; then if grep -iq "shortname" /proc/ubnthal/system.info; then unifi_core_device=$(grep "shortname" /proc/ubnthal/system.info | sed 's/shortname=//g'); fi; fi
  if [[ -f /etc/motd && -s /etc/motd && -z "${unifi_core_device}" ]]; then unifi_core_device=$(grep -io "welcome.*" /etc/motd | sed -e 's/Welcome //g' -e 's/to //g' -e 's/the //g' -e 's/!//g'); fi
  if [[ -f /usr/lib/version && -s /usr/lib/version && -z "${unifi_core_device}" ]]; then unifi_core_device=$(cut -d'.' -f1 /usr/lib/version); fi
  if [[ -z "${unifi_core_device}" ]]; then unifi_core_device='Unknown device'; fi
fi

remove_old_post_pre_hook() {
  if [[ "$(find /etc/letsencrypt/renewal-hooks/post/ /etc/letsencrypt/renewal-hooks/pre/ -printf "%f\\n" | sed -e '/post/d' -e '/pre/d' -e "/EUS_${server_fqdn}.sh/d" | awk '!NF || !seen[$0]++' | grep -ioc "EUS.*.sh")" -ge "1" ]]; then
    if ! [[ -d /tmp/EUS/hook/ ]]; then mkdir -p /tmp/EUS/hook/ &> /dev/null; fi
    find /etc/letsencrypt/renewal-hooks/post/ /etc/letsencrypt/renewal-hooks/pre/ -printf "%f\\n" | sed -e '/post/d' -e '/pre/d' -e "/EUS_${server_fqdn}.sh/d" | awk '!NF || !seen[$0]++' | grep -io "EUS.*.sh" &> /tmp/EUS/hook/list
    header
    echo -e "${WHITE_R}#${RESET} You seem to have multiple post/pre hook scripts for multiple domains."
    echo -e "${WHITE_R}#${RESET} Having multiple post/pre hook scripts can result in older domain/certificates being used. \\n"
    echo -e "${WHITE_R}#${RESET} post/pre scripts:"
    while read -r script_name; do echo -e "${WHITE_R}-${RESET} \"${script_name}\""; done < /tmp/EUS/hook/list
    echo -e "\\n\\n${WHITE_R}#${RESET} What would you like to do with those scripts?\\n"
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Remove them"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Let me choose which to remove"
    echo -e " [   ${WHITE_R}3${RESET}   ]  |  Do nothing\\n\\n"
    read -rp $'Your choice | \033[39m' choice
    case "$choice" in
        1*|"")
          echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Removing the post/pre hook scripts... \\n\\n${WHITE_R}----${RESET}\\n"
          while read -r script; do
            if [[ -f "/etc/letsencrypt/renewal-hooks/post/${script}" ]]; then
              echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/post/${script}\"..."
              if rm --force "/etc/letsencrypt/renewal-hooks/post/${script}"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/post/${script}\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/post/${script}\"... \\n"; fi
            elif [[ -f "/etc/letsencrypt/renewal-hooks/pre/${script}" ]]; then
              echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/pre/${script}\"..."
              if rm --force "/etc/letsencrypt/renewal-hooks/pre/${script}"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/pre/${script}\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/pre/${script}\"... \\n"; fi
            fi
          done < /tmp/EUS/hook/list;;
        2*)
          header
          echo -e "${WHITE_R}#${RESET} Please enter the name of the script ( FQDN ) that you want to remove below.\\n${WHITE_R}#${RESET} That is without \"EUS_\" and \".sh\"\\n\\n${WHITE_R}#${RESET} Examples:"
          while read -r script_name; do script_name=$(echo "${script_name}" | sed -e 's/EUS_//g' -e 's/.sh//g'); echo -e "${WHITE_R}-${RESET} \"${script_name}\""; done < /tmp/EUS/hook/list
          echo ""
          read -rp $'Script Name | \033[39m' script_name_remove
          echo -e "\\n${WHITE_R}----${RESET}\\n"
		  read -rp $'\033[39m#\033[0m You want to remove script: '"EUS_${script_name_remove}.sh"', is that correct? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"") 
                if grep -iq "EUS_${script_name_remove}.sh" /tmp/EUS/hook/list; then
                  echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Removing post/pre hook script \"EUS_${script_name_remove}.sh\"... \\n\\n${WHITE_R}----${RESET}\\n"
                  while read -r script; do
                    if [[ -f "/etc/letsencrypt/renewal-hooks/post/EUS_${script_name_remove}.sh" ]]; then
                      echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/post/EUS_${script_name_remove}.sh\"..."
                      if rm --force "/etc/letsencrypt/renewal-hooks/post/EUS_${script_name_remove}.sh"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/post/EUS_${script_name_remove}.sh\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/post/EUS_${script_name_remove}.sh\"... \\n"; fi
                    elif [[ -f "/etc/letsencrypt/renewal-hooks/pre/EUS_${script_name_remove}.sh" ]]; then
                      echo -e "${WHITE_R}#${RESET} Removing \"/etc/letsencrypt/renewal-hooks/pre/EUS_${script_name_remove}.sh\"..."
                      if rm --force "/etc/letsencrypt/renewal-hooks/pre/EUS_${script_name_remove}.sh"; then echo -e "${GREEN}#${RESET} Successfully removed \"/etc/letsencrypt/renewal-hooks/pre/EUS_${script_name_remove}.sh\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"/etc/letsencrypt/renewal-hooks/pre/EUS_${script_name_remove}.sh\"... \\n"; fi
                    else
                      echo -e "${YELLOW}#${RESET} Script \"EUS_${script_name_remove}.sh\" does not exist..."
                    fi
                  done < /tmp/EUS/hook/list
                else
                  echo -e "${YELLOW}#${RESET} \"EUS_${script_name_remove}.sh\" is not in the list of post/pre looks that can be removed..."
                fi;;
             [Nn]*) ;;
          esac
          if [[ "$(find /etc/letsencrypt/renewal-hooks/post/ /etc/letsencrypt/renewal-hooks/pre/ -printf "%f\\n" | sed -e '/post/d' -e '/pre/d' -e "/EUS_${server_fqdn}.sh/d" | awk '!NF || !seen[$0]++' | grep -ioc "EUS.*.sh")" -ge "1" ]]; then
            read -rp $'\033[39m#\033[0m Do you want to remove more post/pre hook scripts? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"") remove_old_post_pre_hook;;
               [Nn]*) ;;
            esac
          fi;;
        3*) return;;
    esac
  fi
}

lets_encrypt() {
  if [[ "${script_option_skip}" != 'true' ]]; then header; echo -e "${WHITE_R}#${RESET} Heck yeah! I want to secure my setup with a SSL certificate!"; sleep 3; fi
  if [[ "${script_option_fqdn}" == 'true' ]]; then fqdn_option; fi
  # shellcheck disable=SC2012
  ls -t "${eus_dir}/logs/lets_encrypt_*.log" 2> /dev/null | awk 'NR>2' | xargs rm -f &> /dev/null
  if [[ "${os_codename}" =~ (jessie) || "${downloaded_certbot}" == 'true' ]]; then certbot_auto_install_run; fi
  if [[ "${script_option_skip}" != 'true' ]]; then timezone; fi
  if [[ "${script_option_skip}" != 'true' ]]; then delete_certs_question; fi
  if [[ "${script_option_fqdn}" != 'true' ]]; then domain_name; fi
  if [[ "${script_option_skip}" != 'true' ]]; then change_application_hostname; fi
  if [[ "${script_option_email}" != 'true' ]]; then if [[ "${script_option_skip}" != 'true' ]]; then le_email; else email="--register-unsafely-without-email"; fi; fi
  if [[ "${udm_device}" == 'true' && "${uid_agent}" != 'true' ]]; then
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -ql root 127.0.0.1 "ls -la /mnt/data/udapi-config/raddb/certs/" | grep -iq "server.pem\\|server-key.pem" && [[ "${script_option_skip}" != 'true' ]]; then
      header
      echo -e "${YELLOW}#${RESET} ATTENTION, please backup your system before continuing!!"
      # shellcheck disable=2086
      read -rp $'\033[39m#\033[0m Do you want to apply the certificates to RADIUS on your "'${unifi_core_device}'"? (y/N) ' yes_no
      case "$yes_no" in
          [Yy]*) mkdir -p "${eus_dir}/radius/" &> /dev/null && touch "${eus_dir}/radius/true";;
          [Nn]*|"") if [[ -f "${eus_dir}/radius/true" ]]; then rm --force "${eus_dir}/radius/true"; fi;;
      esac
    fi
  fi
  le_post_hook
  le_pre_hook
  sleep 3
  header
  echo -e "${WHITE_R}#${RESET} Checking for existing certificates and preparing for the challenge..."
  echo "-d ${server_fqdn}" &>> "${eus_dir}/le_domain_list"
  if [[ "${multiple_fqdn_resolved}" == 'true' ]]; then while read -r domain; do echo "--domain ${domain}" >> "${eus_dir}/le_domain_list"; done < "${eus_dir}/other_domain_records"; fi
  server_fqdn_le=$(tr '\r\n' ' ' < "${eus_dir}/le_domain_list")
  rm --force "${eus_dir}/certificates" 2> /dev/null
  if [[ "${certbot_auto}" == 'true' ]]; then
    # shellcheck disable=2086
    ${certbot} certificates --domain "${server_fqdn}" "${certbot_auto_flags}" &>> "${eus_dir}/certificates"
  else
    # shellcheck disable=2086
    ${certbot} certificates --domain "${server_fqdn}" &>> "${eus_dir}/certificates"
  fi
  if grep -iq "${server_fqdn}" "${eus_dir}/certificates"; then
    valid_days=$(grep -i "(valid:" "${eus_dir}/certificates" | awk '{print $6}' | sed 's/)//' | grep -o -E '[0-9]+' | tail -n1)
    if [[ -z "${valid_days}" ]]; then
      valid_days=$(grep -i "(valid:" "${eus_dir}/certificates" | awk '{print $6}' | sed 's/)//' | tail -n1)
    fi
    if grep -iq "renewal configuration file .* produced an unexpected error" "${eus_dir}/certificates"; then
      echo -e "\\n${RED}#${RESET} Unexpected error (from Let's Encrypt) regarding configuration files..."
      abort
    fi
    le_fqdn=$(grep "${valid_days}" -A2 "${eus_dir}/certificates" | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | tail -n1)
    fullchain_pem=$(grep -i "Certificate Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $3}' | sed 's/.pem//g' | tail -n1)
    priv_key_pem=$(grep -i "Private Key Path" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $4}' | sed 's/.pem//g' | tail -n1)
    expire_date=$(grep -i "Expiry Date:" "${eus_dir}/certificates" | grep -i "${le_fqdn}" | awk '{print $3}' | tail -n1)
    if [[ "${run_force_renew}" == 'true' ]] || [[ "${valid_days}" == 'EXPIRED' ]] || [[ "${valid_days}" -lt '30' ]]; then
      echo -e "\\n${GREEN}----${RESET}\\n"
      if [[ "${valid_days}" == 'EXPIRED' ]]; then echo -e "${WHITE_R}#${RESET} Your certificates for '${server_fqdn}' are already EXPIRED!"; else echo -e "${WHITE_R}#${RESET} Your certificates for '${server_fqdn}' expire in ${valid_days} days..."; fi
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to force renew the certficiates? (Y/n) ' yes_no; elif [[ "${script_option_renew}" != 'true' ]]; then echo -e "${WHITE_R}#${RESET} No... I don't want to force renew my certificates"; else echo -e "${WHITE_R}#${RESET} Yes, I want to force renew the certificates!"; fi
      case "$yes_no" in
          [Yy]*|"")
              renewal_option="--force-renewal"
              import_ssl_certificates;;
          [Nn]*)
              read -rp $'\033[39m#\033[0m Would you like to import the existing certificates? (Y/n) ' yes_no
              import_existing_ssl_certificates;;
      esac
    elif [[ "${valid_days}" -ge '30' ]]; then
      echo -e "\\n${GREEN}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} You already seem to have certificates for '${server_fqdn}', those expire in ${valid_days} days..."
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Would you like to import the existing certificates? (Y/n) ' yes_no; fi
      case "$yes_no" in
           [Yy]*|"")
               import_existing_ssl_certificates;;
           [Nn]*) ;;
      esac
    fi
  else
    import_ssl_certificates
  fi
  if [[ "${certbot_auto}" == 'true' ]]; then
    tee /etc/cron.d/eus_certbot &>/dev/null << EOF
# /etc/cron.d/certbot: crontab entries for the certbot package
#
# Upstream recommends attempting renewal twice a day
#
# Eventually, this will be an opportunity to validate certificates
# haven't been revoked, etc.  Renewal will only occur if expiration
# is within 30 days.
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 */12 * * * root ${eus_dir}/certbot-auto -q renew
EOF
  fi
  if [[ "${run_uck_scripts}" == 'true' ]]; then
    if [[ "${is_cloudkey}" == 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n"
      echo -e "${WHITE_R}#${RESET} Creating required scripts and adding them as cronjobs!"
      mkdir -p /srv/EUS/cronjob
      if dpkg --print-architecture | grep -iq 'armhf'; then
        touch /usr/lib/eus &>/dev/null
        cat /usr/lib/version &> /srv/EUS/cloudkey/version
        tee /etc/cron.d/eus_script_uc_ck &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root sleep 200 && /bin/bash /srv/EUS/cronjob/eus_uc_ck.sh
EOF
        # shellcheck disable=SC1117
        tee /srv/EUS/cronjob/eus_uc_ck.sh &>/dev/null << EOF
#!/bin/bash
if [[ -f /srv/EUS/cloudkey/version ]]; then
  current_version=\$(cat /usr/lib/version)
  old_version=\$(cat /srv/EUS/cloudkey/version)
  if [[ \${old_version} != \${current_version} ]] || ! [[ -f /usr/lib/eus ]]; then
    touch /usr/lib/eus
    echo "\$(date +%F-%R) | Cloudkey firmware version changed from \${old_version} to \${current_version}" &>> /srv/EUS/logs/uc-ck_firmware_versions.log
  fi
  server_fqdn="${server_fqdn}"
  if ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log &>/dev/null && [[ -d "/etc/letsencrypt/live/${server_fqdn}" ]]; then
    last_le_log=\$(ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log | tail -n1)
    le_var_log=\$(cat \${last_le_log} | grep -i "/etc/letsencrypt/live/${server_fqdn}" | awk '{print \$1}' | head -n1 | sed 's/\/etc\/letsencrypt\/live\///g' | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
    le_var_dir=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g")
    if [[ "\${le_var_log}" != "\${le_var_dir}" ]]; then
      le_var="\${le_var_dir}"
    else
      le_var="\${le_var_log}"
    fi
  else
    le_var=\$(ls -lc /etc/letsencrypt/live/ | grep -io "${server_fqdn}.*" | tail -n1 | sed "s/${server_fqdn}//g")
  fi
  if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem && -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
    uc_ck_key=\$(cat /etc/ssl/private/cloudkey.key)
    priv_key=\$(cat /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem)
    if [[ \${uc_ck_key} != \${priv_key} ]]; then
      echo "\$(date +%F-%R) | Certificates were different.. applying the Let's Encrypt ones." &>> /srv/EUS/logs/uc_ck_certificates.log
      cp /etc/ssl/private/cloudkey.crt ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)
      cp /etc/ssl/private/cloudkey.key ${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/ssl/private/cloudkey.key
      fi
      systemctl restart nginx
      if [[ \$(dpkg-query -W -f='\${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
        echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
        mkdir -p ${eus_dir}/network/keystore_backups && cp /usr/lib/unifi/data/keystore ${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)
        openssl pkcs12 -export -inkey /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem -in /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem -out /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12 -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12 -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        systemctl restart unifi
      fi
    fi
  fi
  if [[ -f /srv/EUS/logs/uc_ck_certificates.log ]]; then
    uc_ck_certificates_log_size=\$(du -sc /srv/EUS/logs/uc_ck_certificates.log | grep total\$ | awk '{print \$1}')
    if [[ \${uc_ck_certificates_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc_ck_certificates.log &> /srv/EUS/logs/uc_ck_certificates_tmp.log
      cp /srv/EUS/logs/uc_ck_certificates_tmp.log /srv/EUS/logs/uc_ck_certificates.log && rm --force /srv/EUS/logs/uc_ck_certificates_tmp.log
    fi
  fi
  if [[ -f /srv/EUS/logs/uc-ck_firmware_versions.log ]]; then
    firmware_versions_log_size=\$(du -sc /srv/EUS/logs/uc-ck_firmware_versions.log | grep total\$ | awk '{print \$1}')
    if [[ \${firmware_versions_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc-ck_firmware_versions.log &> /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
      cp /srv/EUS/logs/uc-ck_firmware_versions_tmp.log /srv/EUS/logs/uc-ck_firmware_versions.log && rm --force /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
    fi
  fi
  if [[ -f ${eus_dir}/cloudkey/uc_ck_unifi_import.log ]]; then
    unifi_import_log_size=\$(du -sc ${eus_dir}/logs/uc_ck_unifi_import.log | grep total\$ | awk '{print \$1}')
    if [[ \${unifi_import_log_size} -gt '50' ]]; then
      tail -n100 ${eus_dir}/logs/uc_ck_unifi_import.log &> ${eus_dir}/cloudkey/unifi_import_tmp.log
      cp ${eus_dir}/cloudkey/unifi_import_tmp.log ${eus_dir}/logs/uc_ck_unifi_import.log && rm --force ${eus_dir}/cloudkey/unifi_import_tmp.log
    fi
  fi
fi
EOF
        chmod +x /srv/EUS/cronjob/eus_uc_ck.sh
      fi
      tee /etc/cron.d/eus_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root sleep 300 && /bin/bash /srv/EUS/cronjob/install_certbot.sh
EOF
      # shellcheck disable=SC1117
      tee /srv/EUS/cronjob/install_certbot.sh &>/dev/null << EOF
#!/bin/bash
while [ -n "\$1" ]; do
  case "\$1" in
  --force-dpkg) script_option_force_dpkg=true;;
  esac
  shift
done
echo -e "\\n------- \$(date +%F-%R) -------\\n" &>>/srv/EUS/logs/cronjob_install.log
mkdir -p /srv/EUS/tmp/
while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
  unset dpkg_locked
  if [[ "\${script_option_force_dpkg}" == "true" ]]; then
    current_time=\$(date "+%Y-%m-%d %H:%M")
    echo "Force killing the lock... | \${current_time}" &>> /srv/EUS/logs/cronjob_install.log
    rm --force /srv/EUS/tmp/dpkg_lock &> /dev/null
    pgrep "apt" >> /srv/EUS/tmp/apt
    while read -r glennr_apt; do
      kill -9 "\$glennr_apt" &> /dev/null
    done < /srv/EUS/tmp/apt
    rm --force /srv/EUS/tmp/apt &> /dev/null
    rm --force /var/lib/apt/lists/lock &> /dev/null
    rm --force /var/cache/apt/archives/lock &> /dev/null
    rm --force /var/lib/dpkg/lock* &> /dev/null
    dpkg --configure -a &> /dev/null
    DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken &> /dev/null
  else
    if [[ \$(grep -c "eus_lock_active" /srv/EUS/tmp/dpkg_lock) -ge 60 ]]; then
      echo "dpkg lock still active after 600 seconds..." &>> /srv/EUS/logs/cronjob_install.log
      date_minute=\$(date +%M)
      if ! grep -iq "/srv/EUS/cronjob/install_certbot.sh" /etc/crontab; then
        echo "\${date_minute} * * * * root /bin/bash /srv/EUS/cronjob/install_certbot.sh --force-dpkg" >> /etc/crontab
        if grep -iq "root /bin/bash /srv/EUS/cronjob/install_certbot.sh --force-dpkg" /etc/crontab; then
          echo "Script has been scheduled to run on a later time..." &>> /srv/EUS/logs/cronjob_install.log
          exit 0
        fi
      fi
    fi
  fi
  echo "eus_lock_active" >> /srv/EUS/tmp/dpkg_lock
  sleep 10
done;
rm --force /srv/EUS/tmp/dpkg_lock_test &> /dev/null
rmdir /srv/EUS/tmp/ &> /dev/null
if ! dpkg -l certbot 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
  if [[ -f /srv/EUS/certbot_install_failed ]]; then
    rm --force /srv/EUS/certbot_install_failed
  fi
  if [[ -f /srv/EUS/logs/cronjob_install.log ]]; then
    cronjob_install_log_size=\$(du -sc /srv/EUS/logs/cronjob_install.log | grep total\$ | awk '{print \$1}')
    if [[ \${cronjob_install_log_size} -gt '50' ]]; then
      tail -n100 /srv/EUS/logs/cronjob_install.log &> /srv/EUS/logs/cronjob_install_tmp.log
      cp /srv/EUS/logs/cronjob_install_tmp.log /srv/EUS/logs/cronjob_install.log && rm --force /srv/EUS/logs/cronjob_install_tmp.log
    fi
  fi
  if [[ -z "\$(command -v lsb_release)" ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=\$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=\$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print \$4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        if [[ -z "\${os_codename}" ]]; then
          os_codename=\$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print \$3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        fi
      fi
    fi
  else
    os_codename=\$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
  fi
  if [[ \$os_codename == "jessie" ]]; then
    if [[ ! -f "${eus_dir}/certbot-auto" && -s "${eus_dir}/certbot-auto" ]]; then
      curl -s https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto -o "${eus_dir}/certbot-auto" &>>/srv/EUS/logs/cronjob_install.log
      chown root ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
      chmod 0755 ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
    else
      echo "certbot-auto is available!" &>>/srv/EUS/logs/cronjob_install.log
    fi
    if ! dpkg -l libssl-dev 2> /dev/null | awk '{print \$1}' | grep -iq "^ii\\|^hi"; then
      if ! apt-get install libssl-dev -y; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list
        apt-get update -o Acquire::Check-Valid-Until=false &>>/srv/EUS/logs/cronjob_install.log
        apt-get install -t jessie-backports libssl-dev -y &>>/srv/EUS/logs/cronjob_install.log
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list &>>/srv/EUS/logs/cronjob_install.log
      fi
    else
      echo "libssl-dev is installed!" &>>/srv/EUS/logs/cronjob_install.log
    fi
    if [[ -f "${eus_dir}/certbot-auto" || -s "${eus_dir}/certbot-auto" ]]; then
      if [[ \$(stat -c "%a" "${eus_dir}/certbot-auto") != "755" ]]; then
        chmod 0755 ${eus_dir}/certbot-auto
      fi
      if [[ \$(stat -c "%U" "${eus_dir}/certbot-auto") != "root" ]] ; then
        chown root ${eus_dir}/certbot-auto
      fi
    fi
    ${eus_dir}/certbot-auto --non-interactive --install-only --verbose &>>/srv/EUS/logs/cronjob_install.log
  fi
  if [[ \$os_codename == "stretch" ]]; then
    apt-get update &>>/srv/EUS/logs/cronjob_install.log
    apt-get install certbot -y &>>/srv/EUS/logs/cronjob_install.log
    if [[ \$? > 0 ]]; then
      if [[ \$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list
        apt-get update &>>/srv/EUS/logs/cronjob_install.log
        apt-get install certbot -y &>>/srv/EUS/logs/cronjob_install.log || touch /srv/EUS/certbot_install_failed
      fi
    fi
  fi
fi
if [[ "\${script_option_force_dpkg}" == "true" ]]; then sed -i "/install_certbot.sh/d" /etc/crontab &> /dev/null; fi
EOF
      chmod +x /srv/EUS/cronjob/install_certbot.sh
    fi
  fi
  echo ""
  echo ""
  if [[ "${script_timeout_http}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} A DNS challenge requires you to add a TXT record to your domain register. ( NO AUTO RENEWING )"
    echo -e "${WHITE_R}#${RESET} The DNS challenge is only recommend for users where the ISP blocks port 80. ( rare occasions )"
    echo ""
    read -rp $'\033[39m#\033[0m Would you like to use the DNS challenge? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"") 
         echo "--dns" &>> /tmp/EUS/script_options
         get_script_options
         # shellcheck disable=SC2068
         bash "${script_location}" ${script_options[@]}; exit 0;;
       [Nn]*) ;;
    esac
  else
    if [[ "${script_option_skip}" != 'true' ]]; then remove_old_post_pre_hook; fi
    author
  fi
  rm --force "${eus_dir}/le_domain_list" &> /dev/null
  rm --force "${eus_dir}/other_domain_records" &> /dev/null
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
}

paid_certificate_uc_ck() {
  echo -e "\\n${WHITE_R}----${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} Creating required scripts and adding them as cronjobs!"
  if ! [[ -d "/srv/EUS/cronjob" ]]; then mkdir -p /srv/EUS/cronjob; fi
  if ! [[ -f "/usr/lib/eus" ]]; then touch /usr/lib/eus &>/dev/null; fi
  cat /usr/lib/version &> /srv/EUS/cloudkey/version
  tee /etc/cron.d/eus_script_uc_ck &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root sleep 200 && /bin/bash /srv/EUS/cronjob/eus_uc_ck.sh
EOF
  # shellcheck disable=SC1117
  tee /srv/EUS/cronjob/eus_uc_ck.sh &>/dev/null << EOF
#!/bin/bash
if [[ -f /srv/EUS/cloudkey/version ]]; then
  current_version=\$(cat /usr/lib/version)
  old_version=\$(cat /srv/EUS/cloudkey/version)
  if [[ \${old_version} != \${current_version} ]] || ! [[ -f /usr/lib/eus ]]; then
    touch /usr/lib/eus
    echo "\$(date +%F-%R) | Cloudkey firmware version changed from \${old_version} to \${current_version}" &>> /srv/EUS/logs/uc-ck_firmware_versions.log
  fi
  if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" && -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
    uc_ck_key=\$(md5sum /etc/ssl/private/cloudkey.key | awk '{print $1}')
    priv_key=\$(md5sum "${eus_dir}/paid-certificates/eus_key_file.key" | awk '{print $1}')
    if [[ \${uc_ck_key} != \${priv_key} ]]; then
      echo "\$(date +%F-%R) | Certificates were different.. applying the paid ones." &>> /srv/EUS/logs/uc_ck_certificates.log
      cp /etc/ssl/private/cloudkey.crt ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)
      cp /etc/ssl/private/cloudkey.key ${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)
      if [[ -f "${eus_dir}/paid-certificates/eus_crt_file.crt" ]]; then
        cp "${eus_dir}/paid-certificates/eus_crt_file.crt" /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f "${eus_dir}/paid-certificates/eus_key_file.key" ]]; then
        cp "${eus_dir}/paid-certificates/eus_key_file.key" /etc/ssl/private/cloudkey.key
      fi
      systemctl restart nginx
      if [[ \$(dpkg-query -W -f='\${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
        echo -e "\\n------- \$(date +%F-%R) -------\\n" &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
        mkdir -p ${eus_dir}/network/keystore_backups && cp /usr/lib/unifi/data/keystore ${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)
        keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> "${eus_dir}/logs/uc_ck_unifi_import.log"
        keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore "${eus_dir}/paid-certificates/eus_unifi.p12" -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> "${eus_dir}/logs/uc_ck_unifi_import.log"
        systemctl restart unifi
      fi
    fi
  fi
  if [[ -f /srv/EUS/logs/uc_ck_certificates.log ]]; then
    uc_ck_certificates_log_size=\$(du -sc /srv/EUS/logs/uc_ck_certificates.log | grep total\$ | awk '{print \$1}')
    if [[ \${uc_ck_certificates_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc_ck_certificates.log &> /srv/EUS/logs/uc_ck_certificates_tmp.log
      cp /srv/EUS/logs/uc_ck_certificates_tmp.log /srv/EUS/logs/uc_ck_certificates.log && rm --force /srv/EUS/logs/uc_ck_certificates_tmp.log
    fi
  fi
  if [[ -f /srv/EUS/logs/uc-ck_firmware_versions.log ]]; then
    firmware_versions_log_size=\$(du -sc /srv/EUS/logs/uc-ck_firmware_versions.log | grep total\$ | awk '{print \$1}')
    if [[ \${firmware_versions_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc-ck_firmware_versions.log &> /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
      cp /srv/EUS/logs/uc-ck_firmware_versions_tmp.log /srv/EUS/logs/uc-ck_firmware_versions.log && rm --force /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
    fi
  fi
  if [[ -f ${eus_dir}/cloudkey/uc_ck_unifi_import.log ]]; then
    unifi_import_log_size=\$(du -sc ${eus_dir}/logs/uc_ck_unifi_import.log | grep total\$ | awk '{print \$1}')
    if [[ \${unifi_import_log_size} -gt '50' ]]; then
      tail -n100 ${eus_dir}/logs/uc_ck_unifi_import.log &> ${eus_dir}/cloudkey/unifi_import_tmp.log
      cp ${eus_dir}/cloudkey/unifi_import_tmp.log ${eus_dir}/logs/uc_ck_unifi_import.log && rm --force ${eus_dir}/cloudkey/unifi_import_tmp.log
    fi
  fi
fi
EOF
  chmod +x /srv/EUS/cronjob/eus_uc_ck.sh
  if [[ -f "/srv/EUS/cronjob/eus_uc_ck.sh" && -f "/etc/cron.d/eus_script_uc_ck" ]]; then
    echo -e "${GREEN}#${RESET} Successfully created the required scripts and were added as cronjob!"
    sleep 3
  else
    echo -e "${RED}#${RESET} Failed to create the required scripts and were added as cronjob!"
    abort
  fi
}

backup_paid_certificate() {
  if [[ "$(find "${eus_dir}/paid-certificates/" -maxdepth 1 -not -type d | wc -l)" -ge '1' ]]; then header; fi
  while read -r cert_file; do
    if ! [[ -d "${eus_dir}/paid-certificates/backup_${time_date}/" ]]; then mkdir -p "${eus_dir}/paid-certificates/backup_${time_date}/"; fi
    echo -e "${WHITE_R}#${RESET} Backing up \"${cert_file}\"..."
    if mv "${cert_file}" "${eus_dir}/paid-certificates/backup_${time_date}/${cert_file##*/}"; then echo -e "${GREEN}#${RESET} Successfully backed up \"${cert_file}\"! \\n"; else echo -e "${RED}#${RESET} Failed to back up \"${cert_file}\"..."; abort; fi
  done < <(find "${eus_dir}/paid-certificates/" -maxdepth 1 -type f)
  amount_backup_folders=$(find "${eus_dir}/paid-certificates/" -maxdepth 1 -type d | grep -ci "backup_.*")
  if [[ "${amount_backup_folders}" -gt 10 ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You seem to have more then 10 paid-certificate backups..."
    echo -e "${WHITE_R}#${RESET} In those backups you can find the certificates that were used on your setup ( imported )."
    if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to remove older backup folders and keep the last 3? (Y/n) ' yes_no; fi
    case "$yes_no" in
        [Yy]*|"")
           # shellcheck disable=SC2012
           find "${eus_dir}/paid-certificates/" -type d -exec stat -c '%X %n' {} \; | sort -nr | grep -i "${eus_dir}/paid-certificates/backup_.*" | awk 'NR>3 {print $2}' &> "${eus_dir}/paid-certificates/list.tmp"
           while read -r folder; do
             echo -e "${WHITE_R}#${RESET} Removing \"${folder}\"..."
             if rm -r "${folder}" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully removed \"${folder}\"! \\n"; else echo -e "${RED}#${RESET} Failed to remove \"${folder}\"..."; abort; fi
           done < "${eus_dir}/paid-certificates/list.tmp"
           rm --force "${eus_dir}/paid-certificates/list.tmp" &> /dev/null;;
        [Nn]*) ;;
    esac
  fi
}

paid_certificate() {
  if ! [[ -d "${eus_dir}/paid-certificates" ]]; then mkdir -p "${eus_dir}/paid-certificates" &> /dev/null; fi
  if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]] && dpkg -l unifi-talk 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then create_eus_certificates_file=true; fi
  if dpkg -l uas-led 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then if dpkg -l | awk '{print $2}' | grep -iq "^docker.io\\|^docker-ce"; then if docker ps -a | grep -iq 'ubnt/eot'; then create_eus_certificates_file=true; fi; fi; fi
  if [[ "${is_cloudkey}" == 'true' ]] && [[ "${unifi_core_system}" != 'true' ]]; then create_eus_crt_file=true; create_eus_key_file=true; fi
  if [[ "${unifi_core_system}" == 'true' ]]; then create_eus_crt_file=true; create_eus_key_file=true; fi
  if dpkg -l | grep -iq "\\bUAS\\b\\|UniFi Application Server" && [[ "${unifi_core_system}" != 'true' ]]; then create_eus_crt_file=true; create_eus_key_file=true; fi
  if dpkg -l unifi-video 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi" && [[ "${unifi_core_system}" != 'true' ]]; then create_ufv_crts=true; fi
  backup_paid_certificate
  header
  paid_cert=true
  if [[ -f "${chain_crt}" ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    if openssl pkcs12 -export -inkey "${priv_key}" -in "${signed_crt}" -in "${chain_crt}" -out "${eus_dir}/paid-certificates/eus_unifi.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."; abort; fi
    if [[ "${create_ufv_crts}" == 'true' ]]; then
      echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
      echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."
      if openssl x509 -outform der -in "${signed_crt}" -in "${chain_crt}" -out "${eus_dir}/paid-certificates/ufv-server.cert.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.cert.der\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."; abort; fi
    fi
  elif [[ -f "${intermediate_crt}" ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    if openssl pkcs12 -export -inkey "${priv_key}" -in "${signed_crt}" -certfile "${intermediate_crt}" -out "${eus_dir}/paid-certificates/eus_unifi.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."; abort; fi
    if [[ "${create_ufv_crts}" == 'true' ]]; then
      echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
      echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."
      if openssl x509 -outform der -in "${signed_crt}" -out "${eus_dir}/paid-certificates/ufv-server.cert.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.cert.der\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."; abort; fi
    fi
  else
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    if openssl pkcs12 -export -inkey "${priv_key}" -in "${signed_crt}" -out "${eus_dir}/paid-certificates/eus_unifi.p12" -name unifi -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."; abort; fi
    if [[ "${create_ufv_crts}" == 'true' ]]; then
      echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
      echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."
      if openssl x509 -outform der -in "${signed_crt}" -out "${eus_dir}/paid-certificates/ufv-server.cert.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.cert.der\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/ufv-server.cert.der\"..."; abort; fi
    fi
  fi
  if [[ "${create_ufv_crts}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/ufv-server.key.der\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/ufv-server.key.der\"..."
    if openssl pkcs8 -topk8 -nocrypt -in "${priv_key}" -outform DER -out "${eus_dir}/paid-certificates/ufv-server.key.der" &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/ufv-server.key.der\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/ufv-server.key.der\"..."; abort; fi
  fi
  if [[ "${create_eus_key_file}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -nodes -nocerts -out "${eus_dir}/paid-certificates/eus_key_file.key" -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/eus_key_file.key\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."; abort; fi
  fi
  if [[ "${create_eus_crt_file}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -clcerts -nokeys -out "${eus_dir}/paid-certificates/eus_crt_file.crt" -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/eus_crt_file.crt\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."; abort; fi
  fi
  if [[ "${create_eus_certificates_file}" == 'true' ]]; then
    echo -e "\\n------- Creating \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\" ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/paid_certificate.log"
    echo -e "${WHITE_R}#${RESET} Creating \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."
    if openssl pkcs12 -in "${eus_dir}/paid-certificates/eus_unifi.p12" -nodes -out "${eus_dir}/paid-certificates/eus_certificates_file.pem" -password pass:aircontrolenterprise ${openssl_legacy_flag} &>> "${eus_dir}/logs/paid_certificate.log"; then echo -e "${GREEN}#${RESET} Successfully created \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"! \\n"; else echo -e "${RED}#${RESET} Failed to create \"${eus_dir}/paid-certificates/eus_certificates_file.pem\" from \"${eus_dir}/paid-certificates/eus_unifi.p12\"..."; abort; fi
  fi
  import_existing_ssl_certificates
  if [[ "${is_cloudkey}" == 'true' ]] && dpkg --print-architecture | grep -iq 'armhf'; then paid_certificate_uc_ck; fi
  author
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                       What Should we do?                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [[ "${script_option_skip}" != 'true' ]]; then
  header
  echo -e "  What do you want to do?\\n\\n"
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Apply Let's Encrypt Certificates (recommended)"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Apply Paid Certificates (advanced)"
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Restore previous certificates"
  echo -e " [   ${WHITE_R}4${RESET}   ]  |  Restore certificates to original state"
  echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel\\n\\n"
  read -rp $'Your choice | \033[39m' unifi_easy_encrypt
  case "$unifi_easy_encrypt" in
      1) certbot_install_function; lets_encrypt;;
      2)
        if [[ ! -f "${priv_key}" ]] || [[ ! -f "${signed_crt}" ]]; then cert_missing=true; fi
        if [[ ! -f "${chain_crt}" ]] && [[ -f "${intermediate_crt}" ]]; then cert_missing=false; fi
        if [[ ! -f "${intermediate_crt}" ]] && [[ -f "${chain_crt}" ]]; then cert_missing=false; fi
        if [[ "${cert_missing}" == 'true' ]]; then
          header_red
          echo -e "${RED}#${RESET} Missing one or more required certificate files..."
          echo -e "${RED}#${RESET} Private Key: \"${priv_key}\""
          echo -e "${RED}#${RESET} Signed Certificate: \"${signed_crt}\""
          if [[ -n "${chain_crt}" ]]; then echo -e "${RED}#${RESET} Chain Certificate file: \"${chain_crt}\""; fi
          if [[ -n "${intermediate_crt}" ]]; then echo -e "${RED}#${RESET} Intermediate Certificate file: \"${intermediate_crt}\""; fi
          echo -e "\\n"
          help_script
        else
          paid_certificate
        fi;;
      3)
        header
        echo -e "${WHITE_R}#${RESET} Restoring certificates may result in browser errors due to invalid certificates."
        read -rp $'\033[39m#\033[0m Do you want to proceed with restoring previous certificates? (y/N) ' yes_no
        restore_previous_certs;;
      4)
        header
        read -rp $'\033[39m#\033[0m Do you want to proceed with restoring to original state? (y/N) ' yes_no
        restore_original_state=true
        restore_previous_certs;;
      5*|"") cancel_script;;
  esac
else
  if [[ "${own_certificate}" == 'true' ]]; then
    if [[ ! -f "${priv_key}" ]] || [[ ! -f "${signed_crt}" ]]; then cert_missing=true; fi
    if [[ ! -f "${chain_crt}" ]] && [[ -f "${intermediate_crt}" ]]; then cert_missing=false; fi
    if [[ ! -f "${intermediate_crt}" ]] && [[ -f "${chain_crt}" ]]; then cert_missing=false; fi
    if [[ "${cert_missing}" == 'true' ]]; then
      header_red
      echo -e "${RED}#${RESET} Missing one or more required certificate files..."
      echo -e "${RED}#${RESET} Private Key: \"${priv_key}\""
      echo -e "${RED}#${RESET} Signed Certificate: \"${signed_crt}\""
      if [[ -n "${chain_crt}" ]]; then echo -e "${RED}#${RESET} Chain Certificate file: \"${chain_crt}\""; fi
      if [[ -n "${intermediate_crt}" ]]; then echo -e "${RED}#${RESET} Intermediate Certificate file: \"${intermediate_crt}\""; fi
      abort
    else
      paid_certificate
    fi
  else
    certbot_install_function; lets_encrypt
  fi
fi
