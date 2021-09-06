#!/bin/sh

if [ -n "$1" ] ; then
	$@
	exit
fi

ssl_dir=/home/node/ssl
ssl_key=$ssl_dir/key.pem
ssl_cert=$ssl_dir/cert.pem

mkdir -p $ssl_dir

if ! [ -f $ssl_key ] || ! [ -f $ssl_cert ] ; then
	rm -f $ssl_key $ssl_cert
	echo "One or both SSL keys were not found. Generating new ones..."

	openssl req -x509 -newkey rsa:4096 -keyout $ssl_key -out $ssl_cert \
		-days 300000 -nodes -subj "/C=YZ/ST=Hello/L=Here/O=Company/OU=Org/CN=wetty"
fi

yarn start --ssh-host 'wetty-ssh' --ssh-port 22 --base ${BASEURL}/ --ssl-key $ssl_key --ssl-cert $ssl_cert
