# Análisis de Diferencias: feature/lab1-improvements vs main

**Fecha:** 2026-05-04  
**Rama feature:** 4 commits adelante (mejoras Lab 1 + Branching Strategies)  
**Rama main:** 10 commits adelante (Git Fundamentals + mejoras generales)

## Resumen Ejecutivo

**Recomendación:** REBASE de feature/lab1-improvements sobre main + resolución manual de conflictos

**Razón:** Main tiene mejoras estructurales significativas que deben preservarse, pero nuestras mejoras de Lab 1 son complementarias y valiosas.

---

## Análisis de Commits

### Commits SOLO en main (10 total)

| Commit | Descripción | Impacto |
|--------|-------------|---------|
| `a2669b8` | Merge PR #3 Git Fundamentals | Merge commit |
| `414bed9` | Fix PlantUML diagram | Mejora técnica |
| `987bf0d` | **Implement Application CI, CD, Promotion** | ⚠️ CRÍTICO - Agrega day2-lab1-promotion.adoc |
| `4cd9d65` | Make cluster URLs dynamic with {guid} | ⚠️ CRÍTICO - Mejora antora.yml |
| `29a7788` | Update Day 1 with real cluster | ⚠️ CONFLICTO - Modifica branching-strategies |
| `0ad560a` | Restructure Day 1 timing (45 min) | ⚠️ CONFLICTO - Modifica branching-strategies |
| `d57230c` | Add collaboration guidelines | Nuevo archivo CONTRIBUTING.md |
| `d0da3f8` | Fix leveloffset for partials | Mejora técnica |
| `22fd24b` | Restructure Git Fundamentals | Nueva estructura modular |
| `857ba76` | Add Git Fundamentals lab | Nuevo contenido Day 1 |

### Commits SOLO en feature/lab1-improvements (4 total)

| Commit | Descripción | Autor |
|--------|-------------|-------|
| `2a50e1f` | Fix attribute substitution | Sergio Canales |
| `8f0016f` | Use internal GitLab for clone | Sergio Canales |
| `6c8401c` | Improve branching strategies lab | Sergio Canales |
| `e6023bc` | **Add Lab 1 critical improvements** | Sergio Canales |

---

## Archivos con Conflictos

### 1. `content/modules/ROOT/nav.adoc`

**Conflicto:** Línea 22

**En feature/lab1-improvements:**
```adoc
* xref:day2-lab1-troubleshooting.adoc[Troubleshooting (Optional)]
```

**En main:**
```adoc
* xref:day2-lab1-promotion.adoc[Promotion Pipeline]
```

**Resolución recomendada:** MANTENER AMBOS
```adoc
* xref:day2-lab1-promotion.adoc[Promotion Pipeline]
* xref:day2-lab1-troubleshooting.adoc[Troubleshooting (Optional)]
```

**Justificación:** Promotion Pipeline es contenido del lab, Troubleshooting es guía de soporte.

---

### 2. `content/modules/ROOT/pages/day1-branching-strategies.adoc`

**Conflicto:** TODO EL ARCHIVO (532 líneas de diferencia)

**En feature/lab1-improvements (113 líneas):**
- Instrucciones básicas de clonación
- Uso de GitLab interno con atributo
- Ejercicio simple: agregar nombre a README

**En main (473 líneas):**
- Validación completa de Git setup
- Explicación detallada de modelos de branching
- Múltiples ejercicios hands-on
- Diagramas y tablas comparativas
- Uso extensivo de atributos de Antora
- `role=execute` en bloques de código

**Resolución recomendada:** USAR VERSIÓN DE MAIN + integrar mejoras específicas de feature

**Mejoras de feature a integrar:**
1. ✅ Instrucciones de acceso a GitLab con Keycloak (ya está en main)
2. ✅ Uso de `git clone {gitlab_url}/...` (ya está en main)
3. ⚠️ Verificar que use `platform/etx_app_base_app` (feature) vs `software-factory/parasol-insurance-lab` (main)

**Justificación:** La versión de main es significativamente más completa y educativa. Solo necesitamos verificar el path del repositorio.

---

### 3. `content/modules/ROOT/pages/day2-lab1-ci-pipeline.adoc`

**Conflicto:** Líneas 9-18

**En feature/lab1-improvements:**
```adoc
[NOTE]
====
**Git Authentication:** If using a private Git repository or GitHub, ensure you have:

* GitLab: Use the workshop credentials provided
* GitHub: Create a Personal Access Token with `repo` scope

For public repositories, authentication may not be required for clone operations.
====
```

**En main:**
- Nota eliminada
- Agregado `role=execute` a bloques bash

**Resolución recomendada:** ELIMINAR la nota (seguir versión de main)

**Justificación:** Main eliminó esta nota probablemente porque:
1. Las credenciales ya están explicadas en Environment Overview
2. El workshop usa GitLab interno, no GitHub
3. Reduce redundancia

**Mantener de feature:**
- ✅ Quick Verification section (líneas finales)
- ✅ TIP con Common Issues

