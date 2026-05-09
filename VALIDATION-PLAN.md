# Day 2 Lab Validation Plan

## Purpose
This document provides a comprehensive step-by-step validation plan for Day 2 labs. Use this to execute the labs as a student and identify any issues.

## Prerequisites Validation

### Environment Variables Check
```bash
# Verify all required attributes are defined
echo "Cluster Domain: ${openshift_cluster_ingress_domain}"
echo "GitLab URL: ${gitlab_url}"
echo "Keycloak URL: ${keycloak_url}"
echo "Vault URL: ${vault_url}"
echo "DevSpaces URL: ${devspaces_url}"
```

### Cluster Access Validation
```bash
# Login to OpenShift
oc login --server=${openshift_api_url} --username=${user} --password=${password}

# Verify cluster version
oc version
# EXPECTED: OpenShift 4.20 or higher

# Check namespace exists
oc get namespace etx-app-dev
# EXPECTED: Active namespace

# Check permissions
oc auth can-i create deployment -n etx-app-dev
# EXPECTED: yes
```

---

## Lab 1 - Step 1: Environment Overview

### File: `day2-lab1-environment.adoc`

#### Validation Checklist:
- [ ] Can access OpenShift console at {openshift_console_url}
- [ ] Can access GitLab at {gitlab_url}
- [ ] Can login to GitLab with Keycloak (platform-developer / openshift)
- [ ] Can access Keycloak at {keycloak_url}
- [ ] Can access Vault at {vault_url}
- [ ] Can access Quay at {quay_url}

#### Commands to Execute:
```bash
# Clone the repository
cd ~
git clone ${gitlab_url}/software-factory/etx_app_base_app.git
cd etx_app_base_app

# VERIFY: Repository clones successfully
# EXPECTED: Repository directory created
ls -la

# Verify cluster access
oc whoami --show-server
# EXPECTED: Shows API URL matching {openshift_api_url}

oc project etx-app-dev
# EXPECTED: Switches to etx-app-dev namespace
```

#### Expected Results:
✅ Repository cloned successfully  
✅ GitLab OAuth authentication works  
✅ Namespace etx-app-dev exists and is accessible  

#### Common Failure Scenarios:
❌ **Git clone fails**: Check GitLab URL, verify network access, verify Keycloak OAuth  
❌ **Namespace not found**: Verify bootstrap ran correctly, check with admin  
❌ **Permission denied**: Check RBAC, verify user has access to namespace  

---

## Lab 1 - Step 2: DevSpaces and IDE Setup

### File: `day2-lab1-devspaces.adoc`

#### Validation Checklist:
- [ ] devfile.yaml created in repository
- [ ] devfile includes Testcontainers environment variables
- [ ] Workspace created successfully
- [ ] Git integration works
- [ ] AI assistant (Continue) configured
- [ ] Podman available in workspace
- [ ] Quarkus Dev Services starts successfully

#### Commands to Execute:

**Step 1: Create devfile**
```bash
cd ~/etx_app_base_app

# Create devfile.yaml with content from lab guide
cat > devfile.yaml <<'EOF'
schemaVersion: 2.2.0
metadata:
  name: etx-app-base-app
components:
  - name: development-tooling
    container:
      image: quay.io/devfile/universal-developer-image:ubi9-latest
      env:
        - name: QUARKUS_HTTP_HOST
          value: "0.0.0.0"
        - name: MAVEN_OPTS
          value: "-Dmaven.repo.local=/home/user/.m2/repository"
        - name: DOCKER_HOST
          value: "unix:///run/user/10001/podman/podman.sock"
        - name: TESTCONTAINERS_RYUK_DISABLED
          value: "true"
        - name: TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE
          value: "/run/user/10001/podman/podman.sock"
      memoryLimit: 5Gi
      cpuLimit: 2500m
      volumeMounts:
        - name: m2
          path: /home/user/.m2
      endpoints:
        - name: quarkus-dev
          targetPort: 8080
          exposure: public
          protocol: https
        - name: debug
          targetPort: 5005
          exposure: none
  - name: m2
    volume:
      size: 1G
commands:
  - id: package
    exec:
      label: "1. Package the application"
      component: development-tooling
      commandLine: "./mvnw package"
      group:
        kind: build
        isDefault: true
  - id: start-dev
    exec:
      label: "2. Start Development mode (Hot reload + debug)"
      component: development-tooling
      commandLine: "./mvnw compile quarkus:dev"
      group:
        kind: run
        isDefault: true
  - id: init-continue
    exec:
      label: "Initialize Continue config"
      component: development-tooling
      workingDir: /home/user
      commandLine: |
        mkdir -p /home/user/.continue
        cat > /home/user/.continue/config.yaml << 'INNEREOF'
        name: Continue Config
        version: 0.0.1
        models:
          - name: qwen3-14b
            provider: vllm
            model: qwen3-14b
            apiKey: ${LLM_API_KEY}
            apiBase: ${LLM_BASE_URL}
            roles:
              - chat
        INNEREOF
      group:
        kind: build
events:
  postStart:
    - init-continue
EOF

# Verify devfile created
cat devfile.yaml | grep -E "DOCKER_HOST|TESTCONTAINERS"
# EXPECTED: Should show the 3 Testcontainers environment variables

# Commit and push
git add devfile.yaml
git commit -m "feat: add devfile with Continue AI assistant"
git push
# EXPECTED: Successful push to GitLab
```

