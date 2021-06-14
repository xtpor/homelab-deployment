#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "Populating the LDAP at $URL"
echo "Log in as $BIND_DN"

# WARN: this script will blindly trust the server's tls certificate
export LDAPTLS_REQCERT=never

echo "$DATA" | \
  ldapadd -H "$URL" \
  -D "$BIND_DN" \
  -w "$BIND_PASSWORD"
