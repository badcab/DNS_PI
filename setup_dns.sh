#!/bin/bash

REQUESTED_IP='192.168.101.150'
LOCAL_DOMAIN='dns.test'

case "$*" in
	*--add-record*)

		TARGET_IP = $2
		TARGET_DOMAIN = $3

#we will be using bind9 now so these need to change
	;;

	*)

		apt-get update
		apt-get -y upgrade

		echo 'send dhcp-requested-address' $REQUESTED_IP ';' >> /etc/dhcp/dhclient.conf

		apt-get -y install bind9 bind9utils



#configure the dns
#edit resolve.conf or something


echo 'options { ' >> /etc/bind/named.conf.options
echo '	directory "/var/cache/bind" ; ' >> /etc/bind/named.conf.options
echo '	forwarders { 8.8.8.8 ; 8.8.4.4 ; } ; ' >> /etc/bind/named.conf.options
echo '	auth-nxdomain no ; ' >> /etc/bind/named.conf.options
echo '	listen-on port 53 { 127.0.0.1; '$REQUESTED_IP'; } ;' >> /etc/bind/named.conf.options
echo '};' >> /etc/bind/named.conf.options



# Create this file in the nano editor:
#  nano /etc/bind/named.conf.local
# Then add the following content:
#  // named.conf.local file for BIND9 configuration
#  //
#  zone "domain.local"
#  {
#  type master ;
#  file "/etc/bind/zone.domain.local" ;
#  } ;

#note I will not be using reverse look up



#after I test this I will need to then include by add block list





		#add webmin
		sudo apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
		wget http://prdownloads.sourceforge.net/webadmin/webmin_1.580_all.deb
		sudo dpkg --install webmin_1.580_all.deb
		sudo rm webmin_1.580_all.deb


		#add local webserver
		addgroup --system www-data
		adduser www-data www-data
		usermod -a -G www-data www-data
		apt-get -y install lighttpd php5-cgi
		chown -R www-data:www-data /var/www

		echo '<?php phpinfo(); ?>' > /var/www/index.php

		sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g' /etc/php5/cgi/php.ini

		echo 'server.modules += ("mod_cgi")' >> /etc/lighttpd/conf-enabled/10-cgi-php.conf
		echo ' cgi.assign = (".php" => "/usr/bin/php5-cgi")' >> /etc/lighttpd/conf-enabled/10-cgi-php.conf

		apt-get clean

		reboot
	;;
esac
