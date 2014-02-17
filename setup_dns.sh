#!/bin/bash

REQUESTED_IP='192.168.1.50'
LOCAL_DOMAIN='dns.test'

case "$*" in
	*--add-record*)

		TARGET_IP = $2
		TARGET_DOMAIN = $3

		echo 'zone "'$TARGET_DOMAIN'" {' >> /etc/powerdns/pdns.d/$(TARGET_DOMAIN).conf
		echo '        type master;' >> /etc/powerdns/pdns.d/$(TARGET_DOMAIN).conf
		echo '        notify no;' >> /etc/powerdns/pdns.d/$(TARGET_DOMAIN).conf
		echo '        file "bind/'$TARGET_DOMAIN'.zone";' >> /etc/powerdns/pdns.d/$(TARGET_DOMAIN).conf
		echo '        allow-update { none; };' >> /etc/powerdns/pdns.d/$(TARGET_DOMAIN).conf
		echo '};' >> /etc/powerdns/pdns.d/$(TARGET_DOMAIN).conf

		echo '$ORIGIN test.dns     ; base for unqualified names' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '$TTL 1h                 ; default time-to-live' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '@                       IN      SOA ns.'$LOCAL_DOMAIN $REQUESTED_IP' (' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                                1; serial' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                                1d; refresh' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                                2h; retry' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                                4w; expire' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                                1h; minimum time-to-live' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                        )' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                        IN      NS      ns' >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo '                        IN      A      ' $TARGET_IP >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone
		echo 'ns                      IN      A      ' $TARGET_IP >> /etc/powerdns/bind/$(TARGET_DOMAIN).zone

		service pdns restart
	;;

	*)

		apt-get -y update upgrade

		echo 'send dhcp-requested-address' $REQUESTED_IP ';' >> /etc/dhcp/dhclient.conf

		mkdir /etc/powerdns/bind

		apt-get -y install pdns-server dnsutils

		sed -i 's/# recursor=/recursor=8.8.8.8/g' /etc/powerdns/pdns.conf
		sed -i 's/allow-recursion=127.0.0.1/allow-recursion=127.0.0.1,192.168.0.0\/24/g' /etc/powerdns/pdns.conf
		#does the above line assume I am on a 192.168.0.x network?

		cp adblock_include.conf /etc/powerdns/pdns.d/adblock_include.conf

		echo 'zone "'$LOCAL_DOMAIN'" {' >> /etc/powerdns/pdns.d/$(LOCAL_DOMAIN).conf
		echo '        type master;' >> /etc/powerdns/pdns.d/$(LOCAL_DOMAIN).conf
		echo '        notify no;' >> /etc/powerdns/pdns.d/$(LOCAL_DOMAIN).conf
		echo '        file "bind/'$LOCAL_DOMAIN'.zone";' >> /etc/powerdns/pdns.d/$(LOCAL_DOMAIN).conf
		echo '        allow-update { none; };' >> /etc/powerdns/pdns.d/$(LOCAL_DOMAIN).conf
		echo '};' >> /etc/powerdns/pdns.d/$(LOCAL_DOMAIN).conf

		echo '$TTL 1h                 ; default time-to-live' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '@                       IN      SOA ns.'$LOCAL_DOMAIN $REQUESTED_IP' (' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                                1; serial' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                                1d; refresh' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                                2h; retry' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                                4w; expire' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                                1h; minimum time-to-live' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                        )' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                        IN      NS      ns' >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo '                        IN      A      ' $REQUESTED_IP >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
		echo 'ns                      IN      A      ' $REQUESTED_IP >> /etc/powerdns/bind/$(LOCAL_DOMAIN).zone
#figure out the correct syntax and make these two look the same
		echo '$TTL	86400	; one day' >> /etc/powerdns/null.zone.file
		echo '@       IN      SOA     server      root.localhost. (' >> /etc/powerdns/bind/null.zone
		echo '                        2012110100       ; serial number YYMMDDNN' >> /etc/powerdns/bind/null.zone
		echo '                        28800   ; refresh  8 hours' >> /etc/powerdns/bind/null.zone
		echo '                        7200    ; retry    2 hours' >> /etc/powerdns/bind/null.zone
		echo '                        864000  ; expire  10 days' >> /etc/powerdns/bind/null.zone
		echo '                        86400 ) ; min ttl  1 day' >> /etc/powerdns/bind/null.zone
		echo '                NS      server' >> /etc/powerdns/bind/null.zone
		echo '		A	0.0.0.0' >> /etc/powerdns/bind/null.zone
		echo '*		IN      A       0.0.0.0' >> /etc/powerdns/bind/null.zone

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

		#/etc/init.d/lighttpd force-reload

		#set powerdns, lighttpd to turn on automatically
		#I think this already happens, verify

		apt-get clean

		reboot
	;;
esac
