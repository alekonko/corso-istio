# Prova per canary su tre servizi su base header

Prereq: installazione gateway-api e istio ambient

```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || kubectl apply -f manifests/gateway-api-1.3.0-install.yaml
istioctl install --set profile=ambient --skip-confirmation
```

Preparo ns applicazione

```bash
ns=canary-test
kubectl create namespace ${ns}
kubectl label namespace ${ns} istio-injection=enabled
kubectl config set-context --current --namespace=${ns}
```

Setup app di esempio, 3 deployment name "v1,v2,v3" che rispondono in maniera differente (immagine hashicorp/http-echo con env var per risposta). unico svc che bilancia rr.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: version-service
spec:
  selector:
    app: version
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5678
```

virtualservice che fanno canary in base all'header (che passo poi da curl), chiamate sono in fatte sull'host comune "version-service"

- se header "free-subscription" inizia con "free" -> v1
- se header "beta: tester" (esatto)               -> v2
- altrimenti                                      -> v3

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: version-service
spec:
  host: version-service
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: version-routing
spec:
  hosts:
  - version-service
  http:
  - match:
    - headers:
        free-subscription:
          prefix: free
    route:
    - destination:
        host: version-service
        subset: v1
  - match:
    - headers:
        beta:
          exact: tester
    route:
    - destination:
        host: version-service
        subset: v2
  - route:
    - destination:
        host: version-service
        subset: v3
```

applico manifest ed eseguo pod per eseguire test

```bash
kubectl apply -f 1_setupenv.yaml
kubectl apply -f 2_canary_release.yaml
kubectl run nginx --image=nginx
```


## Demo

Chiamando il servizio version-service con i vari header ci risponderanno versioni diverse della nostra applicazione

```bash
kubectl exec -it nginx -- bash
for i in {1..20}; do curl -H "free-subscription: free" http://version-service/; echo; done;
for i in {1..20}; do curl -H "beta: tester" http://version-service/; echo; done;
for i in {1..20}; do curl http://version-service/; echo; done;
```
