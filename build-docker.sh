#!/bin/bash

# Memory PWA - Docker Build Script
# This script builds and pushes the Memory PWA container image

set -e

# Configuration
IMAGE_NAME="anihilat/pwa-memory"
TAG="latest"
SOURCE_DIR="source"

echo "🐳 Building Memory PWA Docker Image"
echo "=================================="

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Error: Source directory '$SOURCE_DIR' not found!"
    exit 1
fi

# Build the image
echo "📦 Building Docker image..."
sudo podman build --network=host -t "$IMAGE_NAME:$TAG" "$SOURCE_DIR"

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
    echo "📋 Image: $IMAGE_NAME:$TAG"
    
    # Ask if user wants to push
    read -p "🚀 Do you want to push the image to Docker Hub? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📤 Pushing image to Docker Hub..."
        sudo podman push "$IMAGE_NAME:$TAG"
        
        if [ $? -eq 0 ]; then
            echo "✅ Image pushed successfully!"
            echo "🌐 Available at: https://hub.docker.com/r/$IMAGE_NAME"
        else
            echo "❌ Failed to push image"
            exit 1
        fi
    else
        echo "ℹ️  Image built locally. Use 'sudo podman push $IMAGE_NAME:$TAG' to push later."
    fi
else
    echo "❌ Docker build failed!"
    exit 1
fi

echo ""
echo "🎉 Build process completed!"
echo ""
echo "Next steps:"
echo "1. Push changes to GitHub: git add . && git commit -m 'Update' && git push"
echo "2. ArgoCD will automatically deploy the updated image"
echo "3. Access your app: kubectl port-forward -n memory-pwa service/memory-pwa-service 3000:80"
