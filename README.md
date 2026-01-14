# Open5GS 5G Core Network Helm Chart Deployment Guide

A production-ready Helm chart for deploying Open5GS 5G Core Network and UERANSIM on Kubernetes.

```bash
┌──────────────────────────────────────────────────────────────┐
│                     Kind Cluster (kind-5gs)                  │
│                                                              │
│  ┌────────────┐                                              │
│  │  UERANSIM  │                                              │
│  │  ┌──────┐  │         ┌──────────────────────┐             │
│  │  │  UE  │  │ ◄─────► │   AMF (Access &      │             │
│  │  └──────┘  │  N1/N2  │   Mobility Mgmt)     │             │
│  │  ┌──────┐  │         └──────────────────────┘             │
│  │  │ gNB  │  │                    │                         │
│  │  └──────┘  │                    │ SBI                     │
│  └────────────┘         ┌──────────┴──────────┐              │
│         │               │                     │              │
│         │ GTP-U         ▼                     ▼              │
│         │      ┌─────────────┐       ┌─────────────┐         │
│         │      │    AUSF     │       │    UDM      │         │
│         │      │   (Auth)    │       │   (User     │         │
│         │      └─────────────┘       │    Data)    │         │
│         │              │             └─────────────┘         │
│         │              │                     │               │
│         ▼              ▼                     ▼               │
│  ┌──────────┐   ┌──────────────────────────────┐             │
│  │   UPF    │   │         NRF (Discovery)      │             │
│  │  (User   │   └──────────────────────────────┘             │
│  │  Plane)  │                  │                             │
│  └──────────┘                  │                             │
│       ▲                        ▼                             │
│       │ PFCP          ┌─────────────┐                        │
│       │               │     SMF     │                        │
│       └───────────────│  (Session   │                        │
│                       │    Mgmt)    │                        │
│                       └─────────────┘                        │
│                              │                               │
│          ┌───────────────────┼───────────────────┐           │
│          ▼                   ▼                   ▼           │
│    ┌─────────┐         ┌─────────┐        ┌─────────┐        │
│    │   PCF   │         │  NSSF   │        │   BSF   │        │
│    │(Policy) │         │ (Slice) │        │(Binding)│        │
│    └─────────┘         └─────────┘        └─────────┘        │
│                                                              │
│    ┌─────────┐         ┌─────────┐                           │
│    │   UDR   │         │ MongoDB │                           │
│    │  (Data  │ ◄─────► │  (Sub-  │                           │
│    │   Repo) │         │ scriber)│                           │
│    └─────────┘         └─────────┘                           │
│                                                              │
│    ┌─────────────────────────────┐                           │
│    │       WebUI (Port 30999)    │                           │
│    └─────────────────────────────┘                           │
└──────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes 1.19+ (verified with Kind v0.22+)
- Helm 3.0+
- kind (for local deployment) or any Kubernetes cluster
- Docker images built and loaded:
  - `local/open5gs:latest`
  - `local/open5gs-webui:latest`
  - `local/ueransim:latest`
- MongoDB tools: mongosh for subscriber management
- Basic tools: curl, git, sudo access on Ubuntu VM
- Recommended: Wireshark/tcpdump for packet analysis

## 1. Install Prerequisites

Ensure the following tools are installed. If not, install them as shown below.

## Docker
Container runtime.

```bash
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER  # Log out and back in after this
```

## kind
For creating a local Kubernetes cluster.

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64  # Adjust for your arch/OS
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## kubectl
Kubernetes CLI (match your kind/Kubernetes version, e.g., v1.28).

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  # Adjust for arch
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

## Git
For cloning repositories.

```bash
sudo apt install git -y
```

## Other
Node.js v18 (required for WebUI build, if building manually).

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

## Clone the Required Repositories
The demo repository does not include Open5GS or UERANSIM source code. These must be cloned separately into the same parent directory.

```bash
mkdir 5gs-demo-setup && cd 5gs-demo-setup
```

## Clone the Demo Repository
```bash
https://github.com/NigarHajiyeva/Open5GS-UeRANsim-for-5G-Core-RAN-Simulation.git
cd Open5GS-UeRANsim-for-5G-Core-RAN-Simulation

```

## Clone Open5GS Source
```bash
git clone https://github.com/open5gs/open5gs
cd open5gs
git checkout v2.7.6-128-g6489de3
cd ..
```

## Clone UERANSIM Source
```bash
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
git checkout v3.2.7
cd ..
```

## Directory Structure

Your directory structure should now look like this:
```bash
5gs-demo-setup/
├── Open5GS-UeRANsim-for-5G-Core-RAN-Simulation   # The demo repo
            ├── open5gs/    # Open5GS source
            └── UERANSIM/   # UERANSIM source
