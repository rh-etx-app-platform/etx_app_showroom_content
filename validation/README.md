# End-to-End Validation - ETX App Showroom Content

This validation follows the **updated** Day 2 Lab 1 workflow with external cluster services.

## Architecture Overview

**NEW Architecture (External Services):**
- ✅ PostgreSQL runs in `etx-app-dev` namespace (Red Hat certified image)
- ✅ Kafka runs in `etx-app-dev` namespace (AMQ Streams)
- ✅ DevSpaces workspace connects to external services
- ✅ Dev Services (Testcontainers) are **DISABLED**

**OLD Architecture (Removed):**
- ❌ PostgreSQL Dev Services in workspace (Podman container)
- ❌ Kafka Dev Services in workspace (incompatible with Podman rootless)
- ❌ Testcontainers/Podman socket configuration

## Prerequisites

- OpenShift cluster access
- `oc` CLI logged in
- `etx-app-dev` namespace created
- AMQ Streams operator installed (for Kafka)
- GitLab access to push devfile

## Validation Steps

### Phase 1: Deploy Supporting Services (Lab 1 Step 2)

Follow instructions from: `content/modules/ROOT/pages/day2-lab1-supporting-services.adoc`

```bash
# Execute the automated script
cd validation
chmod +x end-to-end-test.sh
./end-to-end-test.sh
```

**Manual alternative:**

1. Deploy PostgreSQL:
   ```bash
   oc apply -f - <<'EOF'
   [PostgreSQL YAML from supporting-services.adoc]
   EOF
   ```

2. Deploy Kafka cluster:
   ```bash
   oc apply -f - <<'EOF'
   [Kafka YAML from supporting-services.adoc]
   EOF
   ```

3. Create Kafka topic:
   ```bash
   oc apply -f - <<'EOF'
   [KafkaTopic YAML from supporting-services.adoc]
   EOF
   ```

**Expected Results:**
- PostgreSQL pod running: `oc get pods -l app=parasol-db`
- Kafka pods running: `oc get pods -l strimzi.io/cluster=parasol-kafka`
- Services accessible:
  - `parasol-db:5432`
  - `parasol-kafka-kafka-bootstrap:9092`
- Topic created: `oc get kafkatopic intake`

### Phase 2: Create Devfile (Lab 1 Step 3)

Follow instructions from: `content/modules/ROOT/pages/day2-lab1-devspaces.adoc`

```bash
# In your etx_app_base_app repository
cd ~/etx_app_base_app

# Copy the validated devfile
cp /path/to/validation/devfile-validation.yaml ./devfile.yaml

# Commit and push
git add devfile.yaml
git commit -m "feat: add devfile with external services configuration"
git push
```

**Validation:**
- Devfile contains these environment variables:
  - `POSTGRESQL_HOST=parasol-db.etx-app-dev.svc.cluster.local`
  - `POSTGRESQL_DATABASE=parasol`
  - `POSTGRESQL_USER=parasol`
  - `POSTGRESQL_PASSWORD=parasol`
  - `KAFKA_BOOTSTRAP_SERVERS=parasol-kafka-kafka-bootstrap.etx-app-dev.svc.cluster.local:9092`
- NO Podman/Testcontainers variables (`XDG_RUNTIME_DIR`, `DOCKER_HOST`, etc.)
- NO `init-podman` command in events

### Phase 3: Create DevSpaces Workspace

Follow instructions from: `content/modules/ROOT/pages/day2-lab1-devspaces.adoc`

1. Get DevSpaces URL:
   ```bash
   oc get checluster/devspaces -n openshift-devspaces \
     -o jsonpath='{.status.cheURL}'
   ```

2. Create workspace from GitLab URL:
   ```
   <devspaces-url>/#<gitlab-url>/software-factory/etx_app_base_app/-/tree/main?devfilePath=/
   ```

3. Wait for workspace to start

**Validation in Workspace:**
```bash
# Verify environment variables are injected
echo $POSTGRESQL_HOST
# Expected: parasol-db.etx-app-dev.svc.cluster.local

echo $POSTGRESQL_DATABASE
# Expected: parasol

echo $KAFKA_BOOTSTRAP_SERVERS
# Expected: parasol-kafka-kafka-bootstrap.etx-app-dev.svc.cluster.local:9092

# Test network connectivity
nc -zv $POSTGRESQL_HOST 5432
# Expected: Connection succeeded

# Verify Podman is NOT required for this workflow
podman version
# Note: Podman is still available in UDI, but NOT used for Dev Services
```

