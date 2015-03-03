#!/usr/bin/env bash

#
# Date: 1 December, 2014
# Author: Aman Hanjrah and Peeyush Budhia
# URI: http://techlinux.net and http://phpnmysql.com
# License: GNU GPL v2.0
# Description: The script is used to check the status of all the services, if stopped then script will try to start the service, if the service not get started the script will send a notification email using mutt.
#

main() {
	prerequisites
	init
	chkAllServices
	sendMail
}

prerequisites() {
	CHK_MUTT=`rpm -qa | grep mutt`
	if [[ ! -n '$CHK_MUTT' ]]; then
		yum -y install mutt
		unset CHK_MUTT
		CHK_MUTT=`rpm -qa | grep mutt`
		if [[ ! -n "$CHK_MUTT" ]]; then
			exit 1
		fi
	fi
}

init() {
	EMAIL_TO="someone@domain"

	SER_APACHE="httpd"
	SER_NGINX="nginx"
	SER_MYSQLD="mysqld"
	SER_PHP_FPM="php-fpm"
	SER_PERCONA="mysql"
	SER_POSTFIX="postfix"
	SER_DOVECOT="dovecot"
}

chkAllServices() {
	chkHttpd
	chkNginx
	chkPHP_FPM
	chkMySQLD
	chkPercona
	chkPostfix
	chkDovecot
}

chkHttpd() {
	CHK_APACHE=`rpm -qa | grep httpd`
	if [[ -n "$CHK_APACHE" ]]; then
		SERVICE="$SER_APACHE"
		chkService
	fi
}

chkNginx() {
	CHK_NGINX=`rpm -qa | grep nginx`
	if [[ -n "$CHK_NGINX" ]]; then
		SERVICE="$SER_NGINX"
		chkService
	fi
}

chkPHP_FPM() {
	CHK_PHP_FPM=`rpm -qa | grep php-fpm`
	if [[ -n "$CHK_PHP_FPM" ]]; then
		SERVICE="$SER_PHP_FPM"
		chkService
	fi
}

chkMySQLD() {
	CHK_MYSQLD=`rpm -qa | grep mysql-server`
	if [[ -n "$CHK_MYSQLD" ]]; then
		SERVICE="$SER_MYSQLD"
		chkService
	fi
}

chkPercona() {
	CHK_PERCONA=`rpm -qa | grep Percona-Server`
	if [[ -n "$CHK_PERCONA" ]]; then
		SERVICE="$SER_PERCONA"
		chkService
	fi
}

chkPostfix() {
	CHK_POSTFIX=`rpm -qa | grep postfix`
	if [[ -n "$CHK_POSTFIX" ]]; then
		SERVICE="$SER_POSTFIX"
		chkService
	fi
}

chkDovecot() {
	CHK_DOVECOT=`rpm -qa | grep dovecot`
	if [[ -n "$CHK_DOVECOT" ]]; then
		SERVICE="$SER_DOVECOT"
		chkService
	fi
}

chkService() {
	STATUS=$(/etc/init.d/$SERVICE status)
	if [[ $(echo $?) != 0 ]]; then
		$(/etc/init.d/$SERVICE start)
		NEW_STATUS=$(/etc/init.d/$SERVICE status)
		if [[ $(echo $?) != 0 ]]; then
			touch /tmp/srv_ser_err.log
			echo -e "$SERVICE" >> /tmp/srv_ser_err.log
		fi
	fi
	
	unset SERVICE
	unset STATUS
	unset NEW_STATUS
}

sendMail() {
	if [[ -s /tmp/srv_ser_err.log ]]; then
		ERRORS=`cat /tmp/srv_ser_err.log`
		echo -e "An attempt to start the following service(s) Failed!\n$ERRORS" | mutt -s "[CRITICAL] Server Alert!" -- $EMAIL_TO
		rm -rf /tmp/srv_ser_err.log
	fi
}
main