**Step 2: Get Dashboard URL**
```bash
oc get checluster/devspaces -n openshift-devspaces \
  -o jsonpath='{.status.cheURL}'
# EXPECTED: Returns DevSpaces URL
# EXAMPLE OUTPUT: https://devspaces.apps.cluster-abc123.dynamic.redhatworkshops.io
```

**Step 3: Create Workspace (Manual - Browser)**
- Open the DevSpaces URL from previous command
- Click "Create Workspace"
- Import from Git: paste GitLab repo URL
- Click "Create & Open"
- EXPECTED: Workspace starts successfully (may take 3-5 minutes first time)

**Step 4: Verify Git Integration (In DevSpaces Terminal)**
```bash
# In DevSpaces workspace terminal
pwd
# EXPECTED: /projects/etx_app_base_app

git remote -v
# EXPECTED: Shows GitLab origin

git branch --show-current
# EXPECTED: main

# Test push
echo "# Test" >> README.md
git add README.md
git commit -m "docs: verify Dev Spaces Git integration"
git push
# EXPECTED: Successful push (may prompt for OAuth if not configured)
```

**Step 5: Verify AI Assistant**
```bash
# Verify environment variables
echo $LLM_API_KEY
# EXPECTED: Shows API key value

echo $LLM_BASE_URL
# EXPECTED: https://litellm-prod.apps.maas.redhatworkshops.io

# Verify Continue config was created
cat ~/.continue/config.yaml
# EXPECTED: Shows Continue configuration with qwen3-14b model
```

**Step 6: Verify Nested Containers**
```bash
podman version
# EXPECTED: Shows Podman version 4.x or higher

podman run --rm registry.access.redhat.com/ubi9-minimal:latest echo "Nested containers work"
# EXPECTED: Prints "Nested containers work"
```

**Step 7: CRITICAL - Verify Testcontainers Configuration**
```bash
# Verify Podman socket path
podman info --format '{{.Host.RemoteSocket.Path}}'
# EXPECTED: /run/user/10001/podman/podman.sock (or similar UID)

# Verify environment variables are set
echo "DOCKER_HOST: $DOCKER_HOST"
echo "TESTCONTAINERS_RYUK_DISABLED: $TESTCONTAINERS_RYUK_DISABLED"
echo "TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE: $TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE"
# EXPECTED: All three should show values from devfile
```

**Step 8: Run Quarkus Dev Services**
```bash
./mvnw compile quarkus:dev
# EXPECTED: 
# - Maven downloads dependencies
# - Quarkus starts in dev mode
# - Dev Services detects PostgreSQL need
# - Testcontainers starts PostgreSQL container via Podman
# - Application starts on port 8080
# - Browser notification shows endpoint URL

# WATCH FOR ERRORS:
# ❌ "Docker not found" - Testcontainers config missing
# ❌ "Could not find a valid Docker environment" - DOCKER_HOST not set
# ❌ "Cannot connect to the Docker daemon" - Podman socket not running
# ❌ "Ryuk container failed to start" - TESTCONTAINERS_RYUK_DISABLED not set
```

#### Expected Results:
✅ devfile.yaml committed to repository  
✅ Workspace starts without errors  
✅ Git push/pull works via OAuth  
✅ Continue extension configured with LLM access  
✅ Podman available and can run containers  
✅ **Quarkus Dev Services starts PostgreSQL successfully**  
✅ Application accessible on port 8080  

