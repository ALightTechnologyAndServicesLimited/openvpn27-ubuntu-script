#!/usr/bin/env bash
set -euo pipefail

log() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

BUILD_IMAGE="openvpn-pq-builder"
OUTPUT_TAR="openvpn-pq-build.tar.gz"

log "Building OpenVPN and OpenSSL via Docker..."
docker build -t "$BUILD_IMAGE" -f Dockerfile.build .

log "Extracting compiled binaries from the image..."
# Use an intermediate container to copy the file
TEMP_CONTAINER=$(docker create "$BUILD_IMAGE")
docker cp "$TEMP_CONTAINER:/openvpn-pq-build.tar.gz" "./$OUTPUT_TAR"
docker rm "$TEMP_CONTAINER"

if [[ -f "./$OUTPUT_TAR" ]]; then
    log "Successfully generated $OUTPUT_TAR"
    log "You can now run: sudo ./install-host.sh"
else
    error "Failed to extract $OUTPUT_TAR"
fi