---

### 4. `content/modules/ROOT/pages/day2-lab1-app-deployment.adoc`

**Conflicto:** Atributo `role=execute` agregado en main

**En feature/lab1-improvements:**
```adoc
[source,bash]
----
oc get csv -n openshift-operators | grep gitops
----
```

**En main:**
```adoc
[source,bash,role=execute]
----
oc get csv -n openshift-operators | grep gitops
----
```

**Resolución recomendada:** ADOPTAR cambios de main + mantener nuestras secciones nuevas

**Cambios de main a adoptar:**
- ✅ `role=execute` en todos los bloques bash
- ✅ Mejoras de formato

**Mantener de feature:**
- ✅ Quick Verification section
- ✅ TIP con Common Issues

---

## Archivos Nuevos

### Solo en main

| Archivo | Descripción | Acción |
|---------|-------------|--------|
| `.containerignore` | Docker build | ✅ MANTENER |
| `CONTRIBUTING.md` | Guidelines para contributors | ✅ MANTENER |
| `Dockerfile` | Containerización del showroom | ✅ MANTENER |
| `README-DOCKER.md` | Documentación Docker | ✅ MANTENER |
| `WORKSHOP-STRUCTURE-PROPOSAL.md` | Propuesta de estructura | ✅ MANTENER |
| `day2-lab1-promotion.adoc` | **Promotion Pipeline lab** | ⚠️ CRÍTICO - MANTENER |

### Solo en feature

| Archivo | Descripción | Acción |
|---------|-------------|--------|
| `IMPROVEMENTS.md` | Documentación de mejoras Lab 1 | ✅ MANTENER (útil como referencia) |
| `day2-lab1-troubleshooting.adoc` | Guía de troubleshooting | ⚠️ CRÍTICO - MANTENER |

---

## Cambios en antora.yml

### En feature/lab1-improvements
```yaml
guid: abc123
bastion_public_hostname: bastion.abc123.ocpv00.rhdp.net
openshift_console_url: https://console-openshift-console.apps.cluster-abc123.ocpv00.rhdp.net
openshift_cluster_ingress_domain: apps.cluster-abc123.ocpv00.rhdp.net
ocp_version: "4.18"
user: kubeadmin
password: changeme
```

### En main
```yaml
guid: wgphm
bastion_public_hostname: bastion.{guid}.dynamic.redhatworkshops.io
openshift_console_url: https://console-openshift-console.apps.cluster-{guid}.dynamic.redhatworkshops.io
openshift_cluster_ingress_domain: apps.cluster-{guid}.dynamic.redhatworkshops.io
ocp_version: "4.20"
user: platform-admin
password: openshift
gitlab_url: http://gitlab.apps.cluster-{guid}.dynamic.redhatworkshops.io
keycloak_url: https://etx-sso.apps.cluster-{guid}.dynamic.redhatworkshops.io
quay_url: https://quay.apps.cluster-{guid}.dynamic.redhatworkshops.io
vault_url: https://vault.apps.cluster-{guid}.dynamic.redhatworkshops.io
etx_gitops_url: https://etx-gitops-server-etx-gitops.apps.cluster-{guid}.dynamic.redhatworkshops.io
```

**Resolución recomendada:** USAR versión de main COMPLETAMENTE

**Justificación:**
- Uso consistente de {guid} como variable
- Atributos nuevos necesarios (gitlab_url, keycloak_url, etc.)
- Credenciales correctas del workshop (platform-admin/openshift)
- OCP version actualizada a 4.20

---

## Estrategia de Integración Recomendada

### Opción 1: REBASE (Recomendada) ✅

```bash
# 1. Crear backup de la rama feature
git branch feature/lab1-improvements-backup

# 2. Rebase sobre main
git checkout feature/lab1-improvements
git rebase origin/main

# 3. Resolver conflictos manualmente:
#    - nav.adoc: Agregar troubleshooting DESPUÉS de promotion
#    - day1-branching-strategies.adoc: Usar versión de main
#    - day2-lab1-ci-pipeline.adoc: Eliminar nota de Git Auth, mantener Quick Verification
#    - day2-lab1-app-deployment.adoc: Agregar role=execute, mantener Quick Verification

# 4. Continuar rebase
git rebase --continue

# 5. Force push
git push origin feature/lab1-improvements --force
```

**Ventajas:**
- ✅ Historia lineal y limpia
- ✅ Nuestros commits quedan "encima" de main
- ✅ Fácil de revisar en el PR

**Desventajas:**
- ⚠️ Requiere force push (ya lo hicimos antes)
- ⚠️ Necesita resolución manual de conflictos

---

### Opción 2: MERGE (No recomendada) ❌

```bash
git checkout feature/lab1-improvements
git merge origin/main
# Resolver conflictos
git commit
git push origin feature/lab1-improvements
```

**Ventajas:**
- ✅ Preserva toda la historia
- ✅ No requiere force push

