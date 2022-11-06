#!/bin/bash

# UniFi Network Application Easy Installation Script.
# Version  | 1.2.2
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.

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
  clear && clear
  echo -e "${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

# Variables
script_name=$(basename "${BASH_SOURCE[0]}")

script_logo() {
  cat << "EOF"

  _______________ ___  _________  .___                 __         .__  .__   
  \_   _____/    |   \/   _____/  |   | ____   _______/  |______  |  | |  |  
   |    __)_|    |   /\_____  \   |   |/    \ /  ___/\   __\__  \ |  | |  |  
   |        \    |  / /        \  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
  /_______  /______/ /_______  /  |___|___|  /____  > |__| (____  /____/____/
          \/                 \/            \/     \/            \/           

EOF
}

help_script() {
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  echo -e "    Easy UniFi Network Application Install script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_name} [options]
  
  Script options:
    --skip                                  Skip any kind of manual input.
    --skip-install-haveged                  Skip installation of haveged.
    --skip-swap                             Skip swap file check/creation.
    --add-repository                        Add UniFi Repository if --skip is used.
    --custom-url [argument]                 Manually provide a UniFi Network Application download URL.
                                            example:
                                            --custom-url https://dl.ui.com/unifi/5.12.72/unifi_sysvinit_all.deb
    --help                                  Shows this information :)\\n\\n
  Script options for UniFi Easy Encrypt:
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
                                            with the use of --skip.\\n\\n"
  exit 0
}

mkdir -p /tmp/EUS/ &> /dev/null
rm --force /tmp/EUS/script_options &> /dev/null
script_option_list=(-skip --skip --skip-install-haveged --skip-swap --add-repository --local --local-controller --local-install --custom-url --help --v6 --ipv6 --email --mail --fqdn --domain-name --server-ip --server-address --retry --external-dns --force-renew --renew --dns --dns-challenge)

while [ -n "$1" ]; do
  case "$1" in
  -skip | --skip)
       echo "--skip" &>> /tmp/EUS/script_options;;
  --skip-install-haveged)
       echo "--skip-install-haveged" &>> /tmp/EUS/script_options;;
  --skip-swap)
       echo "--skip-swap" &>> /tmp/EUS/script_options;;
  --add-repository)
       echo "--add-repository" &>> /tmp/EUS/script_options;;
  --local | --local-controller | --local-install)
       echo "--local-install" &>> /tmp/EUS/script_options;;
  --custom-url)
       if echo "${2}" | grep -iq ".*\.deb$"; then custom_url_down_provided=true; custom_download_url="${2}"; fi
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --help)
       script_option_help=true
       help_script;;
  --v6 | --ipv6)
       echo "--v6" &>> /tmp/EUS/script_options;;
  --email | --mail)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--email ${2}" &>> /tmp/EUS/script_options
       shift;;
  --fqdn | --domain-name)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--fqdn ${2}" &>> /tmp/EUS/script_options
       fqdn_specified=true
       shift;;
  --server-ip | --server-address)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--server-ip ${2}" &>> /tmp/EUS/script_options
       shift;;
  --retry)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--retry ${2}" &>> /tmp/EUS/script_options
       shift;;
  --external-dns)
       echo -e "--external-dns" &>> /tmp/EUS/script_options;;
  --force-renew | --renew)
       echo -e "--force-renew" &>> /tmp/EUS/script_options;;
  --dns | --dns-challenge)
       echo -e "--dns-challenge" &>> /tmp/EUS/script_options;;
  --priv-key | --private-key)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--private-key ${2}" &>> /tmp/EUS/script_options
       shift;;
  --signed-crt | --signed-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--signed-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --chain-crt | --chain-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--chain-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --intermediate-crt | --intermediate-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--intermediate-certificate ${2}" &>> /tmp/EUS/script_options
       shift;;
  --own-certificate)
       echo "--own-certificate" &>> /tmp/EUS/script_options;;
  esac
  shift
done

if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi

rm --force "$0" 2> /dev/null
rm --force unifi-latest.sh* 2> /dev/null
rm --force unifi-7.2.95.sh 2> /dev/null
# shellcheck disable=SC2086
wget -q https://get.glennr.nl/unifi/install/unifi-7.2.95.sh && bash unifi-7.2.95.sh ${script_options[@]}; exit 0
