## Breaking Change 🔴

**Complete architectural redesign from local Dev Services to external cluster services.**

This is a **breaking change** that fundamentally changes how students interact with the lab environment.

## Summary

Changes the development workflow from using Quarkus Dev Services (local containers via Testcontainers/Podman) to deploying shared external services (PostgreSQL and Kafka) in the OpenShift cluster.

## Why This Change?

### Problems with Previous Approach (Dev Services + Podman)
❌ Kafka Dev Services incompatible with Podman rootless mode in DevSpaces  
❌ Complex Podman socket configuration required  
❌ Frequent Testcontainers "Docker not found" errors  
❌ Uses community images instead of Red Hat certified images  
❌ Inconsistent with production deployment patterns  
❌ Different for each developer workspace  

### Benefits of New Approach (External Cluster Services)
✅ Uses **only Red Hat certified container images**  
✅ **Consistent** development and production patterns  
✅ **No Podman/Testcontainers configuration** needed  
✅ **Shared services** across all team workspaces  
✅ **Easier to debug** integration issues  
✅ **More realistic** enterprise environment  

## Architecture Changes

### Before (REMOVED ❌)
```
DevSpaces Workspace
├── Podman socket service (init-podman command)
├── PostgreSQL container (Dev Services via Testcontainers)
└── Kafka container (FAILED - incompatible with Podman rootless)
```

### After (NEW ✅)
```
etx-app-dev namespace
├── parasol-db deployment (PostgreSQL 17 - Red Hat certified)
└── parasol-kafka cluster (AMQ Streams 3.9.0)

DevSpaces Workspace
└── Quarkus app → connects to external services via environment variables
```

## Changes Made

### 1. Supporting Services Lab (day2-lab1-supporting-services.adoc)
- ➕ Added PostgreSQL deployment using `registry.redhat.io/rhel9/postgresql-17:latest`
- ➕ Added Kafka cluster deployment using AMQ Streams operator
- ➕ Added Kafka topic creation (`intake`)
- ➕ Added service verification steps
- 📝 Updated to deploy services BEFORE DevSpaces setup

### 2. Lab Workflow Reordering (day2-lab1-environment.adoc)
- 🔄 **Changed lab order:**
  - OLD: Environment → DevSpaces → Supporting Services → CI Pipeline
  - NEW: Environment → **Supporting Services → DevSpaces** → CI Pipeline
- 📝 Added IMPORTANT note about deployment order dependency

### 3. DevSpaces Lab (day2-lab1-devspaces.adoc)
- ❌ **REMOVED** all Testcontainers/Podman socket configuration:
  - Removed `XDG_RUNTIME_DIR` environment variable
  - Removed `DOCKER_HOST` environment variable
  - Removed `TESTCONTAINERS_RYUK_DISABLED` environment variable
  - Removed `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` environment variable
  - Removed `init-podman` postStart command
  - Removed Podman socket troubleshooting section
- ➕ **ADDED** external service connection configuration:
  - Added `POSTGRESQL_HOST` environment variable
  - Added `POSTGRESQL_DATABASE` environment variable
  - Added `POSTGRESQL_USER` environment variable
  - Added `POSTGRESQL_PASSWORD` environment variable
  - Added `KAFKA_BOOTSTRAP_SERVERS` environment variable
- 📝 Updated "Run Quarkus Dev Services" section to "Run Quarkus in Development Mode"
- 📝 Removed Dev Services startup expectations
- 📝 Added external services connection verification

### 4. Devfiles Reference (day2-devspaces-devfiles.adoc)
- 🔄 Updated complete example devfile with external service environment variables
- ❌ Removed Podman/Testcontainers configuration from example
- 📝 Updated callouts to explain external service connection

### 5. MTA Lab (day2-lab2-mta.adoc)
- 🔄 Updated `application.properties` example:
  - Explicitly disable Dev Services: `%dev.quarkus.datasource.devservices.enabled=false`
  - Explicitly disable Kafka Dev Services: `%dev.quarkus.kafka.devservices.enabled=false`
  - Configure external service connections for `%dev` profile
  - Use environment variables for connection details
