#! /bin/sh

# Opening Firewall ports and saving configuration
iptables -I INPUT 2 -p udp --dport 1900 -j ACCEPT
iptables -I INPUT 2 -p udp --dport 10001 -j ACCEPT
iptables -I INPUT 2 -p udp --destination-port "5656:5699" -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 27117 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 6789 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 8843 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 8880 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 8443 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 8080 -j ACCEPT
iptables -I INPUT 2 -p udp --dport 3478 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 80 -j ACCEPT
iptables-save >  /etc/iptables/rules.v4


# Install jq for parsing JSON for metadata
apt-get update
apt-get -qq install -y jq


# Dynamic DNS Update
ddns_url=$(curl -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/metadata | jq -c ".ddns_url" | tr --delete '"')
if [ $ddns_url ]
then
	echo "Updating Dynamic DNS"
	curl "$ddns_url"
fi



# Create default parameter set for the Unifi script to run automatically
PARAMETERS=" --skip"

# If DNS name was provided, use it when setting up Unifi
dnsname=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c '.["dns_name"]' | tr --delete '"')
if [ $dnsname ]
then
	PARAMETERS="$PARAMETERS --fqdn $dnsname --retry 5"
fi

email=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c '.["email"]' | tr --delete '"')
if [ $email ]
then
	PARAMETERS="$PARAMETERS --email $email"
fi

#Running GlennR's install script which also installs prequisites
# https://community.ui.com/questions/UniFi-Installation-Scripts-or-UniFi-Easy-Update-Script-or-UniFi-Lets-Encrypt-or-UniFi-Easy-Encrypt-/ccbc7530-dd61-40a7-82ec-22b17f027776
apt-get update; apt-get install ca-certificates wget -y
# rm unifi-latest.sh &> /dev/null; wget https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh && bash unifi-latest.sh $PARAMETERS
rm unifi-latest.sh &> /dev/null
wget 'https://get.glennr.nl/unifi/install/install_latest/unifi-latest.sh'
echo "Preparing to run 'bash unifi-latest.sh $PARAMETERS'"
bash unifi-latest.sh $PARAMETERS


# bucket=$(curl -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/metadata | jq -c ".bucket" | tr --delete '"')
# if [ $bucket ]; then
# 	echo "Downloading existing backup file"
# 	cd /usr/lib/unifi/data/backup/autobackup/
# 	sudo wget ${bucket}autobackup.unf

# # TODO See if able to mount bucket directly in file system
# # https://blogs.oracle.com/cloud-infrastructure/post/mounting-an-object-storage-bucket-as-file-system-on-oracle-linux
# # https://www.luxoug.org/mounting-an-oracle-cloud-object-storage-bucket-as-a-file-system-on-linux/
# # https://www.youtube.com/watch?v=bPVuCf6ssec

# 	echo "Creating backup script file"
# 	echo '#!/bin/bash' | sudo tee ~/unifi-backup.sh
# 	# Copy the most recent auto backup file to be named autobackup.unf
# 	echo 'cd /usr/lib/unifi/data/backup/autobackup/' | sudo tee -a ~/unifi-backup.sh
# 	echo 'cp $(ls autobackup_*unf -t | head -n 1) autobackup.unf' | sudo tee -a ~/unifi-backup.sh
# 	echo 'bucket=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c ".bucket" | tr --delete '\''"'\'' )' | sudo tee -a ~/unifi-backup.sh
# 	echo curl -T /usr/lib/unifi/data/backup/autobackup/autobackup.unf \$bucket | sudo tee -a ~/unifi-backup.sh
# 	sudo chmod u+x ~/unifi-backup.sh

# 	echo "Scheduling weekly backups of database using cron on Sundays at 1:00 am"
# 	# https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
# 	crontab -l | { cat; echo "* 1 * * 0 ~/unifi-backup.sh"; } | crontab -
# fi

# Version 1.3.4
# This is a modified script for UniFi Controller on Ubuntu based Oracle Cloud Instances.
# Based on the excellent work of PetriR for GCP
# For instructions and how-to:  https://metis.fi/en/2018/02/unifi-on-gcp/
# For comments and code walkthrough:  https://metis.fi/en/2018/02/gcp-unifi-code/
#
# (c) 2018 Petri Riihikallio Metis Oy

# # Install jq for parsing JSON for metadata
# apt-get update
# apt-get -qq install -y jq



