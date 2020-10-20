### Offline K3s Deployment

This repository contains a set of bash scripts, Terraform definitions and Ansible playbooks to demonstrate how to deploy and "air-gapped" [Rancher K3s](https://k3s.io/) cluster. This is demonstrated in a test environment on Microsoft Azure.

The test environment consists of four virtual machines:

1. 1x Bastion Host: This is accessible from the internet by SSH, and can access the cluster machines
2. 3x Cluster Node: No access to the internet, accessible by SSH from the bastion

Note that by default, the Network Security Group that controls SSH access to the bastion host will only allow connections from the IP that created the resource using Terraform.

All nodes are deployed with CentOS 8.

### Get Started

First, ensure that you have the following tools installed and available in your PATH:

- [terraform](https://terraform.io)
- [ansible](https://ansible.com)
- [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

In order for the Terraform to deploy, the Azure CLI must be logged in to a valid subscription using `az login`. It is also possible to configure Terraform to authenticate with Azure using environment variables that specify a service principal - but the `az login` method is most simple.

Once the pre-requisites are installed, just run: `./scripts/deploy-demo-env.sh`

### What does the automation actually do?

1. Creates an RSA SSH Key at `~/.ssh/id_rsa` if it doesn't already exist. This is the identity used to SSH into all of the machines
2. Download a local copy of all of the RPMs, binaries and configuration required to bootstrap an offline cluster. This is done using the [get-file.sh](./scripts/get-files.sh) script.
3. Deploy a testing environment using [Terraform](./terraform)
4. Use Ansible to:
   - Install `kubectl` and `helm` on all machines
   - Perform system specific config (selinux, iptables, etc)
   - Copy across dependency RPMs and install them
   - Copy across K3s binaries, install script and offline image
   - Bootstrap the cluster and join the nodes

### Using Ansible Playbook outside of Azure

To deploy this configuration to a set of local machines or VMs, simply adjust the [inventory](./ansible/inventory) so that the `master` and `nodes` group contain the IP addresses or hostnames of the various nodes in your environment. You will likely be able to remove the `bastion` group completely in this scenario.

Note that you will still need to populate the `<repository_root>/files` directory using the [get-files.sh](./scripts/get-files.sh) so that Ansible can copy across all the necessary dependencies. This will obviously need to be done on machine with internet access.

To run the playbook and configure your hosts:

```bash
$ cd ansible/
# Specify '-K' to prompt the use for the sudo password on remote hosts
$ ansible-playbook -K -i inventory playbook.yml
```

Note that Ansible requires the hosts to be accessible over SSH using public key authentication. The example [inventory](./ansible/inventory) specifies a variable to prevent host key checking - this can be omitted if the machine running Ansible has already SSHd into the remote hosts and accepted their host keys.

### Verifying the deployment was successful

Once the Ansible playbook has completed, you should be able to SSH into the master node and check that the two agent nodes are registered:

```bash
$ ssh node-0
$ sudo k3s kubectl get nodes
NAME     STATUS   ROLES    AGE   VERSION
node-1   Ready    <none>   86m   v1.18.10+k3s1
node-2   Ready    <none>   86m   v1.18.10+k3s1
node-0   Ready    master   86m   v1.18.10+k3s1
```

### Cleaning up

Once you have finished experimenting, you can run the [cleanup.sh](./scripts/cleanup.sh) to remove all resources.

**WARNING**: This will delete all cloud resources, cached offline files and configuration.

### Limitations

- For the purposes of testing, `selinux` is disabled. This can be rectified in production if needed.
- The cluster, while deployed and functioning, is a little useless until a locally accessible registry is deployed
- The [get-files.sh](./scripts/get-files.sh) script has hardcoded URLs for RPM dependencies. These were valid and working at the time of writing (20/10/2020). If at any point the RPMs need refreshing, or RPMs need to be fetched another way, this can be done either by:
  - `yum install -y --downloadonly --downloaddir=<directory> <package>` to download all RPMs associated with a specific package
  - `yumdownloader --urls <package>` - fetches the URL pointing to the RPM for a specific package
