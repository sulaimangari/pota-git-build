#!/usr/bin/bash

SMEE_URL=$(curl https://smee.io/new | grep -o "https://smee.io/[A-Za-z0-9-]*")
gh secret set MYSECRET --body "$SMEE_URL"

PUB_KEY=$(cat ~/.ssh/id_*.pub)
gh secret set MYSECRET --body "$PUB_KEY"






