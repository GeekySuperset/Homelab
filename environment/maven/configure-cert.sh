#!/bin/bash

# Script to add Nexus SSL certificate to Java cacerts
# JDKs are installed/managed by SDKMAN!
# Usage: ./configure-cert.sh

NEXUS_HOST="nexus.homelab"
CERT_FILE="/tmp/nexus.crt"

# Get certificate from Nexus
echo "Fetching certificate from $NEXUS_HOST"
openssl s_client -connect $NEXUS_HOST:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > $CERT_FILE

if [ ! -f "$CERT_FILE" ] || [ ! -s "$CERT_FILE" ]; then
    echo "Error: Failed to retrieve certificate from $NEXUS_HOST"
    exit 1
fi

# Import certificate
echo "Importing certificate to Java keystore"
keytool -importcert -cacerts -alias "$NEXUS_HOST" -file "$CERT_FILE" -storepass changeit -noprompt

if [ $? -eq 0 ]; then
    echo "Certificate successfully imported!"
    rm -f "$CERT_FILE"
else
    echo "Error: Failed to import certificate"
    exit 1
fi