# Canary 2 - da query parameters

Prereq: installazione gateway-api e istio ambient

```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || kubectl apply -f manifests/gateway-api-1.3.0-install.yaml
istioctl install --set profile=ambient --skip-confirmation
```

Preparo ns applicazione

```bash
ns=canary-test-pae
kubectl create namespace ${ns}
kubectl label namespace ${ns} istio-injection=enabled
kubectl config set-context --current --namespace=${ns}
```

applico manifest ed eseguo pod per eseguire test

```bash
kubectl apply -f 1_setupenv.yaml
kubectl run nginx --image=nginx
```

Non ho ancora mesh abilitato sul deployment perche non ho config (vs,dr). Test su app

```bash
kubectl exec -it nginx -- bash -c "for i in {1..20}; do curl http://version-service/; echo; done;"
```

Abilito canary release.

- 1. creo un virtual service e un destinationroule che mi predispongono l'applicazione per esser pilotata da istio

```bash
kubectl apply -f 2_canary_release.yaml
```
#se chiamo la mia applicazione mi risponde come prima
```bash
kubectl exec -it nginx -- bash -c "for i in {1..20}; do curl http://version-service/; echo; done;"
```

-2. a questo punto sviluppo la mia applicazione v2 e decido la logica da implementare per ruotare gli utenti sulla versione v2. in questo caso se in query string esiste link=promotionEx4MpL3  (nel vs uso match  queryParams  link=promotionEx4MpL3)


```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: version-routing
spec:
  hosts:
  - version-service
  http:
  - match:
    - queryParams:
        link:
          exact: promotionEx4MpL3
    route:
    - destination:
        host: version-service
        subset: v2
  - route:
    - destination:
        host: version-service
        subset: v1
```

```bash
kubectl apply -f 3_canary_release.yaml
kubectl apply -f 4_addapplication.yaml
```

-3. test

```bash
kubectl exec -it nginx -- bash
#questo andra sulla v1
for i in {1..20}; do curl http://version-service/; echo; done;
#questo andrà sulla v2
for i in {1..20}; do curl http://version-service/?link=promotionEx4MpL3; echo; done;
for i in {1..20}; do curl http://version-service/test.php?link=promotionEx4MpL3; echo; done;
for i in {1..20}; do curl http://version-service/test/test/test.html?link=promotionEx4MpL3; echo; done;
#mentre questo sulla v1
for i in {1..20}; do curl http://version-service/test.php?link=promotionEx4MpL; echo; done;  # attenzione non ho il 3 finale

```