# ###########################################################
# #
# # Set up logging for unattended scripts and UniFi's MongoDB log
# # Variables $LOG and $MONGOLOG are used later on in the script.
# #
# LOG="/var/log/unifi/oci-unifi.log"
# if [ ! -f /etc/logrotate.d/oci-unifi.conf ]; then
# 	cat > /etc/logrotate.d/oci-unifi.conf <<_EOF
# $LOG {
# 	monthly
# 	rotate 4
# 	compress
# }
# _EOF
# 	echo "Script logrotate set up"
# fi

# MONGOLOG="/usr/lib/unifi/logs/mongod.log"
# if [ ! -f /etc/logrotate.d/unifi-mongod.conf ]; then
# 	cat > /etc/logrotate.d/unifi-mongod.conf <<_EOF
# $MONGOLOG {
# 	weekly
# 	rotate 10
# 	copytruncate
# 	delaycompress
# 	compress
# 	notifempty
# 	missingok
# }
# _EOF
# 	echo "MongoDB logrotate set up"
# fi

# ###########################################################
# #
# # Update DynDNS as early in the script as possible
# #
# ddns=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c '.["ddns-url"]')
# if [ ${ddns} ]; then
# 	curl -fs ${ddns}
# 	echo "Dynamic DNS accessed"
# fi


# # Lighttpd needs a config file and a reload
# httpd=$(dpkg-query -W --showformat='${Status}\n' lighttpd 2>/dev/null)
# if [ "x${httpd}" != "xinstall ok installed" ]; then
# 	if apt-get -qq install -y lighttpd >/dev/null; then
# 		cat > /etc/lighttpd/conf-enabled/10-unifi-redirect.conf <<_EOF
# \$HTTP["scheme"] == "http" {
#     \$HTTP["host"] =~ ".*" {
#         url.redirect = (".*" => "https://%0:8443")
#     }
# }
# _EOF
# 		systemctl reload-or-restart lighttpd
# 		echo "Lighttpd installed"
# 	fi
# fi


# # Fail2Ban needs three files and a reload
# f2b=$(dpkg-query -W --showformat='${Status}\n' fail2ban 2>/dev/null)
# if [ "x${f2b}" != "xinstall ok installed" ]; then
# 	if apt-get -qq install -y fail2ban >/dev/null; then
# 			echo "Fail2Ban installed"
# 	fi
# 	if [ ! -f /etc/fail2ban/filter.d/unifi-controller.conf ]; then
# 		cat > /etc/fail2ban/filter.d/unifi-controller.conf <<_EOF
# [Definition]
# failregex = ^.* Failed .* login for .* from <HOST>\s*$
# _EOF
# 		cat > /etc/fail2ban/jail.d/unifi-controller.conf <<_EOF
# [unifi-controller]
# filter   = unifi-controller
# port     = 8443
# logpath  = /var/log/unifi/server.log
# _EOF
# 	fi
# 	# The .local file will be installed in any case
# 	cat > /etc/fail2ban/jail.d/unifi-controller.local <<_EOF
# [unifi-controller]
# enabled  = true
# maxretry = 3
# bantime  = 3600
# findtime = 3600
# _EOF
# 	systemctl reload-or-restart fail2ban
# fi

# ###########################################################
# #
# # Set the time zone
# #
# tz=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c ".timezone" | tr --delete '"')
# if [ ${tz} ] && [ -f /usr/share/zoneinfo/${tz} ]; then
# 	apt-get -qq install -y dbus >/dev/null
# 	if ! systemctl start dbus; then
# 		echo "Trying to start dbus"
# 		sleep 15
# 		systemctl start dbus
# 	fi
# 	if timedatectl set-timezone $tz; then echo "Localtime set to ${tz}"; fi
# 	systemctl reload-or-restart rsyslog
# fi


# ###########################################################
# #
# # Set up automatic repair for broken MongoDB on boot
# #
# if [ ! -f /usr/local/sbin/unifidb-repair.sh ]; then
# 	cat > /usr/local/sbin/unifidb-repair.sh <<_EOF
# #! /bin/sh
# if ! pgrep mongod; then
# 	if [ -f /var/lib/unifi/db/mongod.lock ] \
# 	|| [ -f /var/lib/unifi/db/WiredTiger.lock ] \
# 	|| [ -f /var/run/unifi/db.needsRepair ] \
# 	|| [ -f /var/run/unifi/launcher.looping ]; then
# 		if [ -f /var/lib/unifi/db/mongod.lock ]; then rm -f /var/lib/unifi/db/mongod.lock; fi
# 		if [ -f /var/lib/unifi/db/WiredTiger.lock ]; then rm -f /var/lib/unifi/db/WiredTiger.lock; fi
# 		if [ -f /var/run/unifi/db.needsRepair ]; then rm -f /var/run/unifi/db.needsRepair; fi
# 		if [ -f /var/run/unifi/launcher.looping ]; then rm -f /var/run/unifi/launcher.looping; fi
# 		echo >> $LOG
# 		echo "Repairing Unifi DB on \$(date)" >> $LOG
# 		su -c "/usr/bin/mongod --repair --dbpath /var/lib/unifi/db --smallfiles --logappend --logpath ${MONGOLOG} 2>>$LOG" unifi
# 	fi
# else
# 	echo "MongoDB is running. Exiting..."
# 	exit 1
# fi
# exit 0
# _EOF
# 	chmod a+x /usr/local/sbin/unifidb-repair.sh

