#!/bin/bash
set -e

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir
CONFIG_PATH=/data/options.json

EMAIL=$(jq --raw-output ".email" $CONFIG_PATH)
DOMAINS=$(jq --raw-output ".domains[]" $CONFIG_PATH)
KEYFILE=$(jq --raw-output ".keyfile" $CONFIG_PATH)
CERTFILE=$(jq --raw-output ".certfile" $CONFIG_PATH)

mkdir -p "$CERT_DIR"

if [[ $(jq --raw-output ".dns_rfc2136" $CONFIG_PATH) != "null" ]]; then
    jq --raw-output ".dns_rfc2136" $CONFIG_PATH > /dns-rfc2136.ini
fi

# Generate new certs
if [ ! -d "$CERT_DIR/live" ]; then
    DOMAIN_ARR=()
    for line in $DOMAINS; do
        DOMAIN_ARR+=(-d "$line")
    done

    echo "$DOMAINS" > /data/domains.gen

    if [ -f /dns-rfc2136.ini ]; then
        certbot certonly --non-interactive --email "$EMAIL" --agree-tos --config-dir "$CERT_DIR" --dns-rfc2136 --dns-rfc2136-credentials /dns-rfc2136 "${DOMAIN_ARR[@]}"
    else
        certbot certonly --non-interactive --standalone --email "$EMAIL" --agree-tos --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --preferred-challenges "http" "${DOMAIN_ARR[@]}"
    fi

# Renew certs
else
    if [ -f /dns-rfc2136.ini ]; then
        certbot renew --non-interactive --config-dir "$CERT_DIR"
    else
        certbot renew --non-interactive --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --preferred-challenges "http"
    fi
fi

# copy certs to store
cp "$CERT_DIR"/live/*/privkey.pem "/ssl/$KEYFILE"
cp "$CERT_DIR"/live/*/fullchain.pem "/ssl/$CERTFILE"

