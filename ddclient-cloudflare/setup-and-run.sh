#!/bin/sh

set -e

DDCLIENT_UPDATE_SECONDS=${DDCLIENT_UPDATE_SECONDS:-600}

if [ -z "$CLOUDFLARE_APIKEY" ] || [ -z "$CLOUDFLARE_LOGIN" ] || [ -z "$DOMAIN" ]; then
	echo "[INFO] ddclient off as needed variables are missing."
	echo "       If you want it on, make sure CLOUDFLARE_APIKEY, CLOUDFLARE_LOGIN and DOMAIN are defined."
	exit 1
else
	echo "[INFO] Setting ddclient configuration ..."
	sed -i "s/{{CLOUDFLARE_APIKEY}}/$CLOUDFLARE_APIKEY/g; \
		s/{{CLOUDFLARE_LOGIN}}/$CLOUDFLARE_LOGIN/g; \
		s/{{DDCLIENT_UPDATE_SECONDS}}/$DDCLIENT_UPDATE_SECONDS/g; \
		s/{{DOMAIN}}/$DOMAIN/g;" \
	      	/etc/ddclient/ddclient.conf
fi

echo "[INFO] Running ddclient ..."
exec ddclient -foreground -noquiet "$DDCLIENT_EXTRAARGS"