# 	cat > /etc/systemd/system/unifidb-repair.service <<_EOF
# [Unit]
# Description=Repair UniFi MongoDB database at boot
# Before=unifi.service mongodb.service
# After=network-online.target
# Wants=network-online.target
# [Service]
# Type=oneshot
# ExecStart=/usr/local/sbin/unifidb-repair.sh
# [Install]
# WantedBy=multi-user.target
# _EOF
# 	systemctl enable unifidb-repair.service
# 	echo "Unifi DB autorepair set up"
# fi

# ###########################################################
# #
# # Set up daily backup to a bucket after 01:00
# #


# bucket=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c ".bucket" | tr --delete '"')
# if [ ${bucket} ]; then
# 	cat > /etc/systemd/system/unifi-backup.service <<_EOF
# [Unit]
# Description=Daily backup to OCI Storage service
# After=network-online.target
# Wants=network-online.target
# [Service]
# Type=oneshot
# ExecStart=/usr/bin/find /var/lib/unifi/backup -iname '*.unf' -exec curl -T {} $bucket \;
# _EOF

# 	cat > /etc/systemd/system/unifi-backup.timer <<_EOF
# [Unit]
# Description=Daily backup to OCI Storage timer
# [Timer]
# OnCalendar=1:00
# RandomizedDelaySec=30m
# [Install]
# WantedBy=timers.target
# _EOF
# 	systemctl daemon-reload
# 	systemctl start unifi-backup.timer
# 	echo "Backups to OCI Storage set up"
# fi




# ###########################################################
# #
# # Set up Let's Encrypt
# #
# dnsname=$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq -c '.["dns-name"]' | tr --delete '"')
# echo "DNS Name found is" $dnsname
# if [ -z $dnsname ]; then exit 0; fi
# echo "Got past the dnsname check"

# echo "Installing certbot"
# apt-get update
# apt-get -qq install software-properties-common
# add-apt-repository universe
# add-apt-repository -y ppa:certbot/certbot
# apt-get update
# apt-get -qq install -y certbot

# privkey=/etc/letsencrypt/live/$dnsname/privkey.pem
# pubcrt=/etc/letsencrypt/live/$dnsname/cert.pem
# chain=/etc/letsencrypt/live/$dnsname/chain.pem
# caroot=/usr/share/misc/ca_root.pem

# # Write the cross signed root certificate to disk
# if [ ! -f $caroot ]; then
# 	cat > $caroot <<_EOF
# -----BEGIN CERTIFICATE-----
# MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/
# MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
# DkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVow
# PzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQD
# Ew5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4O
# rz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEq
# OLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9b
# xiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw
# 7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaD
# aeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNV
# HQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqG
# SIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69
# ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXr
# AvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZz
# R8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5
# JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYo
# Ob8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ
# -----END CERTIFICATE-----
# _EOF
# fi

# # Write pre and post hooks to stop Lighttpd for the renewal
# if [ ! -d /etc/letsencrypt/renewal-hooks/pre ]; then
# 	mkdir -p /etc/letsencrypt/renewal-hooks/pre
# fi
# cat > /etc/letsencrypt/renewal-hooks/pre/lighttpd <<_EOF
# #! /bin/sh
# systemctl stop lighttpd
# _EOF
# chmod a+x /etc/letsencrypt/renewal-hooks/pre/lighttpd

# if [ ! -d /etc/letsencrypt/renewal-hooks/post ]; then
# 	mkdir -p /etc/letsencrypt/renewal-hooks/post
# fi
# cat > /etc/letsencrypt/renewal-hooks/post/lighttpd <<_EOF
# #! /bin/sh
# systemctl start lighttpd
# _EOF
# chmod a+x /etc/letsencrypt/renewal-hooks/post/lighttpd

