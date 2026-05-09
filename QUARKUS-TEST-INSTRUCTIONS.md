# Instrucciones para Probar Aplicación Quarkus en DevSpaces

## Estado Actual del Ambiente

✅ **DevSpaces**: Active  
✅ **URL**: https://devspaces.apps.ocp.8884q.sandbox2771.opentlc.com  
✅ **GitLab**: https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com  
✅ **Testcontainers Config**: Incluida en devfile  

---

## 📋 Opción 1: Crear Workspace Desde GitLab (Recomendado)

### Paso 1: Verificar/Crear el Repositorio en GitLab

**1.1** Abre GitLab en tu browser:
```
https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com
```

**1.2** Login con Keycloak:
- Click en **"Sign in with OpenID Connect"**
- User: `platform-developer`
- Password: `openshift`

**1.3** Verifica que existe el repositorio:
```
software-factory/etx_app_base_app
```

Si NO existe, necesitas:
- Crear el proyecto en GitLab
- O usar un repositorio de ejemplo

### Paso 2: Agregar el Devfile al Repositorio

**2.1** Clona el repositorio localmente (o usa la Web UI de GitLab):
```bash
git clone https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com/software-factory/etx_app_base_app.git
cd etx_app_base_app
```

**2.2** Copia el devfile al repositorio:
```bash
# El devfile está en /tmp/quarkus-test/devfile.yaml
# O copia el contenido del devfile mostrado arriba

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
```

**2.3** Commit y push:
```bash
git add devfile.yaml
git commit -m "feat: add devfile with Testcontainers/Podman configuration"
git push origin main
```

### Paso 3: Crear Workspace en DevSpaces

**3.1** Abre DevSpaces Dashboard:
```
https://devspaces.apps.ocp.8884q.sandbox2771.opentlc.com
```

**3.2** Login con OpenShift OAuth (usuario admin)

**3.3** Opción A - URL Directa (MÁS FÁCIL):
Abre esta URL en tu browser:
```
https://devspaces.apps.ocp.8884q.sandbox2771.opentlc.com/#https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com/software-factory/etx_app_base_app
```

**3.3** Opción B - Dashboard Manual:
- Click en **"Create Workspace"**
- En "Import from Git", pega:
  ```
  https://gitlab.apps.ocp.8884q.sandbox2771.opentlc.com/software-factory/etx_app_base_app
  ```
- Click **"Create & Open"**

**3.4** Espera a que el workspace inicie (3-5 minutos la primera vez)

---

## 🚀 Opción 2: Crear Workspace Desde Devfile Público (Si no tienes acceso a GitLab)

Si no puedes acceder al repositorio GitLab, puedes crear un workspace con un repositorio de ejemplo:

**URL para crear workspace con Quarkus de ejemplo:**
```
https://devspaces.apps.ocp.8884q.sandbox2771.opentlc.com/#https://github.com/quarkusio/quarkus-quickstarts?devfilePath=.devfile-getting-started.yaml
```

⚠️ **IMPORTANTE**: Este devfile NO tiene la configuración de Testcontainers/Podman. Necesitarás agregarla manualmente.

---

## 🧪 Paso 4: Ejecutar Quarkus Dev Services

Una vez que el workspace esté abierto:

### 4.1 Verificar Variables de Entorno

Abre una terminal en el workspace y ejecuta:

```bash
# Verificar que las variables de Testcontainers están configuradas
echo "DOCKER_HOST: $DOCKER_HOST"
echo "TESTCONTAINERS_RYUK_DISABLED: $TESTCONTAINERS_RYUK_DISABLED"
echo "TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE: $TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE"
```

**✅ Esperado:**
```
DOCKER_HOST: unix:///run/user/10001/podman/podman.sock
TESTCONTAINERS_RYUK_DISABLED: true
TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE: /run/user/10001/podman/podman.sock
```

❌ **Si las variables NO están configuradas:**
- El devfile no se aplicó correctamente
- Reinicia el workspace desde el Dashboard

### 4.2 Verificar Podman

```bash
# Verificar que Podman está disponible
podman version

# Verificar socket de Podman
podman info --format '{{.Host.RemoteSocket.Path}}'

# Probar nested containers
podman run --rm registry.access.redhat.com/ubi9-minimal:latest echo "Nested containers work"
```

**✅ Esperado:**
- Podman version muestra versión 4.x o superior
- Socket path: `/run/user/10001/podman/podman.sock`
- El test container imprime "Nested containers work"

### 4.3 Ejecutar Quarkus en Dev Mode

```bash
# Asegúrate de estar en el directorio del proyecto
cd /projects/etx_app_base_app  # o el nombre de tu proyecto

# Compilar y ejecutar Quarkus en modo desarrollo
./mvnw compile quarkus:dev
```

**✅ Lo que DEBE suceder:**

1. **Maven descarga dependencias** (primera vez toma ~2-3 minutos)
2. **Quarkus detecta que necesita PostgreSQL**
3. **Testcontainers se inicia automáticamente**
4. **Podman descarga imagen de PostgreSQL**
5. **Contenedor PostgreSQL arranca**
6. **Aplicación Quarkus inicia en puerto 8080**

**📝 Salida esperada en la consola:**
```
__  ____  __  _____   ___  __ ____  ______ 
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/ 
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \   
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/   

INFO  [io.qua.dat.dep.dev.DevServicesDatasourceProcessor] Dev Services for default datasource (postgresql) started
INFO  [io.quarkus] Installed features: [agroal, cdi, hibernate-orm, jdbc-postgresql, narayana-jta, resteasy-reactive, smallrye-context-propagation, vertx]
INFO  [io.quarkus] Quarkus 3.x.x started in 3.456s. Listening on: http://0.0.0.0:8080
```