#### Common Failure Scenarios:
❌ **Workspace fails to start**: Check CheCluster CR, check pod logs in user namespace  
❌ **Git OAuth fails**: Verify GitLab OAuth secret created, check CheCluster gitServices config  
❌ **LLM variables not set**: Check continue-llm-credentials secret in openshift-devspaces namespace  
❌ **Podman not available**: Verify CheCluster has `disableContainerRunCapabilities: false`  
❌ **Quarkus Dev Services fails with Docker error**: **THIS IS THE CRITICAL FIX** - Verify devfile has DOCKER_HOST, TESTCONTAINERS_RYUK_DISABLED, TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE  
❌ **PostgreSQL container fails to start**: Check Podman socket, check logs with `podman ps -a`  

---

## Lab 1 - Step 3: Supporting Services

### File: `day2-lab1-supporting-services.adoc`

#### Validation Checklist:
- [ ] Vault is accessible (pre-deployed)
- [ ] OpenShift Pipelines operator installed
- [ ] Tekton pods running
- [ ] AMQ Streams operator installed
- [ ] OpenTelemetry operator installed
- [ ] OpenTelemetry collector deployed
- [ ] Instrumentation resource created

#### Commands to Execute:

**Verify Vault (Pre-deployed)**
```bash
# Check Vault accessibility
curl -k ${vault_url}/v1/sys/health
# EXPECTED: JSON response with "initialized": true, "sealed": false

# Login to Vault UI manually
# URL: ${vault_url}
# Method: Keycloak OIDC
# User: platform-developer / openshift
# EXPECTED: Can access Vault UI
```

**Install OpenShift Pipelines**
```bash
# Verify operator installed
oc get csv -n openshift-operators | grep pipelines
# EXPECTED: Shows openshift-pipelines-operator with Succeeded phase

# Check Tekton components
oc get pods -n openshift-pipelines
# EXPECTED: All pods Running (tekton-pipelines-controller, tekton-triggers-controller, etc.)

# Verify tkn CLI (in DevSpaces workspace)
tkn version
# EXPECTED: Shows tkn client and server versions
```

**Install AMQ Streams**
```bash
# Verify operator installed
oc get csv -n openshift-operators | grep amqstreams
# EXPECTED: Shows amqstreams operator with Succeeded phase

# Check CRDs installed
oc get crd | grep kafka
# EXPECTED: Shows Kafka CRDs (kafkas.kafka.strimzi.io, etc.)
```

**Install OpenTelemetry Operator**
```bash
# Verify operator installed
oc get csv -n openshift-operators | grep opentelemetry
# EXPECTED: Shows opentelemetry operator with Succeeded phase

# Deploy collector
oc apply -f - <<'EOF'
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: etx-app-dev
spec:
  mode: deployment
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:
      batch: {}
    exporters:
      logging:
        loglevel: debug
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [logging]
EOF

# Verify collector pod running
oc get pods -l app.kubernetes.io/name=otel-collector-collector -n etx-app-dev
# EXPECTED: Pod in Running state

# Create Instrumentation resource
oc apply -f - <<'EOF'
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: java-instrumentation
  namespace: etx-app-dev
spec:
  exporter:
    endpoint: http://otel-collector-collector:4317
  propagators:
    - tracecontext
    - baggage
  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest
EOF

# Verify Instrumentation created
oc get instrumentation -n etx-app-dev
# EXPECTED: java-instrumentation resource exists
```

#### Expected Results:
✅ Vault accessible and unsealed  
✅ Pipelines operator installed, all pods running  
✅ AMQ Streams operator installed  
✅ OpenTelemetry operator installed  
✅ Collector pod running  
✅ Instrumentation resource created  

#### Common Failure Scenarios:
❌ **Vault sealed**: Contact admin, check bootstrap process  
❌ **Operator fails to install**: Check OperatorHub subscription, check operator pod logs  
❌ **Collector fails to start**: Check YAML syntax, check namespace, check operator logs  
❌ **CRD not found**: Wait for operator to fully install, check CSV phase  

---

## Lab 1 - Step 4: CI Pipeline

### File: `day2-lab1-ci-pipeline.adoc`

#### Validation Checklist:
- [ ] Pipeline workspace PVC created
- [ ] Pipeline ServiceAccount created
- [ ] ServiceAccount has edit permissions
- [ ] Vault fetch task created
- [ ] Pipeline created
- [ ] Manual pipeline run succeeds
- [ ] TriggerBinding created
- [ ] TriggerTemplate created
- [ ] EventListener created
- [ ] EventListener route exposed
- [ ] GitLab webhook configured
- [ ] Webhook triggers pipeline successfully