# # Write the deploy hook to import the cert into Java
# if [ ! -d /etc/letsencrypt/renewal-hooks/deploy ]; then
# 	mkdir -p /etc/letsencrypt/renewal-hooks/deploy
# fi
# cat > /etc/letsencrypt/renewal-hooks/deploy/unifi <<_EOF
# #! /bin/sh

# if [ -e $privkey ] && [ -e $pubcrt ] && [ -e $chain ]; then

# 	echo >> $LOG
# 	echo "Importing new certificate on \$(date)" >> $LOG
# 	p12=\$(mktemp)

# 	if ! openssl pkcs12 -export \\
# 	-in $pubcrt \\
# 	-inkey $privkey \\
# 	-CAfile $chain \\
# 	-out \$p12 -passout pass:aircontrolenterprise \\
# 	-caname root -name unifi >/dev/null ; then
# 		echo "OpenSSL export failed" >> $LOG
# 		exit 1
# 	fi

# 	if ! keytool -delete -alias unifi \\
# 	-keystore /var/lib/unifi/keystore \\
# 	-deststorepass aircontrolenterprise >/dev/null ; then
# 		echo "KeyTool delete failed" >> $LOG
# 	fi

# 	if ! keytool -importkeystore \\
# 	-srckeystore \$p12 \\
# 	-srcstoretype pkcs12 \\
# 	-srcstorepass aircontrolenterprise \\
# 	-destkeystore /var/lib/unifi/keystore \\
# 	-deststorepass aircontrolenterprise \\
# 	-destkeypass aircontrolenterprise \\
# 	-alias unifi -trustcacerts -noprompt >/dev/null; then
# 		echo "KeyTool import failed" >> $LOG
# 		exit 2
# 	fi

# 	systemctl stop unifi
# 	if ! java -jar /usr/lib/unifi/lib/ace.jar import_cert \\
# 	$pubcrt $chain $caroot >/dev/null; then
# 		echo "Java import_cert failed" >> $LOG
# 		systemctl start unifi
# 		exit 3
# 	fi
# 	systemctl start unifi
# 	rm -f \$p12
# 	echo "Success" >> $LOG
# else
# 	echo "Certificate files missing" >> $LOG
# 	exit 4
# fi
# _EOF
# chmod a+x /etc/letsencrypt/renewal-hooks/deploy/unifi

# # Write a script to acquire the first certificate (for a systemd timer)
# cat > /usr/local/sbin/certbotrun.sh <<_EOF
# #! /bin/sh
# extIP=\$(dig +short myip.opendns.com @resolver1.opendns.com)
# dnsIP=\$(getent hosts $dnsname | cut -d " " -f 1)

# echo >> $LOG
# echo "CertBot run on \$(date)" >> $LOG
# if [ "\$extIP" = "\$dnsIP" ]; then
# 	if [ ! -d /etc/letsencrypt/live/${dnsname} ]; then
# 		systemctl stop lighttpd
# 		if certbot certonly -d $dnsname --standalone --agree-tos --register-unsafely-without-email >> $LOG; then
# 			echo "Received certificate for $dnsname" >> $LOG
# 		fi
# 		systemctl start lighttpd
# 	fi
# 	if /etc/letsencrypt/renewal-hooks/deploy/unifi; then
# 		systemctl stop certbotrun.timer
# 		echo "Certificate installed for $dnsname" >> $LOG
# 	fi
# else
# 	echo "No action because $dnsname doesn't resolve to \$extIP" >> $LOG
# fi
# _EOF
# chmod a+x /usr/local/sbin/certbotrun.sh

# # Write the systemd unit files
# if [ ! -f /etc/systemd/system/certbotrun.timer ]; then
# 	cat > /etc/systemd/system/certbotrun.timer <<_EOF
# [Unit]
# Description=Run CertBot hourly until success
# [Timer]
# OnCalendar=hourly
# RandomizedDelaySec=15m
# [Install]
# WantedBy=timers.target
# _EOF
# 	systemctl daemon-reload

# 	cat > /etc/systemd/system/certbotrun.service <<_EOF
# [Unit]
# Description=Run CertBot hourly until success
# After=network-online.target
# Wants=network-online.target
# [Service]
# Type=oneshot
# ExecStart=/usr/local/sbin/certbotrun.sh
# _EOF
# fi

# # Start the above
# if [ ! -d /etc/letsencrypt/live/${dnsname} ] ; then
# 	if ! /usr/local/sbin/certbotrun.sh ; then
# 		echo "Installing hourly CertBot run"
# 		systemctl start certbotrun.timer
# 	fi
# fi
