#!/bin/sh
# Generates a self-signed TLS certificate for the lab domain if one doesn't
# already exist. In a real deployment, replace this with certbot/Let's
# Encrypt (see docs/ssl-notes.md for the exact swap-in steps).
set -e

CERT_DIR="/etc/nginx/ssl"
DOMAIN="${LAB_DOMAIN:-lab.local}"

mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/fullchain.pem" ]; then
  echo "[gen-self-signed-cert] No cert found, generating self-signed cert for $DOMAIN ..."
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=PK/ST=Punjab/L=Lahore/O=DevOpsLab/CN=$DOMAIN" \
    -addext "subjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:python.$DOMAIN,DNS:node.$DOMAIN,DNS:java.$DOMAIN"
  echo "[gen-self-signed-cert] Done."
else
  echo "[gen-self-signed-cert] Existing cert found, skipping."
fi