#### Commands to Execute:

**Create Pipeline Resources**
```bash
# Create workspace PVC and ServiceAccount
oc apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-workspace-pvc
  namespace: etx-app-dev
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline
  namespace: etx-app-dev
EOF

# Grant permissions
oc adm policy add-role-to-user edit \
  system:serviceaccount:etx-app-dev:pipeline \
  -n etx-app-dev

# Verify
oc get pvc pipeline-workspace-pvc -n etx-app-dev
# EXPECTED: PVC in Bound state

oc get sa pipeline -n etx-app-dev
# EXPECTED: ServiceAccount exists
```

**Create Vault Task**
```bash
# Apply Vault fetch task from lab guide
oc apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: vault-fetch-registry-creds
  namespace: etx-app-dev
spec:
  workspaces:
    - name: source
  results:
    - name: registry-server
    - name: registry-username
    - name: registry-password
  steps:
    - name: fetch
      image: registry.access.redhat.com/ubi9/ubi-minimal:latest
      script: |
        #!/bin/sh
        set -e
        microdnf install -y jq && microdnf clean all
        VAULT_ADDR="${vault_url}"
        SA_TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        VAULT_TOKEN=\$(curl -s --request POST \
          "\${VAULT_ADDR}/v1/auth/kubernetes/login" \
          --data "{\"role\":\"pipeline\",\"jwt\":\"\${SA_TOKEN}\"}" \
          | jq -r '.auth.client_token')
        CREDS=\$(curl -s --header "X-Vault-Token: \${VAULT_TOKEN}" \
          "\${VAULT_ADDR}/v1/secret/data/registry")
        echo "\${CREDS}" | jq -r '.data.data.server' \
          | tr -d '\n' > \$(results.registry-server.path)
        echo "\${CREDS}" | jq -r '.data.data.username' \
          | tr -d '\n' > \$(results.registry-username.path)
        echo "\${CREDS}" | jq -r '.data.data.password' \
          | tr -d '\n' > \$(results.registry-password.path)
EOF

# Verify task created
oc get task vault-fetch-registry-creds -n etx-app-dev
# EXPECTED: Task exists
```

**Create Pipeline**
```bash
# Apply pipeline from lab guide (full YAML in day2-lab1-ci-pipeline.adoc lines 106-188)
# Verify pipeline created
oc get pipeline etx-app-base-app-ci -n etx-app-dev
# EXPECTED: Pipeline exists

# Verify referenced tasks exist in openshift-pipelines namespace
oc get task git-clone -n openshift-pipelines
oc get task maven -n openshift-pipelines
oc get task buildah -n openshift-pipelines
# EXPECTED: All three tasks exist
```

**Test Manual Pipeline Run**
```bash
tkn pipeline start etx-app-base-app-ci \
  --namespace etx-app-dev \
  --param git-url=${gitlab_url}/software-factory/etx_app_base_app \
  --param git-revision=main \
  --param image-name=image-registry.openshift-image-registry.svc:5000/etx-app-dev/etx-app-base-app \
  --workspace name=shared-workspace,claimName=pipeline-workspace-pvc \
  --serviceaccount pipeline \
  --showlog

# EXPECTED: Pipeline runs through all tasks:
# 1. clone - Clones git repository
# 2. build-and-test - Runs mvn package
# 3. fetch-creds - Gets registry credentials from Vault
# 4. build-image - Builds container image with buildah

# After completion, verify image was created
oc get imagestream etx-app-base-app -n etx-app-dev
# EXPECTED: ImageStream with tag matching git revision
```

