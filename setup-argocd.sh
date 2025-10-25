#!/bin/bash

echo "🚀 Memory PWA - ArgoCD Setup Script"
echo "=================================="

# Load environment variables
load_env

# Set up kubectl function for minikube
kubectl() {
    minikube kubectl -- "$@"
}

# Load environment variables from .env file if it exists
load_env() {
    if [ -f .env ]; then
        print_status "Loading environment variables from .env file..."
        export $(cat .env | grep -v '^#' | xargs)
        print_success "Environment variables loaded"
    fi
}

# Function to login to ArgoCD using .env variables
argocd_login() {
    if [ -n "$ARGOCD_USERNAME" ] && [ -n "$ARGOCD_PASSWORD" ] && [ -n "$ARGOCD_SERVER" ]; then
        print_status "Logging into ArgoCD using .env credentials..."
        argocd login $ARGOCD_SERVER --insecure --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "Successfully logged into ArgoCD"
            return 0
        else
            print_warning "Failed to login to ArgoCD using .env credentials"
            return 1
        fi
    else
        print_warning "ArgoCD credentials not found in .env file"
        return 1
    fi
}

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
if ! minikube kubectl -- get nodes > /dev/null 2>&1; then
    print_error "kubectl is not connected to a cluster"
    exit 1
fi
print_success "kubectl is connected"

# Check if ArgoCD is installed and running
print_status "Checking ArgoCD status..."
if ! kubectl get namespace argocd > /dev/null 2>&1; then
    print_status "ArgoCD namespace not found. Installing ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    print_success "ArgoCD installed"
    
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    print_success "ArgoCD is ready"
elif ! kubectl get pods -n argocd | grep -q "Running"; then
    print_status "ArgoCD namespace exists but not running. Starting ArgoCD..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    print_success "ArgoCD is ready"
else
    print_success "ArgoCD is running"
fi

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

# Save ArgoCD credentials to .env file
print_status "Saving ArgoCD credentials to .env file..."
cat > .env << EOF
# ArgoCD Credentials
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=$ARGOCD_PASSWORD
ARGOCD_SERVER=localhost:8080
ARGOCD_INSECURE=true

# Memory PWA Application
MEMORY_PWA_URL=http://localhost:3001
MEMORY_PWA_NAMESPACE=memory-pwa
EOF
print_success "ArgoCD credentials saved to .env file"

# Check if ArgoCD CLI is available
print_status "Checking ArgoCD CLI..."
if ! command -v argocd > /dev/null 2>&1; then
    print_warning "ArgoCD CLI not found. Installing..."
    # Install ArgoCD CLI
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    else
        print_error "Please install ArgoCD CLI manually"
        exit 1
    fi
fi
print_success "ArgoCD CLI is available"

# Start port-forward for ArgoCD in background
print_status "Starting ArgoCD port-forward..."
kubectl port-forward -n argocd svc/argocd-server 8080:443 > /dev/null 2>&1 &
ARGOCD_PF_PID=$!
sleep 5

# Login to ArgoCD
print_status "Logging into ArgoCD..."
if ! argocd_login; then
    # Fallback to manual login if .env method fails
    print_status "Trying manual login to ArgoCD..."
    argocd login localhost:8080 --insecure --username admin --password "$ARGOCD_PASSWORD" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "Successfully logged into ArgoCD"
    else
        print_error "Failed to login to ArgoCD"
        kill $ARGOCD_PF_PID 2>/dev/null
        exit 1
    fi
fi

# Create ArgoCD Application
print_status "Creating ArgoCD Application..."
argocd app create memory-pwa \
  --repo https://github.com/DawidAdamski/pwa-app-university.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace memory-pwa \
  --sync-policy automated \
  --upsert > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_success "ArgoCD Application created successfully"
else
    print_warning "Failed to create ArgoCD Application (may already exist)"
fi

# Sync the application
print_status "Syncing ArgoCD Application..."
argocd app sync memory-pwa --force > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "ArgoCD Application synced"
else
    print_warning "Failed to sync ArgoCD Application"
fi

# Stop port-forward
kill $ARGOCD_PF_PID 2>/dev/null

# Instructions
print_success "Setup complete! Next steps:"
echo ""
echo "1. Access ArgoCD UI:"
echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "   Then open: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "2. Access Memory PWA:"
echo "   kubectl port-forward -n memory-pwa service/memory-pwa-service 3001:80"
echo "   Then open: http://localhost:3001"
echo ""
echo "3. ArgoCD credentials saved to .env file:"
echo "   - Username: admin"
echo "   - Password: $ARGOCD_PASSWORD"
echo "   - Server: localhost:8080"
echo ""
echo "4. To use ArgoCD CLI with saved credentials:"
echo "   source .env"
echo "   argocd login \$ARGOCD_SERVER --insecure --username \$ARGOCD_USERNAME --password \$ARGOCD_PASSWORD"
echo ""
print_success "All done! 🎉"
