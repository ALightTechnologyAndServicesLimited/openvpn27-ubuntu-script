#!/usr/bin/env bash
set -euo pipefail

OPENSSL_VERSION="${OPENSSL_VERSION:-3.6.1}"
OPENVPN_VERSION="${OPENVPN_VERSION:-2.7.0}"
PREFIX_SSL="${PREFIX_SSL:-/usr/local/ssl}"
PREFIX_OPENVPN="${PREFIX_OPENVPN:-/usr/local/openvpn}"
BUILD_DIR="${BUILD_DIR:-/usr/local/src}"
BYPASS_SSL="${BYPASS_SSL:-false}"

log() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
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

openssl_lib_dir() {
  local lib_dir="$PREFIX_SSL/lib"
  [[ -d "$PREFIX_SSL/lib64" ]] && lib_dir="$PREFIX_SSL/lib64"
  echo "$lib_dir"
}

ensure_ca_bundle() {
  : "${SSL_CERT_FILE:=/etc/ssl/certs/ca-certificates.crt}"
  : "${SSL_CERT_DIR:=/etc/ssl/certs}"
  export SSL_CERT_FILE SSL_CERT_DIR

  if [[ ! -f "$SSL_CERT_FILE" ]]; then
    error "CA bundle not found at $SSL_CERT_FILE. Install: sudo apt-get install ca-certificates && sudo update-ca-certificates"
  fi
}

install_dependencies() {
  log "Installing build dependencies..."
  apt-get update
  apt-get install -y \
    build-essential automake autoconf libtool pkg-config \
    liblzo2-dev libpam0g-dev liblz4-dev libcap-ng-dev \
    python3 python3-docutils libsystemd-dev git cmake wget \
    ca-certificates curl zlib1g-dev libnl-genl-3-dev gnupg

  update-ca-certificates
}

download_release() {
  local name="$1"
  local version="$2"
  local repo="$3"
  local tag_prefix="$4"
  local signing_key="$5"
  local tarball="${name,,}-${version}.tar.gz"
  local url="https://github.com/${repo}/releases/download/${tag_prefix}${version}/${tarball}"

  log "Downloading ${name} ${version}..."
  cd "$BUILD_DIR"
  ensure_ca_bundle

  if [[ "$BYPASS_SSL" == "true" ]]; then
    warn "BYPASS_SSL=true - skipping certificate validation (NOT recommended)"
    wget --no-check-certificate "$url"
    wget --no-check-certificate "${url}.asc" || true
  else
    wget --https-only --ca-certificate="$SSL_CERT_FILE" "$url"
    wget --https-only --ca-certificate="$SSL_CERT_FILE" "${url}.asc" || true
  fi

  if command -v gpg >/dev/null 2>&1 && [[ -f "${tarball}.asc" ]]; then
    log "Verifying ${name} signature (best-effort)..."
    if gpg --list-keys "$signing_key" >/dev/null 2>&1; then
      gpg --verify "${tarball}.asc" "$tarball" >/dev/null 2>&1 || warn "${name} signature verification failed"
    else
      warn "${name} GPG key not found - skipping signature verification"
      warn "To verify signatures, import the ${name} signing key: gpg --keyserver keyserver.ubuntu.com --recv-keys ${signing_key}"
    fi
  else
    warn "Skipping signature verification (gpg or .asc missing)."
  fi
}

build_openssl() {
  log "Building OpenSSL ${OPENSSL_VERSION}..."
  cd "$BUILD_DIR"
  rm -rf "openssl-${OPENSSL_VERSION}" || true

  tar xzf "openssl-${OPENSSL_VERSION}.tar.gz"
  cd "openssl-${OPENSSL_VERSION}"

  ./config --prefix="$PREFIX_SSL" --openssldir="$PREFIX_SSL" shared zlib
  make -j"$(nproc)"
  make install

  local lib_dir
  lib_dir="$(openssl_lib_dir)"

  echo "$lib_dir" > /etc/ld.so.conf.d/openssl-3.5.conf
  ldconfig
}

build_openvpn() {
  log "Building OpenVPN ${OPENVPN_VERSION}..."
  cd "$BUILD_DIR"
  rm -rf "openvpn-${OPENVPN_VERSION}" || true

  tar xzf "openvpn-${OPENVPN_VERSION}.tar.gz"
  cd "openvpn-${OPENVPN_VERSION}"

  local lib_dir
  lib_dir="$(openssl_lib_dir)"

  PKG_CONFIG_PATH="$PREFIX_SSL/lib64/pkgconfig:$PREFIX_SSL/lib/pkgconfig" \
    ./configure --prefix="$PREFIX_OPENVPN" \
      OPENSSL_CRYPTO_CFLAGS="-I$PREFIX_SSL/include" \
      OPENSSL_CRYPTO_LIBS="-L$lib_dir -lcrypto" \
      OPENSSL_SSL_CFLAGS="-I$PREFIX_SSL/include" \
      OPENSSL_SSL_LIBS="-L$lib_dir -lssl" \
      --enable-systemd

  make -j"$(nproc)"
  make install
}

verify_installation() {
  log "Verifying installation..."
  "$PREFIX_OPENVPN/sbin/openvpn" --version | head -n 2 || true

  if ldd "$PREFIX_OPENVPN/sbin/openvpn" | grep -q "$PREFIX_SSL"; then
    log "OpenVPN is linked against custom OpenSSL at $PREFIX_SSL"
  else
    warn "OpenVPN may not be using the custom OpenSSL build"
  fi

  mkdir -p /usr/local/sbin
  ln -sf "$PREFIX_OPENVPN/sbin/openvpn" /usr/local/sbin/openvpn

  if command -v openvpn >/dev/null 2>&1; then
    log "openvpn resolved as: $(command -v openvpn)"
  fi
}

main() {
  check_root
  check_ubuntu
  install_dependencies

  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  download_release "OpenSSL" "$OPENSSL_VERSION" "openssl/openssl" "openssl-" "0x8657ABB260F056B1"
  build_openssl

  download_release "OpenVPN" "$OPENVPN_VERSION" "OpenVPN/openvpn" "v" "0x8B3957799518946C"
  build_openvpn

  verify_installation

  log "Done. Run: sudo openvpn --config client.conf"
}

main "$@"
