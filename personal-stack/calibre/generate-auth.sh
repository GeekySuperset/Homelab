#!/usr/bin/env bash

# Script to generate a base64 auth string for Calibre Traefik auto-login middleware.
# Usage: ./generate-auth.sh -u <username> -p <password> [-w|--write]

set -euo pipefail

WRITE_ENV=false
USERNAME=""
PASSWORD=""

usage() {
  echo "Usage:"
  echo "  $0 -u <username> -p <password> [-w|--write]"
  echo ""
  echo "Options:"
  echo "  -u, --username  Calibre web username (required)"
  echo "  -p, --password  Calibre web password (required)"
  echo "  -w, --write     Update or append CALIBRE_AUTH_BASE64 in .env file"
  echo "  -h, --help      Display this help message"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--username)
      if [[ -z "${2:-}" ]]; then
        echo "Error: Option $1 requires a non-empty argument." >&2
        usage
      fi
      USERNAME="$2"
      shift 2
      ;;
    -p|--password)
      if [[ -z "${2:-}" ]]; then
        echo "Error: Option $1 requires a non-empty argument." >&2
        usage
      fi
      PASSWORD="$2"
      shift 2
      ;;
    -w|--write)
      WRITE_ENV=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: Unexpected argument '$1'" >&2
      usage
      ;;
  esac
done

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
  echo "Error: Both -u/--username and -p/--password are required." >&2
  usage
fi

BASE64_AUTH=$(printf '%s:%s' "$USERNAME" "$PASSWORD" | base64)

echo "=========================================="
echo " Calibre Basic Auth Base64 Generator"
echo "=========================================="
echo "Username:           ${USERNAME}"
echo "Base64 Auth String: ${BASE64_AUTH}"
echo "Header Value:       Basic ${BASE64_AUTH}"
echo "=========================================="
echo ""
echo "Add the following line to your .env file:"
echo "CALIBRE_AUTH_BASE64=${BASE64_AUTH}"

if [[ "$WRITE_ENV" == true ]]; then
  ENV_FILE=""
  if [[ -f ".env" ]]; then
    ENV_FILE=".env"
  elif [[ -f "../.env" ]]; then
    ENV_FILE="../.env"
  fi

  if [[ -n "$ENV_FILE" ]]; then
    if grep -q "^CALIBRE_AUTH_BASE64=" "$ENV_FILE"; then
      sed -i "s|^CALIBRE_AUTH_BASE64=.*|CALIBRE_AUTH_BASE64=${BASE64_AUTH}|" "$ENV_FILE"
      echo "Updated CALIBRE_AUTH_BASE64 in ${ENV_FILE}"
    else
      echo "CALIBRE_AUTH_BASE64=${BASE64_AUTH}" >> "$ENV_FILE"
      echo "Appended CALIBRE_AUTH_BASE64 to ${ENV_FILE}"
    fi
  else
    echo "CALIBRE_AUTH_BASE64=${BASE64_AUTH}" > .env
    echo "Created .env with CALIBRE_AUTH_BASE64=${BASE64_AUTH}"
  fi
fi