```

## Enter the Demo Repository
```bash
cd Open5GS-UeRANsim-for-5G-Core-RAN-Simulation
```

## Quick Start

### 1. Create Kind Cluster (for local deployment)

```bash
kind create cluster --config kind-5gs.yaml --name kind-5gs
```



## !! IMPORTANT
Build and Deploy (Automated Script)
The repo provides build-and-deploy.sh for a one-shot setup. This builds Docker images for Open5GS, UERANSIM, and WebUI (takes 10-20 minutes on first run due to compiling from source), loads them into kind, deploys all Kubernetes resources.
```bash
./build-and-deploy.sh
```
If you encounter issues (e.g., build failures), do manual deployment.

## Verify Dpeloyment
```bash
kubectl get pods -n default  # All should be Running
kubectl get svc -n default   # Check services like webui (NodePort 30999)
```

## Manual Deployment (If Automated Script Fails or for Customization)
### 2. Build and Load Docker Images
```bash
# From repository root
docker build -t local/open5gs:latest -f Dockerfile.open5gs .
docker build -t local/ueransim:latest -f Dockerfile.ueransim .
docker build -t local/open5gs-webui:latest -f Dockerfile.webui .

# Load images into kind cluster
kind load docker-image local/open5gs:latest --name kind-5gs
kind load docker-image local/ueransim:latest --name kind-5gs
kind load docker-image local/open5gs-webui:latest --name kind-5gs
```

### 3. Install the Chart

```bash
# Install with default values
helm install open5gs-5g ./helm/open5gs-5g --namespace open5gs --create-namespace

# Watch deployment progress
kubectl get pods -n open5gs -w
```

### 4. Post-Installation Setup

#### Create WebUI Admin Account

```bash
kubectl exec -n open5gs deployment/webui -- sh -c "cat > /webui/create-admin.js << 'EOF'
const mongoose = require('mongoose');
const Account = require('./server/models/account');

const DB_URI = process.env.DB_URI || 'mongodb://mongodb:27017/open5gs';

mongoose.connect(DB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  useCreateIndex: true
});

mongoose.connection.on('connected', async () => {
  console.log('Connected to MongoDB');

  try {
    await Account.deleteMany({ username: 'admin' });
    console.log('Deleted existing admin accounts');

    const account = new Account({
      username: 'admin',
      roles: ['admin']
    });

    await Account.register(account, '1423');
    console.log('Admin account created successfully!');
    console.log('Username: admin');
    console.log('Password: 1423');

    process.exit(0);
  } catch (err) {
    console.error('Error creating admin account:', err);
    process.exit(1);
  }
});

mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err);
  process.exit(1);
});
EOF
cd /webui && node create-admin.js"
```

#### Provision Subscriber

```bash
kubectl exec -n open5gs deployment/mongodb -- mongosh open5gs --quiet --eval '
db.subscribers.insertOne({
  "imsi": "999700000000001",
  "msisdn": ["0000000001"],
  "imeisv": "8140000000000001",
  "mme_host": [],
  "mme_realm": [],
  "purge_flag": [],
  "security": {
    "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
    "amf": "8000",
    "op": null,
    "opc": "E8ED289DEBA952E4283B54E88E6183CA",
    "sqn": NumberLong(0)
  },
  "ambr": {
    "downlink": { "value": 1, "unit": 3 },
    "uplink": { "value": 1, "unit": 3 }
  },
  "slice": [
    {
      "sst": 1,
      "default_indicator": true,
      "session": [
        {
          "name": "internet",
          "type": 3,
          "pcc_rule": [],
          "ambr": {
            "downlink": { "value": 1, "unit": 3 },
            "uplink": { "value": 1, "unit": 3 }
          },
          "qos": {
            "index": 9,
            "arp": {
              "priority_level": 8,
              "pre_emption_capability": 1,
              "pre_emption_vulnerability": 1
            }
          }
        }
      ]
    }
  ],
  "access_restriction_data": 32,
  "subscriber_status": 0,
  "network_access_mode": 0,
  "subscribed_rau_tau_timer": 12,
  "__v": 0
})
'
```

### 5. Verify Installation

```bash
# Check all pods are running (expected: 14/14)
kubectl get pods -n open5gs