- 📝 Updated IMPORTANT note to explain Dev Services are disabled

### 6. Validation Suite (validation/)
- ➕ Added `end-to-end-test.sh`: Automated deployment of supporting services
- ➕ Added `devspaces-validation.sh`: Workspace environment validation
- ➕ Added `devfile-validation.yaml`: Reference devfile configuration
- ➕ Added `application.properties`: Reference application configuration
- ➕ Added `README.md`: Complete validation guide with 7-phase checklist

## Migration Impact

### Students Must Now:

**Phase 1 (NEW - REQUIRED FIRST):**
1. Deploy PostgreSQL to `etx-app-dev` namespace
2. Deploy Kafka cluster to `etx-app-dev` namespace
3. Create Kafka topics
4. Verify services are running

**Phase 2 (UPDATED):**
1. Create devfile with **external service** environment variables (NOT Podman config)
2. Push devfile to GitLab
3. Create DevSpaces workspace

**Phase 3 (UPDATED):**
1. Create `application.properties` with:
   - Dev Services explicitly **disabled**
   - External service connections configured
   - Environment variable placeholders
2. Run `./mvnw compile quarkus:dev`
3. Application connects to **external** PostgreSQL and Kafka

### Breaking Changes for Instructors

- 🔴 Lab order MUST be updated in presentation materials
- 🔴 Students need cluster permissions to deploy PostgreSQL and Kafka
- 🔴 Old devfiles with Podman config will NOT work
- 🔴 Screenshots showing Dev Services startup are now incorrect

## Testing & Validation

### Automated Validation
```bash
cd validation
chmod +x end-to-end-test.sh
./end-to-end-test.sh
```

### Manual Validation Checklist
✅ Supporting services (PostgreSQL + Kafka) deploy successfully  
✅ DevSpaces workspace injects correct environment variables  
✅ Application connects to external PostgreSQL (not Dev Services)  
✅ Application connects to external Kafka (not Dev Services)  
✅ NO Testcontainers/Docker errors  
✅ NO "Dev Services for postgresql started" messages  
✅ Application accessible on port 8080  

### Success Criteria
The validation is successful when a student can:
1. Deploy supporting services following lab instructions
2. Create workspace with updated devfile
3. Run Quarkus dev mode without Testcontainers errors
4. Application connects to external services
5. Database tables created in external PostgreSQL
6. Kafka consumers registered in external Kafka

## Files Changed

```
content/modules/ROOT/pages/
├── day2-lab1-environment.adoc         (reordered workflow)
├── day2-lab1-supporting-services.adoc (added PostgreSQL + Kafka deployment)
├── day2-lab1-devspaces.adoc           (removed Dev Services, added external services)
├── day2-devspaces-devfiles.adoc       (updated example devfile)
└── day2-lab2-mta.adoc                 (updated application.properties example)

validation/
├── README.md                          (complete validation guide)
├── end-to-end-test.sh                 (automated deployment script)
├── devspaces-validation.sh            (workspace validation script)
├── devfile-validation.yaml            (reference devfile)
└── application.properties             (reference configuration)
```

## Rollout Strategy

### Recommended Approach
1. ✅ Merge this PR to a staging branch first
2. ✅ Run full validation with test students
3. ✅ Update instructor materials and presentations
4. ✅ Update any existing student workspaces
5. ✅ Merge to main and announce changes

### Communication Required
- 📧 Email instructors about lab order change
- 📧 Email students about breaking changes if labs in progress
- 📝 Update any video tutorials or recordings
- 📝 Update presentation slides

## References

- [Red Hat PostgreSQL Container Images](https://catalog.redhat.com/software/containers/rhel9/postgresql-17/673e4f1b6c37aaa1e99b88de)
- [Red Hat AMQ Streams Documentation](https://access.redhat.com/documentation/en-us/red_hat_amq_streams)
- [Quarkus Configuration Profiles](https://quarkus.io/guides/config-reference#profiles)
- [DevSpaces Environment Variables](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/3.17/html/user_guide/devfile-introduction#adding-components-to-a-devfile)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