**Desventajas:**
- ❌ Crea merge commit adicional
- ❌ Historia menos lineal
- ❌ PR más difícil de revisar

---

## Cambios que Debemos Preservar de feature/lab1-improvements

### 1. Archivos a mantener ÍNTEGROS
- ✅ `IMPROVEMENTS.md` - Documentación de nuestras mejoras
- ✅ `content/modules/ROOT/pages/day2-lab1-troubleshooting.adoc` - Nueva guía

### 2. Secciones a integrar en archivos existentes

**En `day2-lab1-ci-pipeline.adoc`:**
- ✅ Quick Verification section (líneas 373-400)
- ✅ TIP con Common Issues (líneas 392-400)

**En `day2-lab1-app-deployment.adoc`:**
- ✅ Quick Verification section (líneas 682-698)
- ✅ TIP con Common Issues (líneas 703-710)

**En `content/modules/ROOT/nav.adoc`:**
- ✅ Link a troubleshooting (agregar DESPUÉS de promotion)

### 3. Cambios conceptuales a preservar
- ✅ AMQ Streams installation (ya está en supporting-services)
- ✅ Quick verification commands en CI/CD labs
- ✅ Troubleshooting como recurso opcional

---

## Cambios que Debemos Adoptar de main

### 1. Archivos completos
- ✅ `content/modules/ROOT/pages/day1-branching-strategies.adoc` - Versión mucho más completa
- ✅ `content/modules/ROOT/pages/day2-lab1-promotion.adoc` - Nuevo lab necesario
- ✅ `content/antora.yml` - Atributos mejorados
- ✅ `CONTRIBUTING.md`, `Dockerfile`, etc. - Infraestructura del proyecto

### 2. Mejoras técnicas
- ✅ `role=execute` en bloques bash para botón copy
- ✅ Uso consistente de atributos de Antora ({gitlab_url}, {user}, etc.)
- ✅ URLs dinámicas con {guid}

---

## Plan de Ejecución

### Paso 1: Backup
```bash
git branch feature/lab1-improvements-backup
```

### Paso 2: Rebase
```bash
git checkout feature/lab1-improvements
git rebase origin/main
```

### Paso 3: Resolver Conflictos

**Archivo 1: nav.adoc**
```adoc
* xref:day2-lab1-promotion.adoc[Promotion Pipeline]
* xref:day2-lab1-troubleshooting.adoc[Troubleshooting (Optional)]
```

**Archivo 2: day1-branching-strategies.adoc**
- Aceptar versión de main COMPLETA
- NO necesita cambios (ya usa {gitlab_url})

**Archivo 3: day2-lab1-ci-pipeline.adoc**
- Aceptar cambios de main (role=execute)
- Eliminar NOTE de Git Authentication
- MANTENER Quick Verification section del final
- MANTENER TIP con Common Issues

**Archivo 4: day2-lab1-app-deployment.adoc**
- Aceptar cambios de main (role=execute)
- MANTENER Quick Verification section
- MANTENER TIP con Common Issues

### Paso 4: Continuar Rebase
```bash
git add .
git rebase --continue
```

### Paso 5: Verificar
```bash
git log --oneline origin/main..HEAD
# Debe mostrar nuestros 4 commits encima de main
```

### Paso 6: Push
```bash
git push origin feature/lab1-improvements --force
```

---

## Verificación Post-Merge

### Checklist de contenido

- [ ] `day2-lab1-promotion.adoc` existe (de main)
- [ ] `day2-lab1-troubleshooting.adoc` existe (de feature)
- [ ] `nav.adoc` tiene ambos links (promotion + troubleshooting)
- [ ] `day1-branching-strategies.adoc` es la versión completa de main
- [ ] `day2-lab1-ci-pipeline.adoc` tiene Quick Verification
- [ ] `day2-lab1-app-deployment.adoc` tiene Quick Verification
- [ ] `content/antora.yml` tiene todos los atributos de main
- [ ] Bloques bash tienen `role=execute`
- [ ] URLs usan atributos dinámicos

### Checklist de autoría

- [ ] Todos los commits de feature mantienen autoría: Sergio Canales
- [ ] No hay commits con autor "admin"

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| Pérdida de cambios en conflicto | Media | Crear backup branch antes de rebase |
| PR difícil de revisar | Baja | Historia lineal facilita revisión |
| Conflictos complejos en rebase | Alta | Documentación detallada en este análisis |
| Regression de funcionalidad | Baja | Verificación con showroom local |

---

## Conclusión

**Acción recomendada:** REBASE de feature/lab1-improvements sobre origin/main

**Resultado esperado:**
- Historia lineal con nuestros 4 commits encima de main
- Todas las mejoras de main integradas
- Nuestras contribuciones (troubleshooting, quick verification) preservadas
- PR #4 actualizado y listo para merge a main

**Tiempo estimado:** 15-20 minutos

**Próximos pasos:**
1. Ejecutar el rebase
2. Resolver conflictos según este análisis
3. Verificar en showroom local
4. Force push
5. Actualizar descripción de PR si es necesario