# Check UE registration
kubectl logs -n open5gs deployment/ueransim-gnb -c ue --tail=50 | grep -E "(Registration|PDU Session)"
```

Expected output:
```
[nas] [info] Initial Registration is successful
[nas] [info] PDU Session establishment is successful PSI[1]
[app] [info] Connection setup for PDU session[1] is successful, TUN interface[uesimtun0, 10.45.0.X] is up.
```

## Testing Connectivity

### Test Internet Access from UE

```bash
# Get the current UERANSIM pod name
UE_POD=$(kubectl get pods -n open5gs -l app=ueransim-gnb -o jsonpath='{.items[0].metadata.name}')

# Ping Google DNS
kubectl exec -n open5gs $UE_POD -c ue -- ping -c 4 8.8.8.8

# Ping Cloudflare DNS
kubectl exec -n open5gs $UE_POD -c ue -- ping -c 4 1.1.1.1

# Test DNS resolution and connectivity
kubectl exec -n open5gs $UE_POD -c ue -- ping -c 5 google.com
```

Expected: All pings should succeed with ~10-50ms latency.

### Verify UE IP Address

```bash
kubectl exec -n open5gs $UE_POD -c ue -- ip addr show uesimtun0
```

Expected: IP address from 10.45.0.0/16 subnet (e.g., 10.45.0.2, 10.45.0.3, etc.)

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Kubernetes namespace | `open5gs` |
| `global.imagePullPolicy` | Image pull policy | `Never` |

### Network Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `network.plmn.mcc` | Mobile Country Code | `999` |
| `network.plmn.mnc` | Mobile Network Code | `70` |
| `network.tac` | Tracking Area Code | `1` |
| `network.ueSubnet` | UE IP subnet | `10.45.0.0/16` |
| `network.gateway` | Gateway IP | `10.45.0.1` |
| `network.dns.primary` | Primary DNS server | `8.8.8.8` |
| `network.dns.secondary` | Secondary DNS server | `8.8.4.4` |
| `network.mtu` | MTU size | `1400` |

### Subscriber Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `subscriber.imsi` | IMSI | `999700000000001` |
| `subscriber.key` | K (authentication key) | `465B5CE8B199B49FAA5F0A2EE238A6BC` |
| `subscriber.opc` | OPc (operator variant key) | `E8ED289DEBA952E4283B54E88E6183CA` |
| `subscriber.dnn` | Data Network Name | `internet` |

### WebUI Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `webui.enabled` | Enable WebUI | `true` |
| `webui.service.type` | Service type | `NodePort` |
| `webui.service.nodePort` | NodePort | `30999` |

### Open5GS Network Functions

Each network function can be configured with:
- `enabled`: Enable/disable the NF
- `replicas`: Number of replicas
- `resources`: Resource requests and limits

Example:
```yaml
open5gs:
  amf:
    enabled: true
    replicas: 1
    resources:
      requests:
        memory: "256Mi"
        cpu: "200m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

Supported NFs:
- `nrf` - Network Repository Function
- `scp` - Service Communication Proxy
- `ausf` - Authentication Server Function
- `udm` - Unified Data Management
- `udr` - Unified Data Repository
- `pcf` - Policy Control Function
- `nssf` - Network Slice Selection Function
- `bsf` - Binding Support Function
- `amf` - Access and Mobility Management Function
- `smf` - Session Management Function
- `upf` - User Plane Function

### UERANSIM Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ueransim.enabled` | Enable UERANSIM | `true` |
| `ueransim.gnb.replicas` | Number of gNB instances | `1` |
| `ueransim.ue.enabled` | Enable UE simulator | `true` |
| `ueransim.ue.delay` | Seconds to wait before UE starts | `15` |

## Deployed Components

After successful installation, you'll have:

| Component | Pods | Status |
|-----------|------|--------|
| MongoDB | 1 | Subscriber database |
| NRF | 1 | Service discovery |
| SCP | 1 | Service communication proxy |
| AUSF | 1 | Authentication |
| UDM | 1 | User data management |
| UDR | 1 | User data repository |
| PCF | 1 | Policy control |
| NSSF | 1 | Network slice selection |
| BSF | 1 | Binding support |
| AMF | 1 | Access & mobility management |
| SMF | 1 | Session management |
| UPF | 1 | User plane function |
| WebUI | 1 | Web interface |
| UERANSIM | 1 (2 containers) | gNB + UE simulator |
| **Total** | **14 pods** | **All Running** |

## Access Points

After installation:

- **WebUI**: `http://localhost:30999`
  - Username: `admin`
  - Password: `1423`
  - Manage subscribers, view sessions, configure policies

