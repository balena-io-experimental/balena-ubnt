#!/bin/bash

set -e

DHPARAM_PATH=${DHPARAM_PATH:-/app/data/ssl}
SELFCERT_PATH=${SELFCERT_PATH:-/app/data/ssl}
SELFCERT_COUNTRY=${CERT_COUNTRY:-UK}
LETSENCRYPT_PATH=/etc/letsencrypt/live
CLOUDFLARE_CREDS=/etc/cloudflare/creds.ini
NGINX_SPEC=/app/nginx-spec.conf
SERVICES=(unifi:8443 uisp:443)
CERTBOT="certbot"

function log { echo "[$1] $2"; }
function logerror { log "ERROR" "$1"; exit 1; }
function loginfo { log "INFO" "$1"; }

function letsencrypt_generate {
	local _domain="$1"
	if 	[ -f "$LETSENCRYPT_PATH/$_domain/privkey.pem" ] && \
		[ -f "$LETSENCRYPT_PATH/$_domain/fullchain.pem" ]; then
		loginfo "$_domain letsencrypt certificate in place."
	else
		loginfo "Generating new letsencrypt certificate for $_domain ..."
		$CERTBOT certonly -n --register-unsafely-without-email --agree-tos \
			 --dns-cloudflare --dns-cloudflare-credentials "$CLOUDFLARE_CREDS" \
			 -d "$_domain"
	fi
}

function selfsigned_generate {
	local _domain="$1"
	if 	[ -f "$SELFCERT_PATH/$_domain/privkey.pem" ] && \
		[ -f "$SELFCERT_PATH/$_domain/fullchain.pem" ]; then
		loginfo "$_domain self-signed certificate in place."
	else
		loginfo "Generating new self-signed certificate for $_domain ..."
		mkdir -p "$SELFCERT_PATH/$_domain"
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=$SELFCERT_COUNTRY" \
			-keyout "$SELFCERT_PATH/$_domain/privkey.pem" -out "$SELFCERT_PATH/$_domain/fullchain.pem"
	fi
}

echo ; loginfo "Starting configuration ..."

[ -z "$DOMAIN" ] && logerror "No DOMAIN defined. Please set this environment variable."

if [ -n "$LETSENCRYPT" ]; then
	loginfo "Setting up letsecrypt certificates."
	{ [ -z "$CLOUDFLARE_LOGIN" ] || [ -z "$CLOUDFLARE_APIKEY" ]; } && logerror "Cloudflare credentials missing."
	mkdir -p "$(dirname $CLOUDFLARE_CREDS)"
	cat <<EOF > $CLOUDFLARE_CREDS
dns_cloudflare_email = $CLOUDFLARE_LOGIN
dns_cloudflare_api_key = $CLOUDFLARE_APIKEY
EOF
	chmod 600 $CLOUDFLARE_CREDS
	for service in "${SERVICES[@]}"; do
		SUBDOMAIN=${service%%:*}
		letsencrypt_generate "$SUBDOMAIN.$DOMAIN"
	done
else
	loginfo "Setting up self-signed certificates."
	for service in "${SERVICES[@]}"; do
		SUBDOMAIN=${service%%:*}
		selfsigned_generate "$SUBDOMAIN.$DOMAIN"
	done
fi

if [ -f "$DHPARAM_PATH/dhparam.pem" ]; then
	loginfo "DH param file in place."
else
	loginfo "Generating DH Param file in $DHPARAM_PATH ..."
	mkdir -p "$DHPARAM_PATH"
	openssl dhparam -out "$DHPARAM_PATH/dhparam.pem" 2048
fi

loginfo "Setting nginx configuration ..."
for service in "${SERVICES[@]}"; do
	SUBDOMAIN=${service%%:*}
	PORT=${service#*:}
	cp $NGINX_SPEC "/etc/nginx/conf.d/$SUBDOMAIN.$DOMAIN.conf"
	sed -i "s/{{DOMAIN}}/$DOMAIN/g; \
		s/{{SUBDOMAIN}}/$SUBDOMAIN/g; \
		s/{{PORT}}/$PORT/g;" \
	     	"/etc/nginx/conf.d/$SUBDOMAIN.$DOMAIN.conf"
	if [ -n "$LETSENCRYPT" ]; then
		sed -i "s#{{SSL_CERTIFICATE}}#$LETSENCRYPT_PATH#g; \
			s#{{SSL_CERTIFICATE_KEY}}#$LETSENCRYPT_PATH#g" \
	     		"/etc/nginx/conf.d/$SUBDOMAIN.$DOMAIN.conf"
	else
		sed -i "s#{{SSL_CERTIFICATE}}#$SELFCERT_PATH#g; \
			s#{{SSL_CERTIFICATE_KEY}}#$SELFCERT_PATH#g" \
	     		"/etc/nginx/conf.d/$SUBDOMAIN.$DOMAIN.conf"
	fi
done

loginfo "Running nginx ..."
exec nginx -g 'daemon off;'
