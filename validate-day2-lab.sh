#!/bin/bash
#
# Day 2 Lab Validation Script
# Executes validation checks for each lab step
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((WARNINGS++))
}

check_passed() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

# Validation functions
validate_cluster_access() {
    log_info "Validating cluster access..."

    if oc whoami &>/dev/null; then
        check_passed "Cluster access OK"
        oc whoami --show-server
    else
        check_failed "Cannot access cluster. Please login with: oc login"
        return 1
    fi
}

validate_namespace() {
    log_info "Validating namespace etx-app-dev..."

    if oc get namespace etx-app-dev &>/dev/null; then
        check_passed "Namespace etx-app-dev exists"
    else
        check_failed "Namespace etx-app-dev not found"
        return 1
    fi
}

validate_devspaces() {
    log_info "Validating DevSpaces installation..."

    # Check CheCluster
    if oc get checluster/devspaces -n openshift-devspaces &>/dev/null; then
        check_passed "CheCluster exists"

        # Check phase
        PHASE=$(oc get checluster/devspaces -n openshift-devspaces -o jsonpath='{.status.chePhase}')
        if [ "$PHASE" == "Active" ]; then
            check_passed "DevSpaces is Active"
        else
            check_failed "DevSpaces phase is: $PHASE (expected Active)"
        fi

        # Check URL
        DEVSPACES_URL=$(oc get checluster/devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}')
        log_info "DevSpaces URL: $DEVSPACES_URL"
    else
        check_failed "CheCluster not found in openshift-devspaces namespace"
    fi
}

validate_operators() {
    log_info "Validating operators..."

    # OpenShift Pipelines
    if oc get csv -n openshift-operators | grep -q pipelines; then
        check_passed "OpenShift Pipelines operator installed"
    else
        check_failed "OpenShift Pipelines operator not found"
    fi

    # AMQ Streams
    if oc get csv -n openshift-operators | grep -q amqstreams; then
        check_passed "AMQ Streams operator installed"
    else
        check_failed "AMQ Streams operator not found"
    fi

    # OpenTelemetry
    if oc get csv -n openshift-operators | grep -q opentelemetry; then
        check_passed "OpenTelemetry operator installed"
    else
        check_failed "OpenTelemetry operator not found"
    fi
}

validate_pipeline_resources() {
    log_info "Validating pipeline resources..."

    # Pipeline workspace PVC
    if oc get pvc pipeline-workspace-pvc -n etx-app-dev &>/dev/null; then
        PVC_STATUS=$(oc get pvc pipeline-workspace-pvc -n etx-app-dev -o jsonpath='{.status.phase}')
        if [ "$PVC_STATUS" == "Bound" ]; then
            check_passed "Pipeline workspace PVC is Bound"
        else
            check_warning "Pipeline workspace PVC status: $PVC_STATUS"
        fi
    else
        log_warning "Pipeline workspace PVC not found (may not be created yet)"
    fi

    # Pipeline ServiceAccount
    if oc get sa pipeline -n etx-app-dev &>/dev/null; then
        check_passed "Pipeline ServiceAccount exists"
    else
        log_warning "Pipeline ServiceAccount not found (may not be created yet)"
    fi

    # Pipeline
    if oc get pipeline etx-app-base-app-ci -n etx-app-dev &>/dev/null; then
        check_passed "Pipeline etx-app-base-app-ci exists"
    else
        log_warning "Pipeline not found (may not be created yet)"
    fi

    # EventListener
    if oc get pods -n etx-app-dev | grep -q el-gitlab-listener; then
        check_passed "EventListener pod running"

        # Check route
        if oc get route el-gitlab-listener -n etx-app-dev &>/dev/null; then
            WEBHOOK_URL=$(oc get route el-gitlab-listener -n etx-app-dev -o jsonpath='{.spec.host}')
            log_info "Webhook URL: http://$WEBHOOK_URL"
        fi
    else
        log_warning "EventListener pod not found (may not be created yet)"
    fi
}

validate_argocd() {
    log_info "Validating ArgoCD..."

    # Check ArgoCD instance
    if oc get argocd/argocd -n etx-app-dev &>/dev/null; then
        check_passed "ArgoCD instance exists in etx-app-dev"

        # Check server pod
        if oc get pods -n etx-app-dev | grep -q argocd-server; then
            check_passed "ArgoCD server pod running"

            # Check route
            if oc get route argocd-server -n etx-app-dev &>/dev/null; then
                ARGOCD_URL=$(oc get route argocd-server -n etx-app-dev -o jsonpath='{.spec.host}')
                log_info "ArgoCD URL: https://$ARGOCD_URL"
            fi
        else
            check_warning "ArgoCD server pod not running yet"
        fi
    else
        log_warning "ArgoCD instance not found (may not be deployed yet)"
    fi

    # Check applications
    if oc get application etx-app-dev -n etx-app-dev &>/dev/null; then
        APP_STATUS=$(oc get application etx-app-dev -n etx-app-dev -o jsonpath='{.status.sync.status}')
        APP_HEALTH=$(oc get application etx-app-dev -n etx-app-dev -o jsonpath='{.status.health.status}')
        log_info "Application etx-app-dev: sync=$APP_STATUS, health=$APP_HEALTH"

        if [ "$APP_STATUS" == "Synced" ] && [ "$APP_HEALTH" == "Healthy" ]; then
            check_passed "Application etx-app-dev is Synced and Healthy"
        else
            log_warning "Application etx-app-dev is not fully healthy yet"
        fi
    else
        log_warning "Application etx-app-dev not found (may not be created yet)"
    fi
}

validate_otel() {
    log_info "Validating OpenTelemetry..."

    # Check collector
    if oc get pods -l app.kubernetes.io/name=otel-collector-collector -n etx-app-dev &>/dev/null; then
        POD_STATUS=$(oc get pods -l app.kubernetes.io/name=otel-collector-collector -n etx-app-dev -o jsonpath='{.items[0].status.phase}')
        if [ "$POD_STATUS" == "Running" ]; then
            check_passed "OpenTelemetry collector pod running"
        else
            check_warning "OpenTelemetry collector pod status: $POD_STATUS"
        fi
    else
        log_warning "OpenTelemetry collector not found (may not be deployed yet)"
    fi

    # Check Instrumentation
    if oc get instrumentation java-instrumentation -n etx-app-dev &>/dev/null; then
        check_passed "Java instrumentation resource exists"
    else
        log_warning "Java instrumentation not found (may not be created yet)"
    fi
}

# Main validation
main() {
    echo "========================================="
    echo "  Day 2 Lab Validation"
    echo "========================================="
    echo ""

    validate_cluster_access || exit 1
    validate_namespace || exit 1
    echo ""

    validate_devspaces
    echo ""

    validate_operators
    echo ""

    validate_pipeline_resources
    echo ""

    validate_argocd
    echo ""

    validate_otel
    echo ""

    echo "========================================="
    echo "  Validation Summary"
    echo "========================================="
    echo -e "${GREEN}Passed:${NC} $PASSED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Failed:${NC} $FAILED"
    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ Validation completed successfully${NC}"
        exit 0
    else
        echo -e "${RED}✗ Validation completed with errors${NC}"
        exit 1
    fi
}

main