### Phase 4: Configure Application

```bash
# In DevSpaces workspace terminal
cd /projects/etx_app_base_app

# Copy the validated application.properties
cat > src/main/resources/application.properties << 'EOF'
quarkus.http.port=8080

# Disable Dev Services (use external services from Supporting Services lab)
%dev.quarkus.datasource.devservices.enabled=false
%dev.quarkus.kafka.devservices.enabled=false

# Development configuration (connects to external services in cluster)
%dev.quarkus.datasource.db-kind=postgresql
%dev.quarkus.datasource.username=${POSTGRESQL_USER:parasol}
%dev.quarkus.datasource.password=${POSTGRESQL_PASSWORD:parasol}
%dev.quarkus.datasource.jdbc.url=jdbc:postgresql://${POSTGRESQL_HOST:parasol-db.etx-app-dev.svc.cluster.local}:5432/${POSTGRESQL_DATABASE:parasol}
%dev.kafka.bootstrap.servers=${KAFKA_BOOTSTRAP_SERVERS:parasol-kafka-kafka-bootstrap.etx-app-dev.svc.cluster.local:9092}

# Production configuration
quarkus.datasource.db-kind=postgresql
%prod.quarkus.datasource.username=${POSTGRESQL_USER}
%prod.quarkus.datasource.password=${POSTGRESQL_PASSWORD}
%prod.quarkus.datasource.jdbc.url=jdbc:postgresql://${POSTGRESQL_HOST:parasol-db}:5432/${POSTGRESQL_DATABASE:parasol}
%prod.kafka.bootstrap.servers=${KAFKA_BOOTSTRAP_SERVERS:parasol-kafka-kafka-bootstrap:9092}

# Hibernate
quarkus.hibernate-orm.database.generation=drop-and-create
quarkus.hibernate-orm.sql-load-script=import.sql
EOF
```

**Validation:**
- Dev Services are explicitly **disabled**
- Configuration uses environment variables for connection details
- Both `%dev` and `%prod` profiles point to external services

### Phase 5: Run Quarkus Dev Mode

```bash
# Clean build
./mvnw clean compile quarkus:dev
```

**Expected Output:**

```
[INFO] --- quarkus:3.17.5:dev (default-cli) @ parasol-reimagined ---
Listening for transport dt_socket at address: 5005
__  ____  __  _____   ___  __ ____  ______ 
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/ 
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \   
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/   
2026-05-09 20:30:00,000 INFO  [io.quarkus] (Quarkus Main Thread) parasol-reimagined 1.0.0-SNAPSHOT on JVM (powered by Quarkus 3.17.5) started in 8.123s. Listening on: http://localhost:8080
```

**Key Success Indicators:**

✅ **NO Testcontainers/Docker errors:**
- Should NOT see: "Previous attempts to find a Docker environment failed"
- Should NOT see: "Docker not found"
- Should NOT see: "Unix socket defined in DOCKER_HOST is not writable"

✅ **NO Dev Services startup:**
- Should NOT see: "Dev Services for default datasource (postgresql) started"
- Should NOT see: "Dev Services for Kafka started"
- Should NOT see: "Container ... started in PTX.XXXS"

✅ **Successful external service connections:**
- Hibernate creates tables (check logs)
- Kafka channels configured: "Configuring channel 'emails-in' to be managed by connector 'smallrye-kafka'"
- Application starts without errors

✅ **Application accessible:**
```bash
curl http://localhost:8080
# Or click the endpoint in DevSpaces
```

### Phase 6: Verify Database Connection

```bash
# In DevSpaces workspace, while Quarkus is running

# Check database tables were created
oc exec -it deployment/parasol-db -n etx-app-dev -- \
  psql -U parasol -d parasol -c '\dt'

# Expected: Tables from Hibernate schema
```

### Phase 7: Verify Kafka Connection

```bash
# Check Kafka consumer group
oc exec -it parasol-kafka-kafka-0 -n etx-app-dev -- \
  bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list

# Expected: Consumer group from application
```

