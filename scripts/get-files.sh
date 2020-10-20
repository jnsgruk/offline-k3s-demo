#!/bin/bash 

#
# This script will fetch all the required files to bootstrap
# a k3s cluster offline on CentOS. It will also fetch some
# common Kubernetes CLI tools (kubectl, helm)
#

set -euo pipefail
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Check if a download destination was specified as an argument
if [[ -z "${1}" ]]; then
  DOWNLOAD_DIR="${SCRIPT_DIR}/files"
else
  DOWNLOAD_DIR="${1}"
fi

# Select a CentOS mirror
BASEOS_REPO="http://mirror.centos.org/centos/8/BaseOS/x86_64/os/Packages"
APPSTREAM_REPO="http://mirror.centos.org/centos/8/AppStream/x86_64/os/Packages"

# List of URLs that point to RPMs we need
RPM_URLS=(
  "${BASEOS_REPO}/audit-3.0-0.17.20191104git1c2f876.el8.x86_64.rpm"
  "${BASEOS_REPO}/audit-libs-3.0-0.17.20191104git1c2f876.el8.x86_64.rpm"
  "${BASEOS_REPO}/checkpolicy-2.9-1.el8.x86_64.rpm"
  "${BASEOS_REPO}/libselinux-2.9-3.el8.x86_64.rpm"
  "${BASEOS_REPO}/libselinux-utils-2.9-3.el8.x86_64.rpm"
  "${BASEOS_REPO}/libsemanage-2.9-2.el8.x86_64.rpm"
  "${BASEOS_REPO}/libsepol-2.9-1.el8.x86_64.rpm"
  "${BASEOS_REPO}/policycoreutils-2.9-9.el8.x86_64.rpm"
  "${BASEOS_REPO}/policycoreutils-python-utils-2.9-9.el8.noarch.rpm"
  "${BASEOS_REPO}/python3-audit-3.0-0.17.20191104git1c2f876.el8.x86_64.rpm"
  "${BASEOS_REPO}/python3-libselinux-2.9-3.el8.x86_64.rpm"
  "${BASEOS_REPO}/python3-libsemanage-2.9-2.el8.x86_64.rpm"
  "${BASEOS_REPO}/python3-policycoreutils-2.9-9.el8.noarch.rpm"
  "${BASEOS_REPO}/python3-setools-4.2.2-2.el8.x86_64.rpm"
  "${BASEOS_REPO}/selinux-policy-3.14.3-41.el8_2.6.noarch.rpm"
  "${BASEOS_REPO}/selinux-policy-targeted-3.14.3-41.el8_2.6.noarch.rpm"
  "${APPSTREAM_REPO}/container-selinux-2.124.0-1.module_el8.2.0+305+5e198a41.noarch.rpm"
  "https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm"
)

echo "[+] Downloading RPM dependencies..."
mkdir -p "${DOWNLOAD_DIR}/rpms"
wget -qP "${DOWNLOAD_DIR}/rpms" "${RPM_URLS[@]}"

echo "[+] Downloading kubectl..."
wget -qO "${DOWNLOAD_DIR}/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v1.18.10/bin/linux/amd64/kubectl"

echo "[+] Downloading helm..."
wget -qO- "https://get.helm.sh/helm-v3.3.4-linux-amd64.tar.gz" | tar zx --strip-components 1 -C "${DOWNLOAD_DIR}" linux-amd64/helm 

echo "[+] Downloading k3s..."
wget -qO "${DOWNLOAD_DIR}/k3s" "https://github.com/rancher/k3s/releases/download/v1.18.10%2Bk3s1/k3s"

echo "[+] Downloading k3s offline images..."
wget -qO "${DOWNLOAD_DIR}/k3s-airgap-images-amd64.tar" "https://github.com/rancher/k3s/releases/download/v1.18.10%2Bk3s1/k3s-airgap-images-amd64.tar"

echo "[+] Downloading k3s installer..."
wget -qO "${DOWNLOAD_DIR}/install-k3s.sh" "https://get.k3s.io"