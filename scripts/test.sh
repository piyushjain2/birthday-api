#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    npm run test:unit
    
    if [ $? -eq 0 ]; then
        log_info "Unit tests passed"
    else
        log_error "Unit tests failed"
        return 1
    fi
}

# Run integration tests with Docker
run_integration_tests() {
    log_info "Running integration tests..."
    
    # Start test database
    log_info "Starting test database..."
    docker-compose -f docker-compose.test.yml up -d postgres
    
    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    for i in {1..30}; do
        if docker-compose -f docker-compose.test.yml exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
            log_info "Database is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            log_error "Database failed to start"
            docker-compose -f docker-compose.test.yml logs postgres
            return 1
        fi
        sleep 1
    done
    
    # Run integration tests
    docker-compose -f docker-compose.test.yml run --rm app-test npm run test:integration
    local test_result=$?
    
    # Clean up
    log_info "Cleaning up test environment..."
    docker-compose -f docker-compose.test.yml down -v
    
    if [ $test_result -eq 0 ]; then
        log_info "Integration tests passed"
    else
        log_error "Integration tests failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    log_info "Running all tests..."
    
    # Run unit tests first (they don't need database)
    run_unit_tests || return 1
    
    # Run integration tests if unit tests pass
    if [ "${SKIP_INTEGRATION_TESTS:-false}" != "true" ]; then
        run_integration_tests || return 1
    else
        log_warn "Skipping integration tests (SKIP_INTEGRATION_TESTS=true)"
    fi
    
    log_info "All tests passed!"
}

# Main execution
main() {
    case "${1:-all}" in
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        all)
            run_all_tests
            ;;
        *)
            log_error "Invalid test type: $1"
            echo "Usage: $0 [unit|integration|all]"
            exit 1
            ;;
    esac
}

main "$@" 