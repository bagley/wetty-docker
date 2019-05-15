#!/bin/sh

ssl_dir=/ssl
ssl_key=/ssl/key.pem
ssl_cert=/ssl/cert.pem

if ! [ -f $ssl_key ] || ! [ -f $ssl_cert ] ; then
	rm -f $ssl_key $ssl_cert
	echo "One or both SSL keys were not found. Generating new ones..."

	openssl req -x509 -newkey rsa:2048 -keyout $ssl_key -out $ssl_cert \
		-days 300000 -nodes -subj "/C=YZ/ST=Hello/L=Here/O=Company/OU=Org/CN=wetty"
fi

yarn start --sshhost 'wetty-ssh' --sshport 22 --base ${BASEURL} --sslkey $ssl_key --sslcert $ssl_cert
