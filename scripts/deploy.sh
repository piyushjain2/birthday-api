#!/bin/bash
set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPO=${ECR_REPO:-}
IMAGE_TAG=${2:-latest}
CLUSTER_NAME=${CLUSTER_NAME:-birthday-app-cluster}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required tools
    for tool in kubectl aws docker kustomize; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool is not installed"
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    # Check kubectl context
    if ! kubectl config current-context &> /dev/null; then
        log_error "kubectl context not configured"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

run_tests() {
    log_info "Running tests..."
    
    # Run unit tests locally
    if ! npm run test:unit; then
        log_error "Unit tests failed"
        exit 1
    fi
    
    log_info "Tests passed"
}

build_and_push_image() {
    log_info "Building Docker image..."
    
    # Build image (targeting production stage, skipping test stage)
    docker build --target production -t birthday-api:${IMAGE_TAG} .
    
    if [ -n "$ECR_REPO" ]; then
        log_info "Pushing image to ECR..."
        
        # Login to ECR
        aws ecr get-login-password --region ${AWS_REGION} | \
            docker login --username AWS --password-stdin ${ECR_REPO}
        
        # Tag and push
        docker tag birthday-api:${IMAGE_TAG} ${ECR_REPO}/birthday-api:${IMAGE_TAG}
        docker push ${ECR_REPO}/birthday-api:${IMAGE_TAG}
        
        log_info "Image pushed successfully"
    else
        log_warn "ECR_REPO not set, skipping push to registry"
    fi
}

deploy_database() {
    log_info "Deploying PostgreSQL..."
    
    # Apply database manifests
    kubectl apply -f k8s/base/namespace.yaml
    kubectl apply -f k8s/base/postgres-replication-secret.yaml
    kubectl apply -f k8s/base/postgres-statefulset.yaml
    
    # Wait for primary to be ready
    log_info "Waiting for PostgreSQL primary to be ready..."
    kubectl wait --for=condition=ready pod/postgres-0 \
        -n birthday-app --timeout=300s
    
    # Wait for replicas to be ready
    log_info "Waiting for PostgreSQL replicas to be ready..."
    for i in 1 2; do
        kubectl wait --for=condition=ready pod/postgres-$i \
            -n birthday-app --timeout=300s || true
    done
    
    log_info "PostgreSQL deployment completed"
}

deploy_application() {
    log_info "Deploying application to ${ENVIRONMENT}..."
    
    # Update image in kustomization if ECR is configured
    if [ -n "$ECR_REPO" ]; then
        cd k8s/overlays/${ENVIRONMENT}
        kustomize edit set image birthday-api=${ECR_REPO}/birthday-api:${IMAGE_TAG}
        cd -
    fi
    
    # Apply manifests using kustomize
    kubectl apply -k k8s/overlays/${ENVIRONMENT}
    
    # Wait for deployment rollout
    log_info "Waiting for deployment rollout..."
    kubectl rollout status deployment/birthday-app -n birthday-app --timeout=300s
    
    log_info "Application deployment completed"
}

perform_health_check() {
    log_info "Performing health check..."
    
    # Get service endpoint
    SERVICE_IP=$(kubectl get svc birthday-app -n birthday-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$SERVICE_IP" ]; then
        SERVICE_IP=$(kubectl get svc birthday-app -n birthday-app -o jsonpath='{.spec.clusterIP}')
        log_warn "Using ClusterIP for health check: ${SERVICE_IP}"
    fi
    
    # Check health endpoint
    if curl -f -s "http://${SERVICE_IP}/health" > /dev/null; then
        log_info "Health check passed"
    else
        log_error "Health check failed"
        exit 1
    fi
}

rollback() {
    log_error "Deployment failed, initiating rollback..."
    
    # Rollback deployment
    kubectl rollout undo deployment/birthday-app -n birthday-app
    
    # Wait for rollback to complete
    kubectl rollout status deployment/birthday-app -n birthday-app --timeout=300s
    
    log_info "Rollback completed"
}

# Main execution
main() {
    log_info "Starting deployment process..."
    
    # Set error trap for rollback
    trap 'rollback' ERR
    
    # Execute deployment steps
    check_prerequisites
    run_tests
    build_and_push_image
    
    # Check if database needs to be deployed
    if ! kubectl get statefulset postgres -n birthday-app &> /dev/null; then
        deploy_database
    else
        log_info "PostgreSQL already deployed, skipping..."
    fi
    
    deploy_application
    perform_health_check
    
    # Remove error trap
    trap - ERR
    
    log_info "Deployment completed successfully!"
}

# Run main function
main 