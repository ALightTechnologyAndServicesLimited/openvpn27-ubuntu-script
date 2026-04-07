# OpenVPN 2.7 + OpenSSL 3.6 (Ubuntu) Build & Install Scripts

"OpenVPN" is a trademark of OpenVPN Inc.

This repository provides two ways to build and install OpenVPN 2.7 with Post-Quantum (PQ) cryptography support (linked against OpenSSL 3.6.1):

1. **Host-based monolithic script:** `install-openvpn27-pq-client-ubuntu.sh` (Installs heavy build tools directly on the host)
2. **Docker-based isolated build:** `Dockerfile.build` + `build-and-extract.sh` + `install-host.sh` (Recommended: Builds inside a container, extracts only the necessary binaries, and installs them on the host with minimal runtime dependencies) based on Ubuntu 24.04

## Recommended: Docker-based Build & Install

To keep your host system clean from compilers and development headers, use the Docker-based approach.

### Prerequisites
- Docker installed on the host
- Ubuntu host (for the final installation)

### 1. Build the binaries
Run the build script. This will use Docker to download and compile OpenSSL and OpenVPN, then extract the compiled binaries into a `openvpn-pq-build.tar.gz` archive.

```bash
chmod +x build-and-extract.sh
./build-and-extract.sh
```

### 2. Install on the host
Once the archive is generated, run the host install script. This script installs only the minimal required libraries (like `liblzo2-2`, `libpam0g`, etc.), extracts the binaries to `/usr/local`, and configures the dynamic linker.

```bash
chmod +x install-host.sh
sudo ./install-host.sh
```

### 3. Verify
```bash
openvpn --version | head -n 2
ldd $(which openvpn) | grep /usr/local/ssl || true
```

---

## Legacy: Host-based Monolithic Script

If you prefer to compile directly on your host (which will install `build-essential` and many `-dev` packages), use the standalone script.

```bash
chmod +x install-openvpn27-pq-client-ubuntu.sh
sudo bash ./install-openvpn27-pq-client-ubuntu.sh
```

## Verify it is using the custom OpenSSL

```bash
which openvpn
ldd "$(which openvpn)" | grep /usr/local/ssl || true
/usr/local/openvpn/sbin/openvpn --version | head -n 2
```

If your shell resolves a different `openvpn`, run the compiled binary explicitly:

```bash
sudo /usr/local/openvpn/sbin/openvpn --config client.conf
```

## Configuration

Environment variables you can override (for both the monolithic script and the Dockerfile):

- `OPENSSL_VERSION` (default: `3.6.1`)
- `OPENVPN_VERSION` (default: `2.7.0`)
- `PREFIX_SSL` (default: `/usr/local/ssl`)
- `PREFIX_OPENVPN` (default: `/usr/local/openvpn`)
- `BUILD_DIR` (default: `/usr/local/src`)

## Uninstall / cleanup

If you want to remove what the scripts installed:

```bash
sudo rm -rf /usr/local/openvpn /usr/local/ssl
sudo rm -f /etc/ld.so.conf.d/openssl-3.6.conf
sudo rm -f /usr/local/sbin/openvpn
sudo ldconfig
```

## Files included

- `Dockerfile.build` — Multi-stage Dockerfile to compile the software
- `build-and-extract.sh` — Wrapper script to run the Docker build and extract the artifact
- `install-host.sh` — Lightweight script to install the pre-compiled artifact on an Ubuntu host
- `install-openvpn27-pq-client-ubuntu.sh` — Legacy monolithic build & install script

### Personal Links:
[Facebook - Kanti Arumilli](https://www.facebook.com/kanti.arumilli)

[LinkedIn - Kanti Kalyan Arumilli](https://www.linkedin.com/in/kanti-kalyan-arumilli/)

[Thread](https://www.threads.net/@kantiarumilli)

[Youtube](https://www.youtube.com/@kantikalyanarumilli)

[Facebook](https://www.facebook.com/kanti.arumilli)

[Instagram](https://www.instagram.com/kantiarumilli/)

+91-789-362-6688, +1-480-347-6849, +44-07718-273-964

### Startup Links:
[Facebook](https://www.facebook.com/ALightTechnologyAndServicesLimited/)

[LinkedIn](https://www.linkedin.com/company/alight-technology-and-services-limited/)

[Youtube](https://www.youtube.com/@alighttechnologyandservicesltd)

[Website](https://www.alightservices.com/)

[WebVeta](https://webveta.alightservices.com/)

[VPN](https://vpn.alightservices.com/)

### Disclaimer:
NOT associated to the cyber mafia using invisible drones capable of invisible cameras, invisible speakers, mind reading capabilities equipment that are Indians but harassing Indian citizens, India's paid goons begging for ransom extortion or those Indian paid goons acts like virtual family, virtual friends for distorting identity and framing victims on a different identity. I am Indian citizen but against crime. Those cyber mafia are vey notorious criminals probably even murderers, because they did attempt murder on few occassions against me.

