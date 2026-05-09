## Summary

Fixes Day 2 Lab by switching from Quarkus Dev Services (Testcontainers/Podman) to external cluster services (PostgreSQL and Kafka).

## Problem

- Kafka Dev Services incompatible with Podman rootless in DevSpaces
- Frequent "Docker not found" errors with Testcontainers
- Students spending time debugging infrastructure instead of learning products

## Solution

**Reorder lab workflow:**
1. Deploy PostgreSQL and Kafka to cluster first (Lab Step 2)
2. Create DevSpaces workspace second (Lab Step 3)
3. Application connects to external services via environment variables

**Changes:**
- Add PostgreSQL deployment (Red Hat certified image) to Supporting Services lab
- Add Kafka cluster deployment (AMQ Streams) to Supporting Services lab
- Update devfile examples to use environment variables instead of Podman configuration
- Remove all Testcontainers/Podman socket configuration
- Update application.properties examples to disable Dev Services

## Files Changed

```
content/modules/ROOT/pages/
├── day2-lab1-environment.adoc         (reordered workflow)
├── day2-lab1-supporting-services.adoc (added PostgreSQL + Kafka deployment)
├── day2-lab1-devspaces.adoc           (removed Dev Services config)
├── day2-devspaces-devfiles.adoc       (updated example)
└── day2-lab2-mta.adoc                 (updated config example)

validation/
├── end-to-end-test.sh                 (automated deployment)
├── devspaces-validation.sh            (workspace validation)
├── devfile-validation.yaml            (reference devfile)
└── application.properties             (reference config)
```

## Result

Students deploy external services, create workspace, run application without Testcontainers errors. Focus shifts from debugging to learning Red Hat products and integrations.

## Related

This PR coordinates with etx_app_base_app PR #6. Both must be merged together.
