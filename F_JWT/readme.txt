#SETUP istio
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.1 sh -
export PATH="$PATH:/root/istio-1.25.1/bin"
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled

#deployare l'applicazione httpbin, l'ingressgateway e il virtualservice
kubectl apply -f 1_setupenv.yaml


#su killercoda faccio portforward e poi apro via browser la 8080
kubectl port-forward --address 0.0.0.0 -n istio-system svc/istio-ingressgateway 8080:80

#a questo punto voglio implementare il JWT authentication con auth0 quindi creo le risorse RequestAuthentication e authorizationPolicy
kubectl apply -f 2_jwt.yaml

#se rifaccio la chiamata mi dara un errore di RBAC perche non gli sto passando il token
#RBAC: access denied
#se passo un header Authorization Bearer XXXXXXX mi dira che il tocken non e nel formato corretto
curl -H "Authorization: Bearer XXXXX" https://XXXX.killercoda.com/
#Jwt is not in the form of Header.Payload.Signature with two dots and 3 sectionscontrolplane:~$ 

#quindi lato SERVER genero le varie autorizzazioni e identita con auth0 
#lato CLIENT genero il token e lo passo come header Authorization Bearer
curl --request POST \
  --url https://dev-srxcjo72n3try4vd.eu.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{
    "client_id":"QfNtdIBgXcfdcqZspVeiiwC7FLOviNuW",
    "client_secret":"ItW-HuEJZoUuDtZMaoZz5hssakdJUKhyNo-tvApTQ0rV_iL3qkmRJ2BKHp1tkAoS",
    "audience":"https://dev-srxcjo72n3try4vd.eu.auth0.com/api/v2/",
    "grant_type":"client_credentials"
  }'

#e poi faccio la chiamata con il token
curl -H "Authorization: Bearer XXXXX" https://XXXX.spch.r.killercoda.com/