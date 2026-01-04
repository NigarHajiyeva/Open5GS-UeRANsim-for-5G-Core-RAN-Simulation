# Deploying Open5GS + UERANSIM on Kubernetes

This document describes a **containerized 5G core and RAN simulation** using **Open5GS** and **UERANSIM**, deployed on **Kubernetes (Minikube)**. The setup is intended for academic and research purposes, with a strong focus on **5G Authentication Mechanisms (5G-AKA)**.

Unlike a simple VM-based installation, this deployment follows **cloud-native principles**, where each Network Function (NF) runs as a Kubernetes pod.

---

## 1. Research Objective

The goal of this lab is to:

* Deploy a functional **5G Core Network (5GC)** on Kubernetes
* Simulate a **5G gNB and UE** using UERANSIM
* Observe and analyze the **5G-AKA authentication procedure**
* Capture and inspect authentication traffic using logs and packet analysis

---

## 2. System Requirements

* Host OS: Linux (Ubuntu 20.04 / 22.04 recommended)
* Virtualization: VMware / VirtualBox / Native Linux
* Minimum Resources:

  * 4 vCPUs
  * 8 GB RAM
  * 30 GB disk

---

## 3. Technology Stack

| Component             | Purpose                                |
| --------------------- | -------------------------------------- |
| Kubernetes (Minikube) | Container orchestration                |
| Docker                | Container runtime                      |
| Open5GS               | 5G Core Network (AMF, AUSF, UDM, etc.) |
| MongoDB               | Subscriber & policy database           |
| UERANSIM              | 5G gNB and UE simulator                |
| kubectl               | Kubernetes management CLI              |

---

## 4. Architecture Overview

```
UERANSIM UE ──► gNB (UERANSIM) ──► AMF ──► AUSF ──► UDM/UDR
                                   │
                                   └──► NRF / SMF / UPF
```

Authentication is handled primarily by:

* **AMF** – initiates authentication
* **AUSF** – performs 5G-AKA
* **UDM** – generates authentication vectors

---

## 5. Kubernetes Environment Setup

This section prepares a local Kubernetes cluster that will host all 5G core and RAN components as containers.

### Step 1: Install Docker

Docker is required as the container runtime used by Kubernetes to pull, build, and execute network function images.

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker --now
```

Enabling Docker at boot ensures that Kubernetes can always start its pods automatically after system reboot.

---

### Step 2: Install kubectl

`kubectl` is the command-line tool used to interact with the Kubernetes API server. It allows deployment, inspection, and debugging of pods and services.

```bash
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

---

### Step 3: Install Minikube

Minikube creates a single-node Kubernetes cluster locally, which is sufficient for lab-scale 5G core simulations.

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
```

Start the cluster:

```bash
minikube start --driver=docker --memory=8192 --cpus=4
```

The allocated memory and CPU ensure stable operation of multiple 5G core network functions running simultaneously.

Verify cluster status:

```bash
kubectl get nodes
```

---

### Step 2: Install kubectl

```bash
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

---

### Step 3: Install Minikube

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
```

Start the cluster:

```bash
minikube start --driver=docker --memory=8192 --cpus=4
```

Verify:

```bash
kubectl get nodes
```

---

## 6. Deploy Open5GS Core on Kubernetes

### Step 4: Clone Open5GS Kubernetes Manifests

```bash
git clone https://github.com/gradiant/open5gs-k8s.git
cd open5gs-k8s
```

This repository provides Kubernetes YAML files for:

* NRF, AMF, AUSF, UDM, UDR
* SMF, UPF
* MongoDB
* Open5GS WebUI

---

### Step 5: Deploy MongoDB

```bash
kubectl apply -f mongodb/
```

Verify:

```bash
kubectl get pods
```

MongoDB must be in **Running** state before continuing.

---

### Step 6: Deploy Core Network Functions

```bash
kubectl apply -f nrf/
kubectl apply -f amf/
kubectl apply -f ausf/
kubectl apply -f udm/
kubectl apply -f udr/
kubectl apply -f smf/
kubectl apply -f upf/
```

Verify all pods:

```bash
kubectl get pods
```

---

## 7. Open5GS WebUI and Subscriber Management

### Step 7: Deploy WebUI

```bash
kubectl apply -f webui/
```

Expose WebUI locally:

```bash
kubectl port-forward svc/webui 3000:3000
```

Access:

```
http://localhost:3000
```

Login:

* **admin / 1423**

---

### Step 8: Create a Subscriber (Authentication Data)

Fill in the following fields:

* **SUPI (IMSI)**: `imsi-001010000000001`
* **Key (K)**: `465B5CE8B199B49FAA5F0A2EE238A6BC`
* **OPc**: `E8ED289DEBA952E4283B54E88E6183CA`
* **AMF**: `8000`
* **Slice**: SST = 1, SD = 010203

This data is used directly during **5G-AKA authentication**.

---

## 8. Deploy UERANSIM on Kubernetes

### Step 9: Build UERANSIM Docker Image

```bash
git clone https://github.com/aligungr/UERANSIM.git
cd UERANSIM
docker build -t ueransim .
```

Load image into Minikube:

```bash
minikube image load ueransim
```

---

## 9. Configure gNB and UE

### Step 10: gNB Configuration (ConfigMap)

```yaml
mcc: '001'
mnc: '01'
gnbId: 0x000001
tac: 1

amfConfigs:
  - address: amf
    port: 38412

plmnSupportList:
  - plmn:
      mcc: '001'
      mnc: '01'
    sNssaiList:
      - sst: 1
        sd: '010203'
```

---

### Step 11: UE Configuration (Authentication Parameters)

```yaml
supi: 'imsi-001010000000001'
key: '465B5CE8B199B49FAA5F0A2EE238A6BC'
opc: 'E8ED289DEBA952E4283B54E88E6183CA'
amf: '8000'

mcc: '001'
mnc: '01'

slice:
  sst: 1
  sd: '010203'

gnbSearchList:
  - ueransim-gnb
```

---

## 10. Deploy gNB and UE Pods

Apply deployments:

```bash
kubectl apply -f gnb-deployment.yaml
kubectl apply -f ue-deployment.yaml
```

---

## 11. Authentication Verification

### Step 12: UE Logs

```bash
kubectl logs deployment/ueransim-ue
```

Expected output:

```
[5G-AKA] Authentication successful
```

---

### Step 13: AMF Logs

```bash
kubectl logs deployment/amf
```

You should observe:

* Registration Request
* Authentication Request/Response
* Security Mode Command

---

## 12. Detailed 5G-AKA Authentication Flow 

1. UE sends **SUCI** to AMF
2. AMF requests authentication from AUSF
3. AUSF retrieves credentials from UDM
4. UDM generates authentication vectors (RAND, AUTN, XRES*)
5. UE validates AUTN and computes RES*
6. AUSF compares RES* and XRES*
7. Security context is established

---

## 15. References

* Open5GS: [https://github.com/open5gs/open5gs](https://github.com/open5gs/open5gs)
* Open5GS K8s: [https://github.com/gradiant/open5gs-k8s](https://github.com/gradiant/open5gs-k8s)
* UERANSIM: [https://github.com/aligungr/UERANSIM](https://github.com/aligungr/UERANSIM)
* 3GPP TS 33.501 – 5G Security Architecture
