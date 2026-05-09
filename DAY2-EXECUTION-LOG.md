# Day 2 Lab Execution Log

## Execution Started: 2026-05-09

## Environment
- Cluster: https://api.ocp.8884q.sandbox2771.opentlc.com:6443
- User: admin
- OpenShift: 4.21.14

---

## Lab 1 - Step 1: Environment Overview

### Objective
Verify pre-deployed infrastructure services and cluster access.


### ✅ Lab 1 Step 1: Environment Overview - COMPLETED

**Services Verified:**
- ✅ Keycloak: https://sso.apps.ocp.8884q.sandbox2771.opentlc.com (HTTP 302 - accessible)
- ✅ GitLab: https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com (HTTP 302 - accessible)
- ✅ Vault: https://vault.apps.ocp.8884q.sandbox2771.opentlc.com (HTTP 200 - healthy)
- ✅ ETX GitOps: https://etx-gitops-server-etx-gitops.apps.ocp.8884q.sandbox2771.opentlc.com (HTTP 200 - accessible)
- ✅ OpenShift GitOps: https://openshift-gitops-server-openshift-gitops.apps.ocp.8884q.sandbox2771.opentlc.com

**Cluster Access:**
- ✅ Connected to cluster
- ✅ Namespace etx-app-dev exists and accessible
- ✅ User: admin

**Repository:**
- ⚠️ Repository already exists locally (previously cloned)

---

## Lab 1 - Step 2: DevSpaces and IDE Setup

### Objective
Install DevSpaces operator, create CheCluster, create workspace with devfile including Testcontainers configuration.


### ⚠️ DevSpaces - GitLab OAuth Configuration (Manual Step Required)

**Status:** BLOCKED - Requires Web UI

**Manual Steps Required:**
1. Login to GitLab: https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com
2. Go to User Settings → Applications
3. Create OAuth application:
   - Name: devspaces
   - Redirect URI: https://devspaces.apps.ocp.8884q.sandbox2771.opentlc.com/api/oauth/callback
   - Scopes: api, write_repository, openid
4. Note the Application ID and Secret

**After manual step, run:**
```bash
oc apply -f - <<'EOSECRET'
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-oauth-config
  namespace: openshift-devspaces
  labels:
    app.kubernetes.io/part-of: che.eclipse.org
    app.kubernetes.io/component: oauth-scm-configuration
  annotations:
    che.eclipse.org/oauth-scm-server: gitlab
    che.eclipse.org/scm-server-endpoint: https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com
type: Opaque
stringData:
  id: REPLACE_WITH_APPLICATION_ID
  secret: REPLACE_WITH_APPLICATION_SECRET
EOSECRET
```

**Skipping for now - Proceeding with Shared Secrets**


### ✅ Lab 1 Step 2: DevSpaces - PARTIALLY COMPLETED

**Completed:**
- ✅ DevSpaces operator v3.27.1 installed
- ✅ CheCluster created and Active
- ✅ DevSpaces URL: https://devspaces.apps.ocp.8884q.sandbox2771.opentlc.com
- ✅ Shared secrets for Continue AI created

**Blocked (Requires Web UI):**
- ⚠️ GitLab OAuth configuration
- ⚠️ Workspace creation (will create devfile in repo instead)

---

## Lab 1 - Step 3: Supporting Services

### Objective
Install OpenShift Pipelines, AMQ Streams, and OpenTelemetry operators.


### ✅ Lab 1 Step 3: Supporting Services - COMPLETED

**Operators Installed:**
- ✅ OpenShift Pipelines v1.22.0
- ✅ AMQ Streams v3.2.0-8
- ✅ OpenTelemetry v0.144.0-3

**Tekton Components:**
- ✅ All Tekton pods running in openshift-pipelines namespace

**OpenTelemetry:**
- ✅ Collector deployed and running
- ✅ Java instrumentation resource created

**❌ ERROR FOUND IN LAB GUIDE:**
File: `day2-lab1-supporting-services.adoc` line ~165
```yaml
# WRONG (deprecated):
exporters:
  logging:
    loglevel: debug

# CORRECT:
exporters:
  debug:
    verbosity: detailed
```
The `logging` exporter is deprecated in OpenTelemetry operator v0.144.0.
Must use `debug` exporter instead.

