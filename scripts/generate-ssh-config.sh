#!/bin/bash

#
# This script reads the output from the Terraform configuration
# in the terraform directory, and creates an SSH config file that
# allows simple use of the Bastion host to access the private
# cluster nodes
#

set -euo pipefail
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TOP_DIR=$( cd "$( dirname "${SCRIPT_DIR}" )" && pwd )
CURRENT_DIR="${PWD}"

# Get into the directory where the Terraform state file exists
cd "${TOP_DIR}/terraform" || exit

# Fetch the Bastion Public IP address
bastion_ip=$(cut -d"\"" -f4 <<< "$(terraform output bastion-ip)")

# Fetch the host-key of the bastion and add it to the local known_hosts file
ssh-keyscan -t rsa "${bastion_ip}" 2>/dev/null >> ~/.ssh/known_hosts 

# Create the start of the SSH Config file including the bastion config
ssh_config="Host k3s-bastion\n\tForwardAgent yes\n\tUser azure_user\n\tHostname ${bastion_ip}\n"

# Loop over each of the cluster machines and add them into the ssh config
while IFS= read -r line <&3; do
  # Skip lines that are just "{" or "}"
  if [[ ! $line =~ [\{\}] ]]; then
    # Get the VM resource name and private IP address
    vm_name=$(cut -d"\"" -f2 <<< "${line}")
    ip=$(cut -d"\"" -f4 <<< "${line}")
    # Write a line into the SSH Config
    ssh_config+="\nHost ${vm_name#*nic-k3s-cluster-}\n\tForwardAgent yes\n\tUser azure_user\n\tHostname ${ip}\n\tProxyJump k3s-bastion\n"
  fi
done 3<<<"$(terraform output cluster-ips)"

# Output the SSH config
echo -e "${ssh_config}"

# Get the user back to where they were!
cd "${CURRENT_DIR}" || exit
