#!/bin/sh
set -eu

ATTEMPTS=0
until [ "$ATTEMPTS" -ge 3 ]; do
  ssh -oStrictHostKeyChecking=accept-new "$1" exit && break
  ATTEMPTS=$(expr "$ATTEMPTS" + 1)
  sleep 10
done

ssh "$1" cloud-init status --wait >/dev/null
ssh "$1" cloud-init status
