#!/bin/bash

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=================================================="
echo "Open5GS + UERANSIM Build and Deploy Script"
echo "=================================================="

# Image tags
OPEN5GS_IMAGE="local/open5gs:latest"
UERANSIM_IMAGE="local/ueransim:latest"

echo -e "${GREEN}Step 1: Building Open5GS Docker image${NC}"
echo "This may take 10-20 minutes..."
docker build -t ${OPEN5GS_IMAGE} -f Dockerfile.open5gs .

echo -e "${GREEN}Step 2: Building UERANSIM Docker image${NC}"
echo "This may take 5-10 minutes..."
docker build -t ${UERANSIM_IMAGE} -f Dockerfile.ueransim .

echo -e "${GREEN}Step 3: Building WebUI Docker image${NC}"
echo "This may take 5-10 minutes..."
docker build -t local/webui:latest -f Dockerfile.webui .

echo -e "${GREEN}Step 4: Loading images into kind cluster${NC}"
kind load docker-image ${OPEN5GS_IMAGE} --name kind-5gs
kind load docker-image ${UERANSIM_IMAGE} --name kind-5gs
kind load docker-image local/webui:latest --name kind-5gs

# Also load MongoDB image
echo -e "${GREEN}Step 5: Loading MongoDB image into kind cluster${NC}"
docker pull mongo:latest
kind load docker-image mongo:latest --name kind-5gs

echo -e "${GREEN}Step 6: Updating Kubernetes manifests${NC}"
# Update all Open5GS deployment manifests to use local image
for file in k8s/open5gs/*.yaml; do
    if grep -q "image: openverso/open5gs" "$file"; then
        sed -i 's|image: openverso/open5gs[^:]*:latest|image: local/open5gs:latest|g' "$file"
        sed -i 's|imagePullPolicy:.*|imagePullPolicy: Never|g' "$file"
        # Add imagePullPolicy if not present
        if ! grep -q "imagePullPolicy" "$file"; then
            sed -i '/image: local\/open5gs:latest/a\        imagePullPolicy: Never' "$file"
        fi
    fi
done

# Update UERANSIM deployment manifests
for file in k8s/ueransim/*.yaml; do
    if grep -q "image: towards5gs/ueransim" "$file"; then
        sed -i 's|image: towards5gs/ueransim:latest|image: local/ueransim:latest|g' "$file"
        sed -i 's|imagePullPolicy:.*|imagePullPolicy: Never|g' "$file"
        # Add imagePullPolicy if not present
        if ! grep -q "imagePullPolicy" "$file"; then
            sed -i '/image: local\/ueransim:latest/a\        imagePullPolicy: Never' "$file"
        fi
    fi
done

echo -e "${GREEN}Step 7: Deploying to Kubernetes${NC}"
./deploy.sh

echo -e "${GREEN}=================================================="
echo "Build and Deployment Complete!"
echo -e "==================================================${NC}"
echo ""
echo "Images built and loaded:"
echo "  - ${OPEN5GS_IMAGE}"
echo "  - ${UERANSIM_IMAGE}"
echo ""
echo "Check deployment status:"
echo "  kubectl get pods -n open5gs"
echo ""
