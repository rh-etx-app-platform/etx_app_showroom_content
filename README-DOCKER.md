# Showroom Local Development with Official Red Hat UBI

## Security Policy: Official Red Hat Images Only

**MANDATORY**: Always use official Red Hat Universal Base Images (UBI) from trusted registries.

### Approved Red Hat Registries

- `registry.access.redhat.com/*` - Red Hat Container Catalog (public, unauthenticated)
- `registry.redhat.io/*` - Red Hat Container Registry (authenticated, requires Red Hat account)
- `quay.io/redhat/*` - Red Hat Quay (official Red Hat namespace)

### ❌ Never Use

- Third-party registries (Docker Hub, ghcr.io, etc.) for base images
- Unverified community images
- Images without provenance tracking

---

## Local Development Options

### Option 1: Official Node.js + npm (Recommended for CI/CD parity)

Matches the official Red Hat GitHub Actions workflow:

```bash
# Install Node.js 20
# Install Antora globally
npm install -g @antora/cli@3.1 @antora/site-generator@3.1 @sntke/antora-mermaid-extension

# Generate site
cd /path/to/etx_app_showroom_content
antora --fetch site.yml

# Serve locally
cd www
npx http-server -p 8080
```

Open http://localhost:8080

---

### Option 2: Official Red Hat UBI Container (Isolated development)

Build the official UBI-based container:

```bash
cd C:/Users/sergi/git/etx_app_showroom_content

# Build with Podman (Red Hat recommended)
podman build -t localhost/etx-showroom-viewer:latest .

# Run the container
podman run --rm \
  --name antora-viewer \
  -v $PWD:/antora:z \
  -p 8080:8080 \
  localhost/etx-showroom-viewer:latest
```

**On SELinux systems**: The `:z` flag is required for volume mounts.

**On Windows Git Bash**: Use absolute paths:
```bash
podman run --rm \
  --name antora-viewer \
  -v /c/Users/sergi/git/etx_app_showroom_content:/antora:z \
  -p 8080:8080 \
  localhost/etx-showroom-viewer:latest
```

Open http://localhost:8080

---

### Option 3: One-liner with Official UBI (No Dockerfile)

```bash
podman run --rm -it \
  -v $PWD:/antora:z \
  -w /antora \
  -p 8080:8080 \
  registry.access.redhat.com/ubi9/nodejs-20:latest \
  bash -c "npm install -g @antora/cli@3.1 @antora/site-generator@3.1 @sntke/antora-mermaid-extension && antora --fetch site.yml && cd www && npx http-server -p 8080 -c-1"
```

---

## Container Image Verification

Always verify the image source before running:

```bash
# Inspect image labels
podman inspect registry.access.redhat.com/ubi9/nodejs-20:latest | jq '.[0].Config.Labels'

# Check image signature (requires podman 4.0+)
podman image trust show

# Verify Red Hat signature
skopeo inspect docker://registry.access.redhat.com/ubi9/nodejs-20:latest
```

---

## Why Official Red Hat UBI?

### Security Benefits

✅ **Verified provenance** - Signed by Red Hat  
✅ **CVE scanning** - Automated security updates  
✅ **FIPS compliance** - For regulated environments  
✅ **Enterprise support** - Backed by Red Hat SLA  
✅ **Supply chain security** - Traceable build process  

### Compliance Benefits

✅ **Red Hat Container Certification** - Meets enterprise security standards  
✅ **No license restrictions** - Free to use and redistribute  
✅ **Regular updates** - Security patches and OS updates  
✅ **Audit trail** - Full transparency on image contents  

---

## Continuous Integration

For CI/CD pipelines, use the Node.js approach (Option 1) to match the official GitHub Actions workflow in `.github/workflows/gh-pages.yml`.

---

## Troubleshooting

### Issue: Permission denied on volume mount

**Solution**: Add `:z` flag to volume mount for SELinux contexts:
```bash
-v $PWD:/antora:z
```

### Issue: Port 8080 already in use

**Solution**: Use a different port:
```bash
-p 8081:8080
```

Then access http://localhost:8081

### Issue: Antora fails to fetch dependencies

**Solution**: Ensure you have internet access and run with `--fetch` flag:
```bash
antora --fetch site.yml
```

---

## Image Maintenance

Rebuild the container when:
- Antora version updates
- Security vulnerabilities are discovered
- Base UBI image is updated

```bash
# Pull latest UBI base
podman pull registry.access.redhat.com/ubi9/nodejs-20:latest

# Rebuild
podman build --no-cache -t localhost/etx-showroom-viewer:latest .
```

---

**Last Updated**: 2026-04-12  
**Base Image**: registry.access.redhat.com/ubi9/nodejs-20:latest  
**Antora Version**: 3.1
