# JWT Policy

## Prereq: installazione minikube sidecar

Script installazione automatico, io skippo primo pezzo, uso 1.27.1

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.1 sh -
export PATH="$PATH:/root/istio-1.25.1/bin"
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
```

deployare l'applicazione httpbin, l'ingressgateway e il virtualservice

```bash
kubectl apply -f 1_setupenv.yaml
```

per minikube

```bash
kubectl patch svc istio-ingressgateway -n istio-system \
  -p '{
    "spec": {
      "type": "NodePort",
      "ports": [
        {"port":80,"targetPort":8080,"nodePort":32080,"protocol":"TCP","name":"http2"},
        {"port":443,"targetPort":8443,"nodePort":32443,"protocol":"TCP","name":"https"}
      ]
    }
  }'


myip=$(minikube -p istio ip)
ingressgw_ip=$(minikube -p istio ip)
```

per entrare dal ingressgw (con nodeport)

```bash
curl -H "Authorization: Bearer XXXXX"  http://${ingressgw_ip}:32080
```

per entrare dal ingressgw (con portforward),

```bash
kubectl port-forward -n istio-system --address 0.0.0.0 service/istio-ingressgateway 1234:80
```

```bash
curl -H "Authorization: Bearer XXXXX"  http://localhost:1234
```

# test per ingressgw su minikube, ok entro

#a questo punto voglio implementare il JWT authentication con auth0 quindi creo le risorse RequestAuthentication e authorizationPolicy
kubectl apply -f 2_jwt.yaml

#se rifaccio la chiamata mi dara un errore di RBAC perche non gli sto passando il token
#RBAC: access denied
#se passo un header Authorization Bearer XXXXXXX mi dira che il tocken non e nel formato corretto

curl -H "Authorization: Bearer XXXXX"  http://${ingressgw_ip}:32080

#Jwt is not in the form of Header.Payload.Signature with two dots and 3 sectionscontrolplane:~$ 

#quindi lato SERVER genero le varie autorizzazioni e identita con auth0 
#lato CLIENT genero il token e lo passo come header Authorization Bearer
echo " "
echo "### genero jwt"
echo " "
echo " "
# jwt_currrent=$(curl --request POST \
#   --url https://dev-srxcjo72n3try4vd.eu.auth0.com/oauth/token \
#   --header 'content-type: application/json' \
#   --data '{
#     "client_id":"QfNtdIBgXcfdcqZspVeiiwC7FLOviNuW",
#     "client_secret":"ItW-HuEJZoUuDtZMaoZz5hssakdJUKhyNo-tvApTQ0rV_iL3qkmRJ2BKHp1tkAoS",
#     "audience":"https://dev-srxcjo72n3try4vd.eu.auth0.com/api/v2/",
#     "grant_type":"client_credentials"
#   }')

jwt_currrent=$(curl --request POST \
  --url https://dev-rzkchlfkzqyo3c07.us.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id":"xxxxxxxxxxxx",
    "client_secret":"xxxxxxxxxxxxxxxxxxx",
    "audience":"http://my-api/",
    "grant_type":"client_credentials"
  }')

token_type=$(echo "$jwt_currrent" | jq -r '.token_type')
access_token=$(echo "$jwt_currrent" | jq -r '.access_token')

echo jwt_current  : $jwt_currrent
echo access_token : $access_token
echo token_type   : $token_type
echo " "
echo " "
echo " "
echo curl -H "\"Authorization: $token_type $access_token\"" "http://${ingressgw_ip}:32080"
curl -H "Authorization: $token_type $access_token" "http://${ingressgw_ip}:32080"
echo ""
#fallisce !!  faccio debug



estraggo i proxy envoy

```bash
istioctl proxy-status
```bash

```bash
NAME                                                  CLUSTER        ISTIOD                      VERSION     SUBSCRIBED TYPES
booking-service-7488546889-jl6sx.foo                  Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
details-v1-766844796b-5z6bk.bookinfo                  Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
httpbin-74866dc9d9-l5xgw.default                      Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
istio-egressgateway-74bbd4975d-rgrgl.istio-system     Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      3 (CDS,LDS,EDS)
istio-ingressgateway-b6cd68585-9nc94.istio-system     Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
nginx.observabilty-app                                Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
notification-service-v1-6dcf5fb99d-4848p.bar          Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
notification-service-v1-6dcf5fb99d-gbp25.foo          Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
productpage-v1-54bb874995-qpjb2.bookinfo              Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
ratings-v1-5dc79b6bcd-4qj8z.bookinfo                  Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
reviews-v1-598b896c9d-btfxl.bookinfo                  Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
reviews-v2-556d6457d-44plz.bookinfo                   Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
reviews-v3-564544b4d6-7557t.bookinfo                  Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
test-94d888b5b-wsxld.default                          Kubernetes     istiod-7d4f74889d-cf8mm     1.27.0      4 (CDS,LDS,EDS,RDS)
tester.default                                        Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
tester.foo                                            Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
v1-9dc6cdcd7-glbfm.observabilty-app                   Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
v2-574d47ffff-nklrv.observabilty-app                  Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
v3-fb844b9f-mbhpq.observabilty-app                    Kubernetes     istiod-7d4f74889d-cf8mm     1.27.1      4 (CDS,LDS,EDS,RDS)
```

Con "istioctl experimental authz check pod.ns"  recupero le AuthPolicy

```bash
istioctl experimental authz check httpbin-74866dc9d9-l5xgw.default
ACTION   AuthorizationPolicy         RULES
ALLOW    _anonymous_match_nothing_   1
ALLOW    require-jwt.default         1
```



#alzo debug log envoy

kubectl exec -it httpbin-74866dc9d9-l5xgw -c istio-proxy -- curl -X POST localhost:15000/logging?level=debug


echo "$access_token" | cut -d. -f2 | base64 -d | jq

```json
{
  "iss": "https://dev-srxcjo72n3try4vd.eu.auth0.com/",
  "sub": "QfNtdIBgXcfdcqZspVeiiwC7FLOviNuW@clients",
  "aud": "https://dev-srxcjo72n3try4vd.eu.auth0.com/api/v2/",
  "iat": 1757500635,
  "exp": 1757587035,
  "scope": "read:clients",
  "gty": "client-credentials",
  "azp": "QfNtdIBgXcfdcqZspVeiiwC7FLOviNuW"
}
```

da 2_jwt.yaml

```yaml
jwtRules:
- issuer: "https://dev-srxcjo72n3try4vd.eu.auth0.com/"
  jwksUri: "https://dev-srxcjo72n3try4vd.eu.auth0.com/.well-known/jwks.json"
```

- ISS uguali




curl --request POST \
  --url https://dev-rzkchlfkzqyo3c07.us.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id":"osYXqm68uyx5Ql4YSX8V3TQjA2Gcr3SV",
    "client_secret":"zM_SDLRFk-QELRMY69rdyKsfZYHEGKZ9TyqrPqgDm1U4ZNX02NIqtlJZBpCC5mrZ",
    "audience":"http://my-api/",
    "grant_type":"client_credentials"
  }'
