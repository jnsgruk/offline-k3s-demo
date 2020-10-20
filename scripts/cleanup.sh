#!/bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TOP_DIR=$( cd "$( dirname "${SCRIPT_DIR}" )" && pwd )

cd "${TOP_DIR}/terraform" || exit
terraform destroy --auto-approve

rm -rfv "${TOP_DIR}/files"
rm -rfv "${TOP_DIR}/ssh_config"
rm -rfv "${TOP_DIR}/terraform/.terraform"
rm -rfv "${TOP_DIR}/terraform/terraform.tfstate"
rm -rfv "${TOP_DIR}/terraform/terraform.tfstate.backup"