**Setup Tekton Triggers**
```bash
# Create TriggerBinding
oc apply -f - <<'EOF'
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: gitlab-push-binding
  namespace: etx-app-dev
spec:
  params:
    - name: git-url
      value: $(body.repository.git_http_url)
    - name: git-revision
      value: $(body.checkout_sha)
EOF

# Create TriggerTemplate  
oc apply -f - <<'EOF'
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: gitlab-push-template
  namespace: etx-app-dev
spec:
  params:
    - name: git-url
    - name: git-revision
  resourcetemplates:
    - apiVersion: tekton.dev/v1
      kind: PipelineRun
      metadata:
        generateName: etx-app-base-app-ci-
      spec:
        pipelineRef:
          name: etx-app-base-app-ci
        params:
          - name: git-url
            value: $(tt.params.git-url)
          - name: git-revision
            value: $(tt.params.git-revision)
          - name: image-name
            value: image-registry.openshift-image-registry.svc:5000/etx-app-dev/etx-app-base-app
        workspaces:
          - name: shared-workspace
            persistentVolumeClaim:
              claimName: pipeline-workspace-pvc
        taskRunTemplate:
          serviceAccountName: pipeline
EOF

# Create EventListener
oc apply -f - <<'EOF'
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: gitlab-listener
  namespace: etx-app-dev
spec:
  serviceAccountName: pipeline
  triggers:
    - name: gitlab-push
      bindings:
        - ref: gitlab-push-binding
      template:
        ref: gitlab-push-template
EOF

# Expose EventListener
oc expose svc el-gitlab-listener -n etx-app-dev

# Get webhook URL
WEBHOOK_URL=$(oc get route el-gitlab-listener -n etx-app-dev -o jsonpath='{.spec.host}')
echo "Webhook URL: http://${WEBHOOK_URL}"
# EXPECTED: Returns URL like http://el-gitlab-listener-etx-app-dev.apps...

# Verify EventListener pod running
oc get pods -n etx-app-dev | grep el-gitlab-listener
# EXPECTED: Pod in Running state
```

**Configure GitLab Webhook (Manual - Browser)**
1. Login to GitLab: ${gitlab_url}
2. Navigate to: software-factory/etx_app_base_app
3. Go to Settings → Webhooks
4. Add webhook:
   - URL: (paste webhook URL from above)
   - Trigger: Push events
   - SSL verification: Unchecked
5. Click "Add webhook"
6. Click "Test" → "Push events"
7. EXPECTED: Shows "HTTP 200" or "HTTP 201"

**Verify Webhook Trigger**
```bash
# Make a trivial change
cd ~/etx_app_base_app
echo "# CI/CD test" >> README.md
git add README.md
git commit -m "test: webhook trigger"
git push origin main

# Watch for new pipeline run
tkn pipelinerun list -n etx-app-dev
# EXPECTED: New pipelinerun with name etx-app-base-app-ci-xxxxx

# Follow logs
tkn pipelinerun logs -f -n etx-app-dev
# EXPECTED: Pipeline executes automatically

# Verify image tagged with commit SHA
oc get imagestream etx-app-base-app -n etx-app-dev -o json | jq '.status.tags[].tag'
# EXPECTED: Shows commit SHA as tag
```

#### Expected Results:
✅ Pipeline workspace PVC created and bound  
✅ ServiceAccount has permissions  
✅ Vault task can authenticate and fetch secrets  
✅ Manual pipeline run succeeds  
✅ EventListener pod running  
✅ GitLab webhook configured  
✅ **Git push automatically triggers pipeline**  
✅ Image pushed to internal registry with commit SHA tag  

#### Common Failure Scenarios:
❌ **PVC stuck Pending**: Check storage class, check PV availability  
❌ **Vault authentication fails**: Check Vault kubernetes auth configured, check pipeline role exists  
❌ **Clone task fails**: Check Git credentials, check GitLab URL accessible from cluster  
❌ **Maven build fails**: Check pom.xml, check Maven dependencies accessible  
❌ **Buildah fails**: Check ServiceAccount permissions, check image push permissions  
❌ **EventListener pod CrashLoopBackOff**: Check RBAC, check pipeline ServiceAccount  
❌ **Webhook returns 4xx/5xx**: Check route accessible, check EventListener logs  
❌ **Webhook doesn't trigger pipeline**: Check TriggerBinding/Template, check EventListener logs  

---

*[Continue with Lab 1 Steps 5 & 6, and Lab 2 sections...]*

---

## Validation Success Criteria

### Lab 1 Complete Success:
- ✅ DevSpaces workspace fully functional with Quarkus Dev Services
- ✅ CI pipeline triggers on git push
- ✅ Container images built and pushed to registry
- ✅ ArgoCD deployed and managing applications
- ✅ Application deployed to dev environment
- ✅ Promotion pipeline moves images to staging
- ✅ Application running in both dev and staging clusters

### Critical Path Items:
1. **Testcontainers configuration in devfile** (MOST CRITICAL)
2. Vault authentication from pipeline
3. GitLab webhook triggering pipeline
4. ArgoCD syncing from GitOps repo
5. Multi-cluster deployment to staging

## Next Steps
After validation, document:
- [ ] All errors encountered
- [ ] Steps that needed modification
- [ ] Commands that failed
- [ ] Missing prerequisites
- [ ] Timing/timeout issues
- [ ] Permission problems

Create issues/commits for each error found.
