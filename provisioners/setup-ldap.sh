#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "Populating the LDAP at $URL"
echo "Log in as $BIND_DN"

# WARN: this script will blindly trust the server's tls certificate
export LDAPTLS_REQCERT=never

# Wait a bit if the LDAP server isn't up immediately yet
ATTEMPTS=0
until [ "$ATTEMPTS" -ge 3 ]; do
  ldapwhoami -x \
    -H "$URL" \
    -D "$BIND_DN" \
    -w "$BIND_PASSWORD" >/dev/null && break

  ATTEMPTS=$(expr "$ATTEMPTS" + 1)
  sleep 10
done

echo "$DATA" | \
  ldapadd -H "$URL" \
  -D "$BIND_DN" \
  -w "$BIND_PASSWORD"
