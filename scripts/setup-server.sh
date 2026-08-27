#!/bin/bash
# ==============================================================================
# STCP Server Setup Script
# Server: STCP (34.238.235.55)
# Purpose: Install k3s + Argo CD + configure for Capstan Project
# ==============================================================================

set -e

echo "=========================================="
echo "  STCP Server Setup - Capstan Project"
echo "=========================================="

# Update system
echo "[1/8] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
echo "[2/8] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install k3s
echo "[3/8] Installing k3s (lightweight Kubernetes)..."
if ! command -v k3s &> /dev/null; then
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
fi

# Wait for k3s to be ready
echo "[4/8] Waiting for k3s to be ready..."
sleep 10
sudo k3s kubectl get nodes

# Install kubectl
echo "[5/8] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Install Helm
echo "[6/8] Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install Argo CD
echo "[7/8] Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

# Get Argo CD admin password
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# Install Argo CD CLI
if ! command -v argocd &> /dev/null; then
    curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 755 argocd /usr/local/bin/argocd
    rm argocd
fi

# Apply Argo CD applications
echo "[8/8] Applying Argo CD applications..."
cd /tmp
git clone https://github.com/shajedultonmoy/Capstan-Project.git
cd Capstan-Project

# Create namespaces
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace stage --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

# Apply Argo CD applications
kubectl apply -n argocd -f argocd/application-dev.yaml
kubectl apply -n argocd -f argocd/application-stage.yaml
kubectl apply -n argocd -f argocd/application-prod.yaml

cd /tmp
rm -rf Capstan-Project

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Access points:"
echo "  - Argo CD UI: http://34.238.235.55:30080/argocd"
echo "  - Dev Frontend: http://34.238.235.55:30080"
echo "  - Stage Frontend: http://34.238.235.55:30082"
echo "  - Prod Frontend: http://34.238.235.55:30084"
echo ""
echo "Argo CD Login:"
echo "  Username: admin"
echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo "Next steps:"
echo "  1. Set up GitHub Actions secrets (EC2_SSH_KEY, GHCR_TOKEN)"
echo "  2. Open ports 30080-30085 in AWS Security Group"
echo "  3. Push code to trigger CI/CD pipelines"
