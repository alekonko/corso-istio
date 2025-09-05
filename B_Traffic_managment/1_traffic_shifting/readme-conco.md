# INSTALLO BOOKINFO su cluster con istio ambient

## Prereq: installazione gateway-api e istio ambient

```bash
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || kubectl apply -f manifests/gateway-api-1.3.0-install.yaml
istioctl install --set profile=ambient --skip-confirmation
```

- installo bookinfo

```bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
kubectl apply -n bookinfo -f samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -n bookinfo -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl apply -n bookinfo -f samples/bookinfo/networking/destination-rule-all.yaml
kubectl apply -n bookinfo -f samples/bookinfo/platform/kube/bookinfo.yaml

kubectl wait deploy --all --for condition=available --timeout=400s
```

## App review

abbiamo una destination rule con 3 versioni di un applicazione e un virtual service che punta ad una sola versione

```bash
kubectl edit destinationrules reviews
kubectl edit virtualservices reviews 
```

#abbiamo poi 3 deployment con nome v1 v2 e v3

```bash
kubectl get deployment
```


**Per ambient devo usare gateway-api**

```bash
# kubectl apply -n bookinfo -f samples/bookinfo/networking/conco-istio-ambient.yaml
kubectl apply -n bookinfo -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml
```

Cambio i tipo di service in modo da poter far il forward

```bash
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=bookinfo
kubectl port-forward svc/bookinfo-gateway-istio 8080:80 -n bookinfo
```

Accedo con http://localhost:8080/productpage 

![alt text](bookinfo-ambient.png)



 
Aggiungiamo la v2 al 20% e la v1 all'80%

```bash
kubectl edit virtualservices reviews
```

```yaml
- route:
    - destination:
        host: reviews
        subset: v1
      weight: 80
    - destination:
        host: reviews
        subset: v2
      weight: 20
```

rifacciamo vedere dal browser che ogni tanto mi viene fuori la recensione con le stelline. incrementiamo a 80% e poi a 100%. alla fine possiamo anche togliere la v1 ed eventualmente fare la stessa cosa con la v3


