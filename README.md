# OpenVPN 2.7 + OpenSSL 3.6 (Ubuntu) Build Script

"OpenVPN" is a trademark of OpenVPN Inc.


This repository contains a single script that installs build dependencies and compiles:

- OpenSSL **3.6.1** into `/usr/local/ssl`
- OpenVPN **2.7.0** into `/usr/local/openvpn`

It also creates a convenience symlink:

- `/usr/local/sbin/openvpn` -> `/usr/local/openvpn/sbin/openvpn`

So you can run:

```bash
sudo openvpn --config client.conf
```

## Why compile OpenVPN?

If you need OpenVPN to use a specific OpenSSL version (for example for newer TLS groups / hybrid/PQ experimentation), compiling OpenVPN and linking it to a custom OpenSSL build makes the runtime behavior explicit and reproducible.

## What this script does

- Installs Ubuntu build prerequisites via `apt-get`
- Downloads official release tarballs from GitHub:
  - `openssl/openssl` (tag `openssl-<version>`)
  - `OpenVPN/openvpn` (tag `v<version>`)
- Builds OpenSSL as a shared library
- Builds OpenVPN and links it against the custom OpenSSL
- Runs `ldconfig`
- Symlinks `openvpn` into `/usr/local/sbin` for convenience

## Supported OS

- Ubuntu (tested with Docker images like `ubuntu:24.04`)

The script exits if it doesn’t detect Ubuntu.

## Quick start (on an Ubuntu machine)

From the folder containing the script:

```bash
chmod +x install-openvpn27-pq-client-ubuntu.sh
sudo bash ./install-openvpn27-pq-client-ubuntu.sh

openvpn --version | head -n 2
sudo openvpn --config client.conf
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

## Running inside Docker (for build verification)

You can validate compilation in an interactive Ubuntu container:

```bash
docker run -it --rm -v "$(pwd):/repo" -w /repo ubuntu:24.04 bash
bash ./install-openvpn27-pq-client-ubuntu.sh
openvpn --version | head -n 2
```

Note: building works fine in Docker; actually *connecting* from inside a container requires a working TUN device and additional container privileges.

## Configuration

Environment variables you can override:

- `OPENSSL_VERSION` (default: `3.6.1`)
- `OPENVPN_VERSION` (default: `2.7.0`)
- `PREFIX_SSL` (default: `/usr/local/ssl`)
- `PREFIX_OPENVPN` (default: `/usr/local/openvpn`)
- `BUILD_DIR` (default: `/usr/local/src`)
- `BYPASS_SSL` (default: `false`)

Example:

```bash
sudo OPENVPN_VERSION=2.7.1 bash ./install-openvpn27-pq-client-ubuntu.sh
```

## Security notes

- The build runs as root because it installs packages and writes to `/usr/local`.
- `BYPASS_SSL=true` disables TLS certificate validation for downloads. Keep it `false` unless you have a very specific reason.
- Signature verification is **best-effort**:
  - If you import the maintainer key into `gpg`, the script can verify `.asc` signatures.
  - If the key is not present, the script will warn and proceed.

## Uninstall / cleanup

If you want to remove what the script installed:

```bash
sudo rm -rf /usr/local/openvpn /usr/local/ssl
sudo rm -f /etc/ld.so.conf.d/openssl-3.5.conf
sudo rm -f /usr/local/sbin/openvpn
sudo ldconfig
```

## Files

- `install-openvpn27-pq-client-ubuntu.sh` — main installer/build script

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