- **AMF NGAP**: NodePort `30412` (SCTP) - was `38412`, adjusted for valid NodePort range
- **UPF GTPU**: NodePort `30152` (UDP) - was `2152`, adjusted for valid NodePort range
- **UPF PFCP**: NodePort `30805` (UDP) - was `8805`, adjusted for valid NodePort range

## What Works

### ✅ Fully Functional

- **Control Plane**:
  - UE Registration and Authentication (AUSF/UDM/UDR)
  - PDU Session Establishment
  - Service-based Interface (SBI) communication
  - Network Function discovery via NRF
  - Policy management (PCF)
  - Network slicing (NSSF)

- **User Plane**:
  - GTP-U tunnel establishment
  - PFCP session management (SMF ↔ UPF)
  - UE IP address allocation (10.45.0.0/16)
  - NAT/MASQUERADE for internet access
  - **Full internet connectivity from UE** ✅
  - DNS resolution (8.8.8.8, 8.8.4.4)

- **Management**:
  - WebUI subscriber management
  - MongoDB subscriber database
  - Session monitoring

### Verified Tests

```bash
# All these tests pass successfully:
✅ ping 8.8.8.8           # Google DNS
✅ ping 1.1.1.1           # Cloudflare DNS
✅ ping google.com        # DNS resolution + connectivity
✅ curl http://example.com # HTTP traffic (if curl available)
```

## Examples

### Custom Network Configuration

```yaml
# custom-values.yaml
network:
  plmn:
    mcc: "001"
    mnc: "01"
  tac: 7
  ueSubnet: "10.60.0.0/16"

subscriber:
  imsi: "001010000000001"
  key: "your-authentication-key"
  opc: "your-operator-key"
```

Deploy:
```bash
helm install my-5g ./helm/open5gs-5g -f custom-values.yaml --namespace open5gs --create-namespace
```

### Disable UERANSIM

```yaml
# values-no-ueransim.yaml
ueransim:
  enabled: false
```

### Scale Network Functions

```yaml
# values-ha.yaml
open5gs:
  amf:
    replicas: 2
  smf:
    replicas: 2
  upf:
    replicas: 3
```

### Production Resources

```yaml
# values-production.yaml
open5gs:
  amf:
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
  smf:
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
  upf:
    resources:
      requests:
        memory: "1Gi"
        cpu: "1000m"
      limits:
        memory: "2Gi"
        cpu: "2000m"
```

## Upgrade

```bash
# Upgrade with new values
helm upgrade open5gs-5g ./helm/open5gs-5g -f new-values.yaml --namespace open5gs

# Upgrade and wait for readiness
helm upgrade open5gs-5g ./helm/open5gs-5g --wait --timeout 10m --namespace open5gs

# Rollback if needed
helm rollback open5gs-5g --namespace open5gs
```

## Uninstall

```bash
# Uninstall the release
helm uninstall open5gs-5g --namespace open5gs

# Delete namespace
kubectl delete namespace open5gs
```

## Troubleshooting

### Check Helm Release Status

```bash
helm status open5gs-5g --namespace open5gs
helm get values open5gs-5g --namespace open5gs
helm get manifest open5gs-5g --namespace open5gs
```

### Common Issues and Solutions

#### 1. UE Registration Fails with "Cannot find SUCI"

**Cause**: Subscriber not in database or wrong credentials.

**Solution**:
```bash
# Check if subscriber exists
kubectl exec -n open5gs deployment/mongodb -- mongosh open5gs --quiet --eval "db.subscribers.find().pretty()"

# If missing, provision subscriber (see Post-Installation Setup above)
```

#### 2. PDU Session Fails with "Invalid API name"

**Cause**: Network functions not advertising with FQDN.

**Solution**: This is already fixed in the Helm chart. All NFs use FQDN advertise addresses:
```yaml
sbi:
  server:
    - address: 0.0.0.0
      port: 7777
      advertise: <nf-name>.open5gs.svc.cluster.local
```

Verify by checking NRF logs:
```bash
kubectl logs -n open5gs deployment/nrf --tail=50 | grep -i registered
```

#### 3. UPF Session Fails with "No suitable UPF found"

**Cause**: PFCP association not established between SMF and UPF.

**Solution**: Restart SMF and UPF:
```bash
kubectl rollout restart deployment/smf deployment/upf -n open5gs
sleep 15
kubectl rollout restart deployment/ueransim-gnb -n open5gs
```

#### 4. WebUI Login Fails

**Cause**: Admin account not created.

**Solution**: Run the admin account creation script from Post-Installation Setup section above.

#### 5. Pods CrashLoopBackOff

