#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TOP_DIR=$( cd "$( dirname "${SCRIPT_DIR}" )" && pwd )
CURRENT_DIR="${PWD}"

if ! command -v terraform >/dev/null; then
  echo >&2 "[!] Terraform not in \$PATH, exiting."
elif ! command -v ansible-playbook >/dev/null; then
  echo >&2 "[!] Ansible not in \$PATH, exiting."
elif ! command -v az >/dev/null; then
  echo >&2 "[!] Azure CLI not in \$PATH, exiting."
fi

if ! az account show 2>&1 >/dev/null; then
  echo "[!] Not logged into the Azure CLI, attempting login now..."
  az login
fi

if [[ ! -f "${HOME}/.ssh/id_rsa" ]]; then
  echo "[+] No SSH key found at '~/.ssh/id_rsa'. Generating..."
  ssh-keygen -f "${HOME}"/.ssh/id_rsa -t rsa -b 4096 -N ''
fi

if [[ ! -d "${TOP_DIR}/files" ]]; then
  echo "[+] Offline cache not found. Downloading files..."
  "${SCRIPT_DIR}"/get-files.sh "${TOP_DIR}/files"
fi

echo "[+] Deploying test environment to Azure..."
cd "${TOP_DIR}"/terraform || exit
terraform init
terraform apply --auto-approve

echo "[+] Generating SSH config file for test environment..."
"${SCRIPT_DIR}"/generate-ssh-config.sh > "${TOP_DIR}"/ssh_config

cd "${TOP_DIR}"/ansible || exit
ansible-playbook -i inventory playbook.yml

# Go back to where the user started...
cd "${CURRENT_DIR}" || exit