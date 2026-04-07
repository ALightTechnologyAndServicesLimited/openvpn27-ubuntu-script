#!/usr/bin/env bash
set -euo pipefail

log() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

check_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    error "This script must be run as root. Use: sudo bash $0"
  fi
}

check_ubuntu() {
  if ! grep -q "Ubuntu" /etc/os-release; then
    error "This script is designed for Ubuntu only. Detected: $(grep PRETTY_NAME /etc/os-release | cut -d'\"' -f2)"
  fi
}

install_runtime_dependencies() {
  log "Installing runtime dependencies..."
  apt-get update
  apt-get install -y \
    liblzo2-2 libpam0g liblz4-1 libcap-ng0 \
    libsystemd0 libnl-genl-3-200 zlib1g iproute2
}

install_binaries() {
  local tarball="openvpn-pq-build.tar.gz"
  if [[ ! -f "$tarball" ]]; then
    error "Archive $tarball not found! Please run build-and-extract.sh first."
  fi

  log "Extracting binaries from $tarball..."
  tar -xzf "$tarball" -C /

  log "Configuring dynamic linker for custom OpenSSL..."
  echo "/usr/local/ssl/lib64" > /etc/ld.so.conf.d/openssl-3.6.conf
  echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/openssl-3.6.conf
  ldconfig

  log "Setting up symlinks..."
  mkdir -p /usr/local/sbin
  ln -sf /usr/local/openvpn/sbin/openvpn /usr/local/sbin/openvpn
}

verify_installation() {
  log "Verifying installation..."
  if ! command -v openvpn >/dev/null 2>&1; then
    error "openvpn command not found!"
  fi

  /usr/local/sbin/openvpn --version | head -n 2 || true

  if ldd /usr/local/openvpn/sbin/openvpn | grep -q "/usr/local/ssl"; then
    log "OpenVPN is correctly linked against custom OpenSSL at /usr/local/ssl"
  else
    log "[WARN] OpenVPN may not be using the custom OpenSSL build"
  fi
}

main() {
  check_root
  check_ubuntu
  install_runtime_dependencies
  install_binaries
  verify_installation
  log "Installation complete. Run: sudo openvpn --config client.conf"
}

main "$@"