**Check specific pod logs**:
```bash
kubectl get pods -n open5gs
kubectl logs -n open5gs <pod-name> --tail=100
kubectl describe pod -n open5gs <pod-name>
```

Common causes:
- Image not loaded (for kind): `kind load docker-image <image> --name kind-5gs`
- ConfigMap errors: Check YAML syntax in ConfigMaps
- Resource limits: Increase limits or ensure cluster has enough resources

### Debugging Commands

```bash
# Check all pods
kubectl get pods -n open5gs

# Check services
kubectl get svc -n open5gs

# Check ConfigMaps
kubectl get configmaps -n open5gs

# View UE logs
kubectl logs -n open5gs deployment/ueransim-gnb -c ue --tail=100

# View gNB logs
kubectl logs -n open5gs deployment/ueransim-gnb -c gnb --tail=100

# View AMF logs
kubectl logs -n open5gs deployment/amf --tail=100

# View SMF logs
kubectl logs -n open5gs deployment/smf --tail=100

# View UPF logs
kubectl logs -n open5gs deployment/upf --tail=100

# Check NRF registrations
kubectl logs -n open5gs deployment/nrf --tail=100

# Check MongoDB subscribers
kubectl exec -n open5gs deployment/mongodb -- mongosh open5gs --quiet --eval "db.subscribers.find().pretty()"

# Check MongoDB accounts
kubectl exec -n open5gs deployment/mongodb -- mongosh open5gs --quiet --eval "db.accounts.find().pretty()"
```

## Helm Testing

```bash
# Dry run to see generated manifests
helm install open5gs-5g ./helm/open5gs-5g --dry-run --debug --namespace open5gs

# Template without installing
helm template open5gs-5g ./helm/open5gs-5g --namespace open5gs > rendered.yaml

# Lint the chart
helm lint ./helm/open5gs-5g
```

## Chart Development

### Directory Structure

```
helm/open5gs-5g/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── README.md               # This file
├── templates/              # Kubernetes manifests templates
│   ├── _helpers.tpl        # Template helpers
│   ├── namespace.yaml      # Namespace
│   ├── open5gs/            # Open5GS NF templates
│   │   ├── *-configmap.yaml    # NF configurations
│   │   ├── *.yaml              # NF deployments
│   │   └── webui.yaml          # WebUI deployment
│   └── ueransim/           # UERANSIM templates
│       ├── *-configmap.yaml    # UERANSIM configs
│       └── gnb-ue.yaml         # gNB+UE deployment
└── charts/                 # Dependency charts (if any)
```

### Package the Chart

```bash
# Package for distribution
helm package ./helm/open5gs-5g

# Creates: open5gs-5g-1.0.0.tgz
```

### Publish to Repository

```bash
# Generate index
helm repo index .

# Upload to chart repository
# (your specific repository instructions)
```

## Technical Details

### FQDN Service Discovery

All network functions use Kubernetes FQDN for service advertisement:
- Format: `<service-name>.open5gs.svc.cluster.local`
- Ensures proper discovery in dynamic pod IP environment
- NRF maintains registry of all NF instances

### PFCP Association

SMF and UPF establish PFCP association automatically:
- SMF advertises: `smf.open5gs.svc.cluster.local`
- UPF connects to: `smf.open5gs.svc.cluster.local:8805`
- Session establishment happens on successful association

### UPF NAT Configuration

The UPF automatically configures NAT for UE internet access:
```bash
# Entrypoint script adds gateway IP to ogstun
ip addr add 10.45.0.1/16 dev ogstun
ip link set ogstun up

# Configure NAT for UE subnet
iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
```

### UERANSIM Pod Design

The gNB and UE run in the **same pod** with two containers:
- Container 1: `gnb` - Simulates 5G base station
- Container 2: `ue` - Simulates 5G user equipment
- Shared network namespace allows localhost communication
- UE connects to gNB via 127.0.0.1

## Version Information

- **Open5GS**: v2.7.6-128-g6489de3
- **UERANSIM**: v3.2.7
- **Kubernetes**: v1.28+ (via kind)
- **Helm**: v3.0+
- **MongoDB**: Latest from Docker Hub
- **Node.js**: 18 (for WebUI)


## References

- [Open5GS Documentation](https://open5gs.org)
- [UERANSIM GitHub](https://github.com/aligungr/UERANSIM)
- [Helm Documentation](https://helm.sh/docs/)
- [3GPP 5G Specifications](https://www.3gpp.org)

---

**Status**: ✅ Fully Functional - UE Registration, PDU Session, Internet Connectivity All Working



