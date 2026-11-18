#!/bin/bash

# Script to add Nexus SSL certificate to Java cacerts
# JDKs are installed/managed by SDKMAN!
# Usage: ./configure-cert.sh

NEXUS_HOST="nexus.homelab"
CERT_ALIAS="${NEXUS_HOST}-root"
TMP_DIR="$(mktemp -d)"
CHAIN_FILE="$TMP_DIR/chain.pem"
LAST_CERT_FILE="$TMP_DIR/last.crt"

# Get full certificate chain from Nexus
# -servername ensures correct cert is returned when SNI is used.
echo "Fetching certificate chain from $NEXUS_HOST"
openssl s_client -connect "$NEXUS_HOST:443" -servername "$NEXUS_HOST" -showcerts </dev/null 2>/dev/null \
  | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' > "$CHAIN_FILE"

if [ ! -s "$CHAIN_FILE" ]; then
    echo "Error: Failed to retrieve certificate chain from $NEXUS_HOST"
    exit 1
fi

# Always use the last certificate in the chain.
sed -n '
/-----BEGIN CERTIFICATE-----/ {
  h
  :collect
  n
  H
  /-----END CERTIFICATE-----/!b collect
  x
}
$ {
  p
}
' "$CHAIN_FILE" > "$LAST_CERT_FILE"

if [ ! -s "$LAST_CERT_FILE" ]; then
    echo "Error: Failed to isolate the last certificate from the chain"
    exit 1
fi

echo "Selected certificate details:"
openssl x509 -in "$LAST_CERT_FILE" -noout -subject -issuer -dates

# Replace existing alias if present so updates are idempotent.
if keytool -list -cacerts -alias "$CERT_ALIAS" -storepass changeit >/dev/null 2>&1; then
    echo "Removing existing certificate alias: $CERT_ALIAS"
    keytool -delete -cacerts -alias "$CERT_ALIAS" -storepass changeit
fi

# Import certificate
echo "Importing certificate to Java keystore as alias: $CERT_ALIAS"
keytool -importcert -cacerts -alias "$CERT_ALIAS" -file "$LAST_CERT_FILE" -storepass changeit -noprompt
