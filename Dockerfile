# Official Red Hat UBI 9 Node.js 20 base image
FROM registry.access.redhat.com/ubi9/nodejs-20:latest

# Metadata
LABEL name="ETX Lab Showroom Antora Viewer" \
      version="1.0" \
      description="Official Red Hat UBI-based Antora documentation viewer for ETX Lab workshop content" \
      maintainer="ETX Platform Team"

# Switch to root to install global npm packages
USER root

# Install Antora CLI and extensions
RUN npm install -g \
    @antora/cli@3.1 \
    @antora/site-generator@3.1 \
    @sntke/antora-mermaid-extension@0.0.9 \
    http-server

# Set working directory
WORKDIR /antora

# Expose HTTP port for preview
EXPOSE 8080

# Switch back to non-root user for security
USER 1001

# Generate Antora site and serve it
CMD ["sh", "-c", "antora --fetch site.yml && cd www && npx http-server -p 8080 -c-1"]
