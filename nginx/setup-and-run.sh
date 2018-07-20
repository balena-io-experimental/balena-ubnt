#!/bin/bash

set -e

SSLPATH=${SSLPATH:-/app/data/ssl}
CERT_COUNTRY=${CERT_COUNTRY:-UK}

if [ -z "$DOMAIN" ]; then
	echo "[ERROR] No DOMAIN defined. Please set this environment variable."
	exit 1
else
	echo "[INFO] Setting nginx configuration ..."
	sed -i "s/{{DOMAIN}}/$DOMAIN/g" /etc/nginx/conf.d/default.conf
	echo "[INFO] Done."
fi

# SSL self-signed certificate
if [ -f "$SSLPATH/nginx.key" ] && [ -f "$SSLPATH/nginx.crt" ] && [ -f "$SSLPATH/dhparam.pem" ]; then
	echo "[INFO] SSL certificates in place."
else
	echo "[INFO] Generating SSL certificate in $SSLPATH ..."
	mkdir -p "$SSLPATH"
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=$CERT_COUNTRY" -keyout "$SSLPATH/nginx.key" -out "$SSLPATH/nginx.crt"
	openssl dhparam -out "$SSLPATH/dhparam.pem" 2048
	echo "[INFO] Done."
fi


# Run the main container entrypoint provided by the base image
exec nginx -g 'daemon off;'