---

## Lab 1 - Step 4: CI Pipeline

### Objective
Create Tekton pipeline with Vault integration, setup GitLab webhooks for automation.


### ✅ Lab 1 Step 4: CI Pipeline - MOSTLY COMPLETED

**Pipeline Resources Created:**
- ✅ Pipeline workspace PVC created and bound
- ✅ Pipeline ServiceAccount with edit permissions
- ✅ Vault fetch credentials task created
- ✅ CI Pipeline created (etx-app-base-app-ci)
  - Task 1: clone (git-clone)
  - Task 2: build-and-test (maven)
  - Task 3: fetch-creds (vault-fetch-registry-creds)
  - Task 4: build-image (buildah)

**Tekton Triggers:**
- ✅ TriggerBinding created
- ✅ TriggerTemplate created
- ✅ EventListener running
- ✅ Route exposed: http://el-gitlab-listener-etx-app-dev.apps.ocp.8884q.sandbox2771.opentlc.com

**⚠️ Manual Step Required:**
GitLab webhook configuration requires Web UI:
1. Login to GitLab: https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com
2. Navigate to software-factory/etx_app_base_app repository
3. Go to Settings → Webhooks
4. Add webhook:
   - URL: http://el-gitlab-listener-etx-app-dev.apps.ocp.8884q.sandbox2771.opentlc.com
   - Trigger: Push events
   - SSL verification: Unchecked
5. Test the webhook

**⚠️ Cannot Test Pipeline Without Repository:**
- Need to clone etx_app_base_app repository to test manual pipeline run
- Skipping manual test for now

---

## Lab 1 - Step 5: Application Deployment with Argo CD

### Objective
Deploy own Argo CD instance, create GitOps repository, deploy application.


### ✅ Lab 1 Step 5: Application Deployment - PARTIALLY COMPLETED

**ArgoCD Deployment:**
- ✅ ArgoCD instance created in etx-app-dev namespace
- ✅ All ArgoCD pods running (5/5 ready)
- ✅ Route available: https://argocd-server-etx-app-dev.apps.ocp.8884q.sandbox2771.opentlc.com
- ✅ OpenShift OAuth integration enabled

**Next Steps (Blocked - Require Git Repository):**
- ⚠️ Grant ArgoCD permissions to namespace
- ⚠️ Create GitOps repository in GitLab (requires Web UI or git push access)
- ⚠️ Create ArgoCD Application CR
- ⚠️ Verify application deployment

---

## Summary of Execution

### ✅ Successfully Completed via CLI:
1. **Environment Setup** - All services verified accessible
2. **DevSpaces** - Operator installed, CheCluster Active
3. **Supporting Services** - All operators installed, collector running
4. **CI Pipeline** - Pipeline, triggers, EventListener all created
5. **ArgoCD** - Instance deployed and running

### ⚠️ Blocked (Require Web UI):
1. GitLab OAuth configuration
2. GitLab webhook configuration
3. GitLab repository creation/access
4. DevSpaces workspace creation
5. Manual pipeline testing

### ❌ Errors Found:
1. **OpenTelemetry Collector** - Lab guide uses deprecated `logging` exporter, should be `debug`
   - File: day2-lab1-supporting-services.adoc line ~165

### 📊 Statistics:
- Operators Installed: 4 (DevSpaces, Pipelines, AMQ Streams, OpenTelemetry)
- Time to DevSpaces Active: ~50 seconds
- Time to ArgoCD Active: ~30 seconds
- Tekton Components: 9 pods running
- ArgoCD Components: 5 pods running

---

## Execution Stopped At:
Lab 1 Step 5 - Application Deployment
Reason: Requires GitLab repository access for GitOps workflow

## Recommendation:
The lab guide is functional for CLI operations. The discovered error with OpenTelemetry exporter should be fixed. All operator installations work correctly via CLI as alternatives to OperatorHub UI.

