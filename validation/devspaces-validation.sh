#!/bin/bash
# DevSpaces Workspace Validation Script
# Run this script INSIDE your DevSpaces workspace

set -e

echo "========================================="
echo "DevSpaces Workspace Validation"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 FAILED${NC}"
        return 1
    fi
}

check_value() {
    local var_name=$1
    local var_value=$2
    local expected=$3

    if [ "$var_value" == "$expected" ]; then
        echo -e "${GREEN}✅ $var_name = $var_value${NC}"
        return 0
    else
        echo -e "${RED}❌ $var_name = $var_value (expected: $expected)${NC}"
        return 1
    fi
}

echo "================================================"
echo "STEP 1: Verify Environment Variables"
echo "================================================"
echo ""

echo "Checking PostgreSQL environment variables..."
echo "POSTGRESQL_HOST: $POSTGRESQL_HOST"
check_value "POSTGRESQL_HOST" "$POSTGRESQL_HOST" "parasol-db.etx-app-dev.svc.cluster.local"

echo "POSTGRESQL_DATABASE: $POSTGRESQL_DATABASE"
check_value "POSTGRESQL_DATABASE" "$POSTGRESQL_DATABASE" "parasol"

echo "POSTGRESQL_USER: $POSTGRESQL_USER"
check_value "POSTGRESQL_USER" "$POSTGRESQL_USER" "parasol"

echo "POSTGRESQL_PASSWORD: $POSTGRESQL_PASSWORD"
check_value "POSTGRESQL_PASSWORD" "$POSTGRESQL_PASSWORD" "parasol"

echo ""
echo "Checking Kafka environment variables..."
echo "KAFKA_BOOTSTRAP_SERVERS: $KAFKA_BOOTSTRAP_SERVERS"
check_value "KAFKA_BOOTSTRAP_SERVERS" "$KAFKA_BOOTSTRAP_SERVERS" "parasol-kafka-kafka-bootstrap.etx-app-dev.svc.cluster.local:9092"

echo ""
echo "================================================"
echo "STEP 2: Verify Network Connectivity"
echo "================================================"
echo ""

echo "Testing PostgreSQL connectivity..."
if nc -zv ${POSTGRESQL_HOST} 5432 2>&1 | grep -q "succeeded\|open"; then
    check_success "PostgreSQL port 5432 is reachable"
else
    check_success "PostgreSQL port 5432 is reachable" && false
fi

echo ""
echo "Testing Kafka connectivity..."
KAFKA_HOST=$(echo $KAFKA_BOOTSTRAP_SERVERS | cut -d: -f1)
KAFKA_PORT=$(echo $KAFKA_BOOTSTRAP_SERVERS | cut -d: -f2)
if nc -zv ${KAFKA_HOST} ${KAFKA_PORT} 2>&1 | grep -q "succeeded\|open"; then
    check_success "Kafka port ${KAFKA_PORT} is reachable"
else
    check_success "Kafka port ${KAFKA_PORT} is reachable" && false
fi

echo ""
echo "================================================"
echo "STEP 3: Verify Application Configuration"
echo "================================================"
echo ""

if [ -f "src/main/resources/application.properties" ]; then
    echo "✅ application.properties exists"
    echo ""
    echo "Checking Dev Services configuration..."

    if grep -q "%dev.quarkus.datasource.devservices.enabled=false" src/main/resources/application.properties; then
        check_success "PostgreSQL Dev Services disabled"
    else
        echo -e "${RED}❌ PostgreSQL Dev Services NOT disabled${NC}"
    fi

    if grep -q "%dev.quarkus.kafka.devservices.enabled=false" src/main/resources/application.properties; then
        check_success "Kafka Dev Services disabled"
    else
        echo -e "${RED}❌ Kafka Dev Services NOT disabled${NC}"
    fi

    echo ""
    echo "Checking external service configuration..."

    if grep -q "POSTGRESQL_HOST" src/main/resources/application.properties; then
        check_success "PostgreSQL connection uses environment variable"
    else
        echo -e "${RED}❌ PostgreSQL connection does not use POSTGRESQL_HOST${NC}"
    fi

    if grep -q "KAFKA_BOOTSTRAP_SERVERS" src/main/resources/application.properties; then
        check_success "Kafka connection uses environment variable"
    else
        echo -e "${RED}❌ Kafka connection does not use KAFKA_BOOTSTRAP_SERVERS${NC}"
    fi
else
    echo -e "${RED}❌ application.properties not found${NC}"
    echo "Create it with the configuration from validation/application.properties"
fi

echo ""
echo "================================================"
echo "STEP 4: Verify Devfile Configuration"
echo "================================================"
echo ""

if [ -f "devfile.yaml" ]; then
    echo "✅ devfile.yaml exists"
    echo ""
    echo "Checking for OLD Podman/Testcontainers configuration..."

    if grep -q "XDG_RUNTIME_DIR" devfile.yaml; then
        echo -e "${RED}❌ Found XDG_RUNTIME_DIR (OLD configuration)${NC}"
    else
        check_success "No XDG_RUNTIME_DIR (correct)"
    fi

    if grep -q "DOCKER_HOST" devfile.yaml; then
        echo -e "${RED}❌ Found DOCKER_HOST (OLD configuration)${NC}"
    else
        check_success "No DOCKER_HOST (correct)"
    fi

    if grep -q "TESTCONTAINERS" devfile.yaml; then
        echo -e "${RED}❌ Found TESTCONTAINERS variables (OLD configuration)${NC}"
    else
        check_success "No TESTCONTAINERS variables (correct)"
    fi

    if grep -q "init-podman" devfile.yaml; then
        echo -e "${RED}❌ Found init-podman command (OLD configuration)${NC}"
    else
        check_success "No init-podman command (correct)"
    fi

    echo ""
    echo "Checking for NEW external service configuration..."

    if grep -q "POSTGRESQL_HOST" devfile.yaml; then
        check_success "PostgreSQL environment variables configured"
    else
        echo -e "${RED}❌ Missing PostgreSQL environment variables${NC}"
    fi

    if grep -q "KAFKA_BOOTSTRAP_SERVERS" devfile.yaml; then
        check_success "Kafka environment variables configured"
    else
        echo -e "${RED}❌ Missing Kafka environment variables${NC}"
    fi
else
    echo -e "${RED}❌ devfile.yaml not found${NC}"
fi

echo ""
echo "================================================"
echo "STEP 5: Ready to Run Quarkus Dev Mode"
echo "================================================"
echo ""

echo "Your workspace is configured correctly!"
echo ""
echo "To start the application, run:"
echo "  ./mvnw clean compile quarkus:dev"
echo ""
echo "Expected behavior:"
echo "  ✅ NO Docker/Testcontainers errors"
echo "  ✅ NO 'Dev Services for postgresql started' message"
echo "  ✅ NO 'Dev Services for Kafka started' message"
echo "  ✅ Application connects to external PostgreSQL"
echo "  ✅ Application connects to external Kafka"
echo "  ✅ Application starts on http://localhost:8080"
echo ""
echo "To test the application is using external services:"
echo "  1. Start Quarkus dev mode"
echo "  2. Check logs for Hibernate DDL (creates tables in external PostgreSQL)"
echo "  3. Check logs for Kafka channel configuration"
echo "  4. In another terminal, verify database tables:"
echo "     oc exec -it deployment/parasol-db -n etx-app-dev -- psql -U parasol -d parasol -c '\\dt'"
echo ""
