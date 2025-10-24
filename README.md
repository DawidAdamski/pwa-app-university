# Memory PWA - Kubernetes Deployment with ArgoCD

A Progressive Web App (PWA) for the classic Memory card game, deployed on Kubernetes with ArgoCD for GitOps automation.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│     ArgoCD      │───▶│   Kubernetes    │
│   (Source)      │    │   (GitOps)      │    │   (Minikube)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (Minikube with Hyper-V)
- kubectl configured
- Podman/Docker for container builds
- Git repository (GitHub)

### 1. Build and Push Container Image

```bash
# Build the container image
sudo podman build --network=host -t memory-pwa .

# For minikube, load image directly
minikube image load memory-pwa
```

### 2. Deploy to Kubernetes

```bash
# Create namespace and deploy
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n memory-pwa
kubectl get services -n memory-pwa
```

### 3. Access the Application

```bash
# Port forward to access locally
kubectl port-forward -n memory-pwa service/memory-pwa-service 8080:80

# Access at: http://localhost:8080
```

## 🔄 ArgoCD GitOps Setup

### 1. Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. Get ArgoCD Admin Password

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 3. Access ArgoCD UI

```bash
# Port forward ArgoCD server
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Access ArgoCD at: https://localhost:8080
# Username: admin
# Password: (from step 2)
```

### 4. Create ArgoCD Application

```bash
# Apply the ArgoCD application
kubectl apply -f argocd-application.yaml

# Or create via ArgoCD CLI
argocd app create memory-pwa \
  --repo https://github.com/yourusername/memory-pwa.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace memory-pwa \
  --sync-policy automated
```

## 📁 Repository Structure

```
memory-pwa/
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml           # Namespace definition
│   ├── deployment.yaml          # Deployment configuration
│   ├── service.yaml             # Service definition
│   ├── ingress.yaml             # Ingress configuration
│   └── kustomization.yaml      # Kustomize configuration
├── argocd-application.yaml      # ArgoCD application manifest
├── Dockerfile                   # Container definition
├── package.json                 # Node.js dependencies
├── index.html                   # PWA main file
├── styles.css                   # Application styles
├── app.js                       # Game logic
├── sw.js                        # Service worker
├── manifest.json                # PWA manifest
├── icons/                       # PWA icons
└── README.md                    # This file
```

## 🔧 Configuration

### Environment Variables

- `PORT`: Application port (default: 3000)

### Resource Limits

- **Memory**: 64Mi request, 128Mi limit
- **CPU**: 50m request, 100m limit

### Health Checks

- **Liveness Probe**: HTTP GET on `/` every 10s
- **Readiness Probe**: HTTP GET on `/` every 5s

## 🌐 Networking

### Service Configuration

- **Type**: ClusterIP
- **Port**: 80 → 3000
- **Selector**: app=memory-pwa

### Ingress Configuration

- **Host**: memory-pwa.local
- **Path**: /
- **Annotations**: nginx.ingress.kubernetes.io

## 🔄 GitOps Workflow

### Automatic Deployment

1. **Code Push**: Developer pushes to GitHub
2. **ArgoCD Sync**: ArgoCD detects changes
3. **Auto Deploy**: Application updates automatically
4. **Health Check**: ArgoCD monitors deployment health

### Manual Sync

```bash
# Sync specific application
argocd app sync memory-pwa

# Sync all applications
argocd app sync --all
```

## 🛠️ Development Workflow

### 1. Local Development

```bash
# Start development server
npm run dev

# Test PWA features
# - Install prompt
# - Offline functionality
# - Service worker
```

### 2. Build and Test

```bash
# Build container
sudo podman build --network=host -t memory-pwa .

# Test locally
sudo podman run -d --network=host --name memory-pwa-test memory-pwa
```

### 3. Deploy to Kubernetes

```bash
# Load image to minikube
minikube image load memory-pwa

# Deploy manifests
kubectl apply -f k8s/
```

### 4. GitOps Deployment

```bash
# Commit and push changes
git add .
git commit -m "Update Memory PWA"
git push origin main

# ArgoCD will automatically sync
```

## 📊 Monitoring and Logs

### View Application Logs

```bash
# Pod logs
kubectl logs -n memory-pwa deployment/memory-pwa

# Follow logs
kubectl logs -f -n memory-pwa deployment/memory-pwa
```

### Check Application Status

```bash
# Pod status
kubectl get pods -n memory-pwa

# Service status
kubectl get svc -n memory-pwa

# Ingress status
kubectl get ingress -n memory-pwa
```

### ArgoCD Application Status

```bash
# Application status
argocd app get memory-pwa

# Application logs
argocd app logs memory-pwa
```

## 🔒 Security

### RBAC Configuration

- **Service Account**: memory-pwa
- **Role**: Limited to memory-pwa namespace
- **Permissions**: Get, List, Watch, Create, Update, Patch, Delete

### Network Policies

- **Ingress**: Allow from ingress controller
- **Egress**: Allow to DNS and external APIs

## 🚨 Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Load image to minikube
   minikube image load memory-pwa
   ```

2. **ArgoCD Sync Issues**
   ```bash
   # Check application status
   argocd app get memory-pwa
   
   # Force sync
   argocd app sync memory-pwa --force
   ```

3. **Service Not Accessible**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n memory-pwa
   
   # Port forward for testing
   kubectl port-forward -n memory-pwa service/memory-pwa-service 8080:80
   ```

### Debug Commands

```bash
# Describe resources
kubectl describe pod -n memory-pwa -l app=memory-pwa
kubectl describe service -n memory-pwa memory-pwa-service

# Check events
kubectl get events -n memory-pwa --sort-by='.lastTimestamp'
```

## 📈 Scaling

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-pwa-hpa
  namespace: memory-pwa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: memory-pwa
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 🔄 CI/CD Pipeline

### GitHub Actions (Optional)

```yaml
name: Deploy to Kubernetes
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Deploy to Kubernetes
      run: |
        kubectl apply -f k8s/
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PWA Documentation](https://web.dev/progressive-web-apps/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally and in Kubernetes
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.