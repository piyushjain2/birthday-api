#!/bin/bash
set -euo pipefail

# Configuration
NAMESPACE=${NAMESPACE:-birthday-app}
S3_BUCKET=${S3_BUCKET:-birthday-app-backups}
AWS_REGION=${AWS_REGION:-us-east-1}
RETENTION_DAYS=${RETENTION_DAYS:-30}

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="postgres_backup_${timestamp}"
    
    log_info "Creating backup: ${backup_name}"
    
    # Execute pg_dump on primary
    kubectl exec -n ${NAMESPACE} postgres-0 -- bash -c "
        PGPASSWORD=\$POSTGRES_PASSWORD pg_dump \
            -U \$POSTGRES_USER \
            -d \$POSTGRES_DB \
            -f /tmp/${backup_name}.sql
    "
    
    # Compress backup
    kubectl exec -n ${NAMESPACE} postgres-0 -- gzip /tmp/${backup_name}.sql
    
    # Copy backup to local
    kubectl cp ${NAMESPACE}/postgres-0:/tmp/${backup_name}.sql.gz ./${backup_name}.sql.gz
    
    # Upload to S3
    aws s3 cp ./${backup_name}.sql.gz s3://${S3_BUCKET}/backups/${backup_name}.sql.gz \
        --region ${AWS_REGION}
    
    # Clean up
    rm -f ./${backup_name}.sql.gz
    kubectl exec -n ${NAMESPACE} postgres-0 -- rm -f /tmp/${backup_name}.sql.gz
    
    log_info "Backup completed: s3://${S3_BUCKET}/backups/${backup_name}.sql.gz"
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
    
    aws s3 ls s3://${S3_BUCKET}/backups/ --region ${AWS_REGION} | \
    while read -r line; do
        createDate=$(echo $line | awk '{print $1" "$2}')
        createDate=$(date -d"$createDate" +%s)
        olderThan=$(date -d"-${RETENTION_DAYS} days" +%s)
        
        if [[ $createDate -lt $olderThan ]]; then
            fileName=$(echo $line | awk '{print $4}')
            if [[ $fileName != "" ]]; then
                aws s3 rm s3://${S3_BUCKET}/backups/$fileName --region ${AWS_REGION}
                log_info "Deleted old backup: $fileName"
            fi
        fi
    done
}

# Main
main() {
    log_info "Starting PostgreSQL backup process..."
    
    # Check prerequisites
    if ! kubectl get pod postgres-0 -n ${NAMESPACE} &> /dev/null; then
        log_error "PostgreSQL primary pod not found"
        exit 1
    fi
    
    # Create backup
    create_backup
    
    # Cleanup old backups
    cleanup_old_backups
    
    log_info "Backup process completed successfully"
}

main 