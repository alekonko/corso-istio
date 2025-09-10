#!/usr/bin/env bash

token="$1"

if [ -z "$token" ]; then
  echo "Uso: $0 <JWT>"
  exit 1
fi

# separa le parti
header=$(echo "$token" | cut -d. -f1 | base64 -d 2>/dev/null | jq .)
payload=$(echo "$token" | cut -d. -f2 | base64 -d 2>/dev/null | jq .)

echo "===== HEADER ====="
echo "$header"
echo
echo "===== PAYLOAD ====="
echo "$payload"
echo

# estrai campi utili
iss=$(echo "$payload" | jq -r .iss)
aud=$(echo "$payload" | jq -r .aud)
exp=$(echo "$payload" | jq -r .exp)
iat=$(echo "$payload" | jq -r .iat)
now=$(date +%s)

echo "Issuer (iss): $iss"
echo "Audience (aud): $aud"
echo "Issued At (iat): $(date -d @$iat)"
echo "Expiration (exp): $(date -d @$exp)"
echo "Now:             $(date -d @$now)"

if [ "$now" -gt "$exp" ]; then
  echo "⚠️  Il token è SCADUTO!"
else
  echo "✅ Il token è valido temporalmente."
fi