# Circuit Breaker

Prereq: installazione gateway-api e istio ambient

```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || kubectl apply -f manifests/gateway-api-1.3.0-install.yaml
istioctl install --set profile=ambient --skip-confirmation
```

## Setup ambiente

```bash
ns=circuit-breaker-test
kubectl create namespace ${ns}
kubectl label namespace ${ns} istio-injection=enabled
kubectl config set-context --current --namespace=${ns}
cd C_circuit_breaker/
```

DEPLOYAMO UNA APP DI TEST CHE RISPONDE CON CODICI DI RISPOSTA IN BASE ALLA CHIAMATA

```bash
kubectl apply -f 1_httpbin.yaml
```

test chiamata, se chiamo mi risponde normalmente

```bash
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/200" 
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/500"
```


## CIRCUIT BREAKER

```bash
kubectl apply -f 2_circuit.yaml
```

se la mia applicazione mi risponde 500 si attiva il circuit per 1 minuto
se chiamo piu volte il 200 tutto ok

```bash
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/200" 
```

non appena chiamo il 500 il circuit breaker si attiva e mi rispondera 503 per 1 minuto

```bash
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/500"
```

```bash
for i in {1..60};
  do 
   kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/200" 
   sleep 1
  done;
```

mentre ricevo le chiamate che vanno in 503 sulla mia app non ricevo traffico

```bash
kubectl logs -l app=httpbin -f
for i in {1..2000}; do kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/500"; echo; done;
```

## RETRY

```bash
kubectl apply -f 3_retry.yaml
```

abbiamo rimosso il circuit breaker altrimenti nei log non vediamo le chiamate e aggiunto il retry

```bash
kubectl logs -l app=httpbin -f
```

vedremo che facendo una chiamata in 500 la chiamata rimarra in attesa e nei log vedremo continue chiamate al pod

```bash
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/500"
```

## FAULT INJECTION

se chiamo 201 il 50% delle volte mi risponde 500

```bash
kubectl apply -f 4_faultinjection.yaml 
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/201"
```

## DELAY

se chiamo 200 il 20% delle volte mi risponde con un ritardo di 5 secondi

```bash
kubectl apply -f 5_delay.yaml
kubectl exec sleep -- curl -s -o /dev/null -w "%{http_code}\n" "http://httpbin:8000/status/200"
```