### 4.4 Acceder a la Aplicación

**En el workspace IDE:**
- Busca la notificación que dice "A new process is listening on port 8080"
- Click en **"Open in New Tab"**

**O manualmente:**
- Ve a la sección **"Endpoints"** en el workspace
- Click en el endpoint `quarkus-dev` (puerto 8080)

**URL de la aplicación:**
```
https://quarkus-dev-<workspace-id>.<cluster-domain>
```

### 4.5 Verificar que Dev Services Funciona

**Verificar logs de Quarkus:**
Deberías ver:
```
Dev Services for default datasource (postgresql) started
```

**Verificar contenedores Podman:**
En otra terminal del workspace:
```bash
podman ps
```

**✅ Esperado:** Ver un contenedor de PostgreSQL running:
```
CONTAINER ID  IMAGE                              COMMAND     CREATED        STATUS        PORTS       NAMES
abc123def456  docker.io/library/postgres:16      postgres    2 minutes ago  Up 2 minutes              testcontainers-postgresql-...
```

---

## 🔍 Troubleshooting

### ❌ Error: "Docker not found"

**Causa:** Variables de entorno de Testcontainers no configuradas

**Solución:**
```bash
# En la terminal del workspace, configura manualmente:
export DOCKER_HOST=unix:///run/user/10001/podman/podman.sock
export TESTCONTAINERS_RYUK_DISABLED=true
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/run/user/10001/podman/podman.sock

# Luego ejecuta Quarkus de nuevo
./mvnw compile quarkus:dev
```

### ❌ Error: "Could not find a valid Docker environment"

**Causa:** Socket de Podman no está corriendo o UID incorrecto

**Solución:**
```bash
# Verificar UID del usuario
id -u
# Si no es 10001, ajusta las variables:
export DOCKER_HOST=unix:///run/user/$(id -u)/podman/podman.sock
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/run/user/$(id -u)/podman/podman.sock

# Reiniciar Podman socket si es necesario
podman system service --time=0 unix:///run/user/$(id -u)/podman/podman.sock &
```

### ❌ Error: "Ryuk container failed to start"

**Causa:** TESTCONTAINERS_RYUK_DISABLED no está configurado

**Solución:**
```bash
export TESTCONTAINERS_RYUK_DISABLED=true
./mvnw compile quarkus:dev
```

### ❌ Workspace no inicia

**Causa:** Recursos insuficientes o error en devfile

**Solución:**
1. Ve al Dashboard de DevSpaces
2. Elimina el workspace
3. Verifica el devfile en el repositorio
4. Crea el workspace de nuevo

### ❌ PostgreSQL no arranca

**Causa:** Podman no puede descargar imagen o no tiene permisos

**Solución:**
```bash
# Verificar que Podman puede descargar imágenes
podman pull docker.io/library/postgres:16

# Si falla, verificar conectividad
curl -I https://registry.hub.docker.com

# Verificar capabilities del workspace
oc get workspace -n <your-namespace> -o yaml | grep -A 5 capabilities
```

---

## ✅ Checklist de Validación

Antes de considerar la prueba exitosa, verifica:

- [ ] DevSpaces workspace creado y abierto
- [ ] Terminal funciona en el workspace
- [ ] Variables DOCKER_HOST, TESTCONTAINERS_RYUK_DISABLED configuradas
- [ ] Comando `podman version` funciona
- [ ] Comando `podman ps` muestra contenedores
- [ ] `./mvnw compile quarkus:dev` inicia sin errores
- [ ] Log muestra "Dev Services for default datasource (postgresql) started"
- [ ] `podman ps` muestra contenedor PostgreSQL running
- [ ] Aplicación accesible en endpoint https (puerto 8080)
- [ ] Endpoint `/q/health` responde con status 200

---

## 📊 Comandos Útiles de Verificación

```bash
# Verificar todo el ambiente de una vez
echo "=== Environment Variables ==="
env | grep -E "DOCKER_HOST|TESTCONTAINERS|QUARKUS"

echo -e "\n=== Podman Version ==="
podman version

echo -e "\n=== Running Containers ==="
podman ps

echo -e "\n=== Podman Socket ==="
podman info --format '{{.Host.RemoteSocket.Path}}'

echo -e "\n=== Maven Wrapper ==="
ls -la mvnw

echo -e "\n=== Workspace Endpoints ==="
# Mira en el panel de Endpoints del IDE
```

---

## 🎯 Objetivo de la Prueba

Esta prueba valida que:

1. ✅ **Testcontainers funciona con Podman** (no requiere Docker)
2. ✅ **Nested containers funcionan en DevSpaces**
3. ✅ **Quarkus Dev Services arranca PostgreSQL automáticamente**
4. ✅ **Las variables de entorno del devfile se aplican correctamente**
5. ✅ **La configuración corregida en el PR funciona en un ambiente real**

---

## 📝 Reportar Resultados

Una vez completada la prueba, documenta:

1. ✅/❌ El workspace se creó exitosamente
2. ✅/❌ Las variables de entorno están configuradas
3. ✅/❌ Podman funciona dentro del workspace
4. ✅/❌ Quarkus Dev Services arrancó PostgreSQL
5. ✅/❌ La aplicación es accesible en el endpoint

Si encuentras algún error, anótalo con:
- Mensaje de error exacto
- Comando que lo causó
- Logs relevantes
