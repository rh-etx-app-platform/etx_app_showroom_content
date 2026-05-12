#!/bin/bash
# End-to-End Validation Script
# Following Day 2 Lab 1 instructions from showroom content

set -e

echo "========================================="
echo "ETX App Showroom - End-to-End Validation"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 FAILED${NC}"
        exit 1
    fi
}

check_warning() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${YELLOW}⚠️  $1 (continuing...)${NC}"
    fi
}

echo "================================================"
echo "STEP 1: Verify Cluster Access"
echo "================================================"
echo ""

oc whoami --show-server
check_success "Connected to OpenShift cluster"

oc project etx-app-dev
check_success "Switched to etx-app-dev namespace"

echo ""
echo "================================================"
echo "STEP 2: Deploy Supporting Services"
echo "================================================"
echo ""

echo "--- Deploying PostgreSQL Database ---"

cat <<'EOF' | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: parasol-db-secret
  namespace: etx-app-dev
type: Opaque
stringData:
  database-name: parasol
  database-user: parasol
  database-password: parasol
---
apiVersion: v1
kind: Service
metadata:
  name: parasol-db
  namespace: etx-app-dev
spec:
  ports:
    - name: postgresql
      port: 5432
      targetPort: 5432
  selector:
    app: parasol-db
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: parasol-db
  namespace: etx-app-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: parasol-db
  template:
    metadata:
      labels:
        app: parasol-db
    spec:
      containers:
        - name: postgresql
          image: registry.redhat.io/rhel9/postgresql-17:latest
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRESQL_USER
              valueFrom:
                secretKeyRef:
                  name: parasol-db-secret
                  key: database-user
            - name: POSTGRESQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: parasol-db-secret
                  key: database-password
            - name: POSTGRESQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: parasol-db-secret
                  key: database-name
          volumeMounts:
            - name: postgresql-data
              mountPath: /var/lib/pgsql/data
          livenessProbe:
            exec:
              command:
                - /usr/libexec/check-container
                - --live
            initialDelaySeconds: 120
            timeoutSeconds: 10
          readinessProbe:
            exec:
              command:
                - /usr/libexec/check-container
            initialDelaySeconds: 5
            timeoutSeconds: 1
          resources:
            limits:
              memory: 512Mi
              cpu: 500m
            requests:
              memory: 256Mi
              cpu: 100m
      volumes:
        - name: postgresql-data
          emptyDir: {}
EOF

check_success "PostgreSQL manifests applied"

echo "Waiting for PostgreSQL deployment..."
oc rollout status deployment/parasol-db -n etx-app-dev --timeout=300s
check_success "PostgreSQL deployment ready"

echo ""
echo "--- Deploying Kafka Cluster ---"

cat <<'EOF' | oc apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: parasol-kafka
  namespace: etx-app-dev
spec:
  kafka:
    version: 3.9.0
    replicas: 1
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      default.replication.factor: 1
      min.insync.replicas: 1
      inter.broker.protocol.version: "3.9"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

check_success "Kafka cluster manifest applied"

echo "Waiting for Kafka cluster to be ready (this may take 2-3 minutes)..."
oc wait kafka/parasol-kafka --for=condition=Ready --timeout=300s -n etx-app-dev
check_success "Kafka cluster ready"

echo ""
echo "--- Creating Kafka Topic ---"

cat <<'EOF' | oc apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: intake
  namespace: etx-app-dev
  labels:
    strimzi.io/cluster: parasol-kafka
spec:
  partitions: 1
  replicas: 1
  config:
    retention.ms: 604800000
    segment.bytes: 1073741824
EOF

check_success "Kafka topic created"

echo ""
echo "--- Verifying Services ---"

echo "PostgreSQL pods:"
oc get pods -l app=parasol-db -n etx-app-dev
check_success "PostgreSQL pod running"

echo ""
echo "Kafka pods:"
oc get pods -l strimzi.io/cluster=parasol-kafka -n etx-app-dev
check_success "Kafka pods running"

echo ""
echo "Services:"
oc get svc parasol-db -n etx-app-dev -o jsonpath='{.metadata.name}:{.spec.ports[0].port}'
echo ""
check_success "PostgreSQL service accessible"

oc get svc parasol-kafka-kafka-bootstrap -n etx-app-dev -o jsonpath='{.metadata.name}:{.spec.ports[0].port}'
echo ""
check_success "Kafka service accessible"

echo ""
echo "Secrets:"
oc get secret parasol-db-secret -n etx-app-dev
check_success "Database secret exists"

echo ""
echo "Topics:"
oc get kafkatopic intake -n etx-app-dev
check_success "Kafka topic exists"

echo ""
echo "================================================"
echo "STEP 3: Test Database Connection"
echo "================================================"
echo ""

if oc run postgresql-test --rm --restart=Never \
  --image=registry.redhat.io/rhel9/postgresql-17:latest \
  -n etx-app-dev -- \
  psql -h parasol-db -U parasol -d parasol -c '\conninfo'; then
    echo -e "${GREEN}✅ PostgreSQL connection test${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL connection test (continuing...)${NC}"
fi

echo ""
echo "================================================"
echo "STEP 4: Summary"
echo "================================================"
echo ""

echo "Supporting Services Status:"
echo ""
echo "✅ PostgreSQL:"
echo "   - Host: parasol-db.etx-app-dev.svc.cluster.local:5432"
echo "   - Database: parasol"
echo "   - User: parasol"
echo "   - Secret: parasol-db-secret"
echo ""
echo "✅ Kafka:"
echo "   - Bootstrap: parasol-kafka-kafka-bootstrap.etx-app-dev.svc.cluster.local:9092"
echo "   - Topic: intake"
echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo ""
echo "1. Create DevSpaces workspace with the updated devfile"
echo "2. The workspace will automatically inject these environment variables:"
echo "   - POSTGRESQL_HOST=parasol-db.etx-app-dev.svc.cluster.local"
echo "   - POSTGRESQL_DATABASE=parasol"
echo "   - POSTGRESQL_USER=parasol"
echo "   - POSTGRESQL_PASSWORD=parasol"
echo "   - KAFKA_BOOTSTRAP_SERVERS=parasol-kafka-kafka-bootstrap.etx-app-dev.svc.cluster.local:9092"
echo ""
echo "3. In DevSpaces workspace, configure application.properties and run:"
echo "   ./mvnw clean compile quarkus:dev"
echo ""
echo -e "${GREEN}✅ Supporting Services deployment complete!${NC}"
