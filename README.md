# APPUNTI DEL CORSO ISTIO

## setup

```bash
git clone https://github.com/alekonko/corso-istio.git
```

- setup su katacoda

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.25.0 sh -
export PATH=$HOME/istio-1.25.0/bin:$PATH
```

- setup minikube (check cpu e ram, ram minima 8gb)

```bash
minikube start -p istio-ambient --driver=podman --container-runtime=containerd --addons=[metric-server,auto-pause,ingress,logviewer,yakd,registry-creds] --insecure-registry "dislexlinux.local:5000,dislexlinux:5000,192.168.0.0/16,10.0.0.0/8" --registry-mirror="http://dislexlinux.local:5000,http://dislexlinux:5000"  --cpus=4 --memory=12288mb --kubernetes-version=1.33.1
```

- installazione base

```bash
istioctl install --set profile=demo --skip-confirmation
```

- installazione ambient


```bash
istioctl install --set profile=ambient --skip-confirmation
```

## COMANDI UTILI: istioctl proxy-status

- `istioctl proxy-status` fornisce una panoramica dello stato di sincronizzazione tra il piano di controllo di Istio (Istiod) e i vari proxy sidecar (Envoy) in esecuzione nei tuoi pod. Analizziamo i campi che hai fornito.

esempio (cluster minikube con ambient e sidecar installation)

```bash
NAME                                      CLUSTER        ISTIOD                      VERSION     SUBSCRIBED TYPES
test-556b4dcc6c-9n84g.default             Kubernetes     istiod-796c54b8bb-9dsjw     1.27.0      4 (CDS,LDS,EDS,RDS)
test-sidecar-6f46c69d85-bj5h6.default     Kubernetes     istiod-796c54b8bb-9dsjw     1.27.0      5 (CDS,LDS,EDS,RDS,WDS)
ztunnel-ldkz6.istio-system                Kubernetes     istiod-796c54b8bb-9dsjw     1.27.0      2 (WADS,WDS)
```

### 1. `NAME`
Questo campo identifica in modo univoco il **proxy sidecar** di cui si sta visualizzando lo stato. Il formato è `<nome-pod>.<namespace>`. Ad esempio, `test-556b4dcc6c-9n84g.default` indica il proxy all'interno del pod chiamato `test-556b4dcc6c-9n84g` nel namespace `default`.

---

### 2. `CLUSTER`
Questo campo indica il cluster Kubernetes a cui appartiene il proxy. Nel tuo caso, il valore è sempre `Kubernetes`, a meno che tu non stia usando una configurazione multi-cluster avanzata.

---

### 3. `ISTIOD`
Questo è l'identificativo del **pod Istiod** a cui il proxy si è connesso per ricevere la sua configurazione. Nel tuo output, `istiod-796c54b8bb-9dsjw` mostra che entrambi i proxy stanno ricevendo la configurazione dallo stesso pod del piano di controllo.

---

### 4. `VERSION`
Questo campo mostra la **versione di Istio** del proxy. La versione 1.27.0 indica che i tuoi proxy sono aggiornati e compatibili con il piano di controllo.

---

### 5. `SUBSCRIBED TYPES`
Questo è il campo più importante. Mostra i tipi di configurazione che il proxy sta ricevendo dal piano di controllo tramite il protocollo **xDS (Discovery Service)**. I numeri tra parentesi indicano quanti tipi di risorse sono stati sincronizzati. Ecco i principali:

* **`CDS` (Cluster Discovery Service)**: Contiene informazioni sui cluster di destinazione. Un cluster è un gruppo di endpoint di rete a cui il proxy può inviare il traffico.
* **`LDS` (Listener Discovery Service)**: Descrive i listener del proxy, ovvero le porte e i protocolli su cui il proxy accetta il traffico in entrata.
* **`EDS` (Endpoint Discovery Service)**: Fornisce l'elenco degli endpoint effettivi (indirizzi IP e porte) per ogni cluster, consentendo al proxy di sapere dove inviare il traffico.
* **`RDS` (Route Discovery Service)**: Contiene le regole di routing che mappano le richieste in entrata (da un listener) a un cluster di destinazione.

Nel tuo output, la riga `test-556b4dcc6c-9n84g.default` mostra che il proxy ha sincronizzato tutti i tipi di configurazione principali per la gestione del traffico.

La riga `ztunnel-ldkz6.istio-system` mostra un caso particolare. `ztunnel` è il componente di Istio che si occupa del traffico mTLS (mutual TLS) a livello di rete, noto anche come Istio Ambient Mesh. I tipi `WADS` (Waypoint Agent Discovery Service) e `WDS` (Waypoint Discovery Service) sono specifici di questa architettura e indicano che il `ztunnel` sta sincronizzando la configurazione relativa a un **waypoint proxy**, un concetto chiave della modalità Ambient Mesh.