## Validation Checklist

### ✅ Phase 1: Supporting Services
- [ ] PostgreSQL deployment created
- [ ] PostgreSQL pod running
- [ ] PostgreSQL service accessible
- [ ] Database secret exists
- [ ] Kafka cluster created
- [ ] Kafka pods running (kafka, zookeeper, entity-operator)
- [ ] Kafka service accessible
- [ ] Kafka topic `intake` exists

### ✅ Phase 2: Devfile
- [ ] Devfile created in repository
- [ ] Contains external service environment variables
- [ ] NO Podman/Testcontainers configuration
- [ ] NO init-podman command
- [ ] Devfile committed and pushed to GitLab

### ✅ Phase 3: DevSpaces Workspace
- [ ] Workspace created successfully
- [ ] Environment variables injected correctly
- [ ] Network connectivity to PostgreSQL verified
- [ ] Network connectivity to Kafka verified

### ✅ Phase 4: Application Configuration
- [ ] application.properties created
- [ ] Dev Services explicitly disabled
- [ ] External service connection configured
- [ ] Environment variable placeholders used

### ✅ Phase 5: Quarkus Dev Mode
- [ ] Build completes successfully
- [ ] NO Testcontainers errors
- [ ] NO Dev Services startup messages
- [ ] Application starts successfully
- [ ] Listening on port 8080
- [ ] Hibernate connects to PostgreSQL
- [ ] Kafka channels configured

### ✅ Phase 6: Runtime Verification
- [ ] Application endpoint accessible
- [ ] Database tables created
- [ ] Kafka consumer group registered
- [ ] Application functions correctly

## Troubleshooting

### Issue: "Connection refused" to PostgreSQL or Kafka

**Cause:** Supporting services not deployed or not ready

**Solution:**
```bash
# Verify services are running
oc get pods -n etx-app-dev -l app=parasol-db
oc get pods -n etx-app-dev -l strimzi.io/cluster=parasol-kafka

# Check service endpoints
oc get svc parasol-db parasol-kafka-kafka-bootstrap -n etx-app-dev
```

### Issue: Environment variables not set in workspace

**Cause:** Devfile not pushed to GitLab before workspace creation

**Solution:**
1. Delete workspace
2. Verify devfile is in GitLab repository
3. Create new workspace from updated repository

### Issue: Old Podman/Testcontainers errors still appearing

**Cause:** Workspace created with old devfile

**Solution:**
1. Delete workspace completely
2. Pull latest devfile from GitLab
3. Create fresh workspace

### Issue: "Dev Services for postgresql started"

**Cause:** Dev Services not disabled in application.properties

**Solution:**
Verify these lines exist:
```properties
%dev.quarkus.datasource.devservices.enabled=false
%dev.quarkus.kafka.devservices.enabled=false
```

## Success Criteria

The validation is successful when:

1. ✅ Supporting services (PostgreSQL + Kafka) deployed and running
2. ✅ DevSpaces workspace created with external service configuration
3. ✅ Application starts without Testcontainers/Podman errors
4. ✅ Application connects to external PostgreSQL and Kafka
5. ✅ Application is accessible on port 8080
6. ✅ Database tables created by Hibernate
7. ✅ Kafka consumers registered

## Comparison: Old vs New

### Old Architecture (BROKEN)
```
DevSpaces Workspace
├── Podman socket service
├── PostgreSQL container (Dev Services via Testcontainers)
└── Kafka container (FAILED - incompatible with Podman rootless)
```

**Problems:**
- Complex Podman socket configuration
- Kafka image incompatible
- Testcontainers errors
- Inconsistent with production

### New Architecture (WORKING)
```
etx-app-dev namespace
├── parasol-db deployment (PostgreSQL)
└── parasol-kafka cluster (AMQ Streams)

DevSpaces Workspace
└── Quarkus app → connects to external services
```

**Benefits:**
- Simple configuration
- All services work
- Matches production patterns
- Uses only Red Hat certified images

## Next Steps

After successful validation, students can proceed to:
1. Lab 1 Step 4: Create CI pipeline with Tekton
2. Lab 1 Step 5: Deploy Argo CD for application delivery
3. Lab 1 Step 6: Configure multi-cluster promotion
