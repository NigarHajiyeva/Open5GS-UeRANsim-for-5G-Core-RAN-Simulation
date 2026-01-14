#!/bin/bash

set -e

echo "=================================================="
echo "Open5GS + UERANSIM Kubernetes Deployment Script"
echo "=================================================="

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}No Kubernetes cluster is running. Please start your cluster first.${NC}"
    echo "You can use one of the following:"
    echo "  - minikube start"
    echo "  - kind create cluster"
    echo "  - k3d cluster create"
    exit 1
fi

echo -e "${GREEN}Step 1: Creating namespace${NC}"
kubectl create namespace open5gs --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Step 2: Deploying MongoDB${NC}"
kubectl apply -f k8s/open5gs/mongodb.yaml

echo -e "${YELLOW}Waiting for MongoDB to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/mongodb -n open5gs

echo -e "${GREEN}Step 3: Deploying Open5GS WebUI${NC}"
kubectl apply -f k8s/open5gs/webui.yaml

echo -e "${GREEN}Step 4: Deploying Open5GS ConfigMaps${NC}"
kubectl apply -f k8s/open5gs/configmap-nrf.yaml
kubectl apply -f k8s/open5gs/configmap-scp.yaml
kubectl apply -f k8s/open5gs/configmap-ausf.yaml
kubectl apply -f k8s/open5gs/configmap-udm.yaml
kubectl apply -f k8s/open5gs/configmap-udr.yaml
kubectl apply -f k8s/open5gs/configmap-pcf.yaml
kubectl apply -f k8s/open5gs/configmap-nssf.yaml
kubectl apply -f k8s/open5gs/configmap-bsf.yaml
kubectl apply -f k8s/open5gs/configmap-amf.yaml
kubectl apply -f k8s/open5gs/configmap-smf.yaml
kubectl apply -f k8s/open5gs/configmap-upf.yaml

echo -e "${GREEN}Step 5: Deploying Open5GS Network Functions (NRF first)${NC}"
kubectl apply -f k8s/open5gs/nrf.yaml

echo -e "${YELLOW}Waiting for NRF to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/nrf -n open5gs

echo -e "${GREEN}Step 6: Deploying SCP${NC}"
kubectl apply -f k8s/open5gs/scp.yaml

echo -e "${YELLOW}Waiting for SCP to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/scp -n open5gs

echo -e "${GREEN}Step 7: Deploying remaining control plane functions${NC}"
kubectl apply -f k8s/open5gs/ausf.yaml
kubectl apply -f k8s/open5gs/udm.yaml
kubectl apply -f k8s/open5gs/udr.yaml
kubectl apply -f k8s/open5gs/pcf.yaml
kubectl apply -f k8s/open5gs/nssf.yaml
kubectl apply -f k8s/open5gs/bsf.yaml

echo -e "${YELLOW}Waiting for control plane functions to be ready...${NC}"
sleep 10

echo -e "${GREEN}Step 8: Deploying AMF, SMF, and UPF${NC}"
kubectl apply -f k8s/open5gs/amf.yaml
kubectl apply -f k8s/open5gs/smf.yaml
kubectl apply -f k8s/open5gs/upf.yaml

echo -e "${YELLOW}Waiting for AMF, SMF, and UPF to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/amf -n open5gs
kubectl wait --for=condition=available --timeout=120s deployment/smf -n open5gs
kubectl wait --for=condition=available --timeout=120s deployment/upf -n open5gs

echo -e "${GREEN}Step 9: Deploying UERANSIM ConfigMaps${NC}"
kubectl apply -f k8s/ueransim/configmap-gnb.yaml
kubectl apply -f k8s/ueransim/configmap-ue.yaml

echo -e "${GREEN}Step 10: Deploying UERANSIM gNB+UE${NC}"
kubectl apply -f k8s/ueransim/gnb-ue.yaml

echo -e "${YELLOW}Waiting for gNB to be ready...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/ueransim-gnb -n open5gs

echo -e "${YELLOW}Waiting 30 seconds for PFCP association to establish...${NC}"
sleep 30

echo -e "${GREEN}Step 11: Creating WebUI admin account${NC}"
kubectl exec -n open5gs deployment/webui -- sh -c "cat > /webui/create-admin.js << 'EOF'
const mongoose = require('mongoose');
const Schema = mongoose.Schema;
const passportLocalMongoose = require('passport-local-mongoose');

const Account = new Schema({
  roles: [String]
});

Account.plugin(passportLocalMongoose);
const AccountModel = mongoose.model('Account', Account);

mongoose.connect('mongodb://mongodb:27017/open5gs');

AccountModel.register(new AccountModel({
  username: 'admin',
  roles: ['admin']
}), '1423', function(err, account) {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log('Admin account created successfully');
  process.exit(0);
});
EOF
cd /webui && node create-admin.js"

echo -e "${GREEN}Step 12: Adding subscriber to database${NC}"
kubectl run -it --rm debug --image=local/open5gs:latest --restart=Never -n open5gs -- \
  /bin/open5gs-dbctl add 999700000000001 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA

echo ""
echo -e "${GREEN}=================================================="
echo "Deployment Complete!"
echo -e "==================================================${NC}"
echo ""
echo "Check the status of all pods:"
echo "  kubectl get pods -n open5gs"
echo ""
echo "Access Open5GS WebUI:"
echo "  http://localhost:30999"
echo "  Username: admin"
echo "  Password: 1423"
echo ""
echo "Check UE logs:"
echo "  kubectl logs -n open5gs deployment/ueransim-gnb -c ue --tail=50"
echo ""
echo "Check gNB logs:"
echo "  kubectl logs -n open5gs deployment/ueransim-gnb -c gnb --tail=50"
echo ""
echo "Expected success messages in UE logs:"
echo "  [nas] [info] Initial Registration is successful"
echo "  [nas] [info] PDU Session establishment is successful PSI[1]"
echo "  [app] [info] Connection setup for PDU session[1] is successful"
echo ""
