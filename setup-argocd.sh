#!/bin/bash

echo "🚀 Memory PWA - ArgoCD Setup Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is working
print_status "Checking kubectl connection..."
if ! kubectl cluster-info > /dev/null 2>&1; then
    print_error "kubectl is not connected to a cluster"
    exit 1
fi
print_success "kubectl is connected"

# Check if ArgoCD is running
print_status "Checking ArgoCD status..."
if ! kubectl get pods -n argocd | grep -q "Running"; then
    print_error "ArgoCD is not running. Please install ArgoCD first."
    exit 1
fi
print_success "ArgoCD is running"

# Load image into minikube
print_status "Loading image into minikube..."
if command -v minikube > /dev/null 2>&1; then
    minikube image load localhost/memory-pwa:latest
    print_success "Image loaded into minikube"
else
    print_warning "minikube not found, skipping image load"
fi

# Apply Kubernetes manifests
print_status "Applying Kubernetes manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
print_success "Kubernetes manifests applied"

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/memory-pwa -n memory-pwa
print_success "Deployment is ready"

# Show status
print_status "Current status:"
echo ""
kubectl get pods -n memory-pwa
echo ""
kubectl get svc -n memory-pwa
echo ""

# Get ArgoCD admin password
print_status "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Instructions
print_success "Setup complete! Next steps:"
echo ""
echo "1. Access ArgoCD UI:"
echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "   Then open: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "2. Login to ArgoCD CLI:"
echo "   argocd login localhost:8080 --insecure"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "3. Create ArgoCD Application (after pushing to GitHub):"
echo "   argocd app create memory-pwa \\"
echo "     --repo https://github.com/yourusername/memory-pwa.git \\"
echo "     --path k8s \\"
echo "     --dest-server https://kubernetes.default.svc \\"
echo "     --dest-namespace memory-pwa \\"
echo "     --sync-policy automated"
echo ""
echo "4. Access Memory PWA:"
echo "   kubectl port-forward -n memory-pwa service/memory-pwa-service 3001:80"
echo "   Then open: http://localhost:3001"
echo ""
print_success "All done! 🎉"
