#!/bin/bash

set -e

echo "=================================================="
echo "Open5GS + UERANSIM Cleanup Script"
echo "=================================================="

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This will delete all Open5GS and UERANSIM resources.${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo -e "${GREEN}Deleting UERANSIM resources...${NC}"
kubectl delete -f k8s/ueransim/gnb-ue.yaml --ignore-not-found
kubectl delete -f k8s/ueransim/configmap-ue.yaml --ignore-not-found
kubectl delete -f k8s/ueransim/configmap-gnb.yaml --ignore-not-found

echo -e "${GREEN}Deleting Open5GS network functions...${NC}"
kubectl delete -f k8s/open5gs/upf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/smf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/amf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/bsf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/nssf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/pcf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/udr.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/udm.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/ausf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/scp.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/nrf.yaml --ignore-not-found

echo -e "${GREEN}Deleting ConfigMaps...${NC}"
kubectl delete -f k8s/open5gs/configmap-upf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-smf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-amf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-bsf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-nssf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-pcf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-udr.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-udm.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-ausf.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-scp.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/configmap-nrf.yaml --ignore-not-found

echo -e "${GREEN}Deleting WebUI and MongoDB...${NC}"
kubectl delete -f k8s/open5gs/webui.yaml --ignore-not-found
kubectl delete -f k8s/open5gs/mongodb.yaml --ignore-not-found

#echo -e "${GREEN}Deleting namespace...${NC}"
#kubectl delete namespace open5gs --ignore-not-found
echo "To delete the 'open5gs' namespace, run:"
echo "  kubectl delete namespace open5gs"

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
echo ""
echo "To completely remove the kind cluster:"
echo "  kind delete cluster --name kind-5gs"
echo ""
