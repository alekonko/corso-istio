#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=istio-system
NODEPORT=80            # porta interna del gateway
ACCESS_TOKEN="$1"      # passa il token come primo arg
TENANT="dev-rzkchlfkzqyo3c07.us.auth0.com"

# Recupera il pod dell’ingressgateway
POD=$(kubectl get pod -n $NAMESPACE -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}')
echo "==> Pod ingressgateway: $POD"

# Verifica JWKS direttamente dal pod
echo "==> Test JWKS dal pod..."
kubectl exec -n $NAMESPACE $POD -- curl -s -o /dev/null -w "%{http_code}" "https://$TENANT/.well-known/jwks.json"

# Port-forward temporaneo per test JWT
echo "==> Eseguo port-forward temporaneo..."
kubectl port-forward -n $NAMESPACE $POD 18080:$NODEPORT >/dev/null 2>&1 &
PF_PID=$!
trap "kill $PF_PID" EXIT
sleep 2

# Invia richiesta all’ingress con JWT
echo "==> Invio richiesta con JWT"
curl -v -H "Authorization: Bearer $ACCESS_TOKEN" \
     -H "Host: conco-api" \
     http://127.0.0.1:18080/
