#!/usr/bin/env bash
set -euo pipefail

# =========================
# CONFIGURAZIONE
# =========================
TENANT="dev-rzkchlfkzqyo3c07.us.auth0.com"
CLIENT_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
CLIENT_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
AUDIENCE="http://conco-api"
NODE_IP="127.0.0.1"
NODEPORT="1234"

# =========================
# RICHIESTA TOKEN
# =========================
echo "===> Richiedo un nuovo token da Auth0"
RAW=$(curl -s --request POST \
  --url https://$TENANT/oauth/token \
  --header 'content-type: application/json' \
  --data "{
    \"client_id\":\"$CLIENT_ID\",
    \"client_secret\":\"$CLIENT_SECRET\",
    \"audience\": \"$AUDIENCE\",
    \"grant_type\":\"client_credentials\"
  }")

ACCESS_TOKEN=$(echo "$RAW" | jq -r '.access_token')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "❌ Nessun token trovato, risposta Auth0:"
  echo "$RAW"
  exit 1
fi

echo "✅ Token ricevuto (prime 80 chars): ${ACCESS_TOKEN:0:80}..."

# =========================
# VERIFICA FORMATO JWT
# =========================
IFS='.' read -r h p s <<< "$ACCESS_TOKEN"
if [[ -z "$h" || -z "$p" || -z "$s" ]]; then
  echo "❌ JWT non valido (non ha 3 sezioni)"
  exit 1
fi
echo "✅ JWT valido nel formato Header.Payload.Signature"

# =========================
# DECODE PAYLOAD
# =========================
echo "===> Decodifico payload"
echo "$p" | base64 --decode 2>/dev/null | jq || echo "⚠️ Payload non decodificabile"

# =========================
# RICHIESTA AL SERVIZIO ISTIO
# =========================
echo "===> Invio richiesta a Istio ingress"
# curl -v -H "Authorization: Bearer $ACCESS_TOKEN" \
#      -H "Host: conco-api" \
#      "http://$NODE_IP:$NODEPORT/"

echo curl -v -H "Authorization: Bearer $ACCESS_TOKEN" --resolve "conco-api:1234:127.0.0.1" http://conco-api:1234/


echo $ACCESS_TOKEN > token