#!/usr/bin/env bash
set -euo pipefail

# === VARIABILI ===
ISTIO_VER="1.25.1"
AMBIENT_NS="ambient-demo"

# echo "[1/9] Download istioctl ${ISTIO_VER}"
# curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VER} sh -
# export PATH="$PATH:$PWD/istio-${ISTIO_VER}/bin"
# istioctl version || true

echo "[1/9] SKIP Download istioctl ${ISTIO_VER}, uso quello installato"
istioctl version || true
echo "NEL CASO I COMANDI SON QUESTI"
echo curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VER} sh -
echo export PATH="$PATH:$PWD/istio-${ISTIO_VER}/bin"
echo istioctl version || true
istioctl version || true

echo "[2/9] Install Istio con profilo AMBIENT (include istiod, CNI, ztunnel)"
istioctl install --set profile=ambient --skip-confirmation
# (profilo ambient consigliato per provare ambient mode)  # docs: istioctl + ambient

echo "[3/9] (Opzionale) Install Gateway API CRDs per waypoint in futuro"
kubectl get crd gateways.gateway.networking.k8s.io &>/dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

echo "[4/9] Abilita SIDECAR nel namespace default"
kubectl label namespace default istio-injection=enabled --overwrite

echo "[5/9] Crea namespace AMBIENT e abilita dataplane ambient"
kubectl create namespace "${AMBIENT_NS}" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "${AMBIENT_NS}" istio.io/dataplane-mode=ambient --overwrite

echo "[6/9] Deploy di test"
# Sidecar nel default: vedrai 2 container (app + istio-proxy)
kubectl -n default create deployment test-sidecar --image=nginx --dry-run=client -o yaml | kubectl apply -f -
# Ambient nell'NS dedicato: nessun sidecar nel pod; traffico intercettato da ztunnel
kubectl -n "${AMBIENT_NS}" create deployment test-ambient --image=nginx --dry-run=client -o yaml | kubectl apply -f -

echo "[7/9] Verifiche"
echo "- Sidecar: cerca 'istio-proxy' tra i container"
kubectl -n default get pods -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{range .spec.containers[*]}{.name}{" "}{end}{"\n"}{end}'

echo "- Ambient: verifica annotation di redirezione (settata dal CNI quando attivo)"
POD_AMB=$(kubectl -n "${AMBIENT_NS}" get pod -l app=test-ambient -o jsonpath='{.items[0].metadata.name}')
kubectl -n "${AMBIENT_NS}" get pod "$POD_AMB" -o jsonpath='{.metadata.annotations.ambient\.istio\.io/redirection}{"\n"}'

echo "[8/9] Proxy sync & stato (utile per vedere LDS/RDS/CDS/EDS)"
istioctl proxy-status

echo "[9/9] Hint: ztunnel e CNI"
kubectl -n istio-system get ds ztunnel || true
kubectl -n istio-system get pods -o wide
 