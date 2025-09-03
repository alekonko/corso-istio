# APPUNTI DEL CORSO ISTIO

## setup

```bash
git clone https://github.com/alessandroF-newesis/istio05.git
# poi lo forco
```

- setup su katacoda

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.0 sh -
export PATH=$HOME/istio-1.25.0/bin:$PATH
```

- installazione base

```bash
istioctl install --set profile=demo
```

## 
