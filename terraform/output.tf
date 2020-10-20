output "bastion-ip" {
  description = "Public IP of Bastion VM"
  value = azurerm_public_ip.bastion.ip_address
}

output "cluster-ips" {
  value = {
    for nic in azurerm_network_interface.cluster:
    nic.name => nic.private_ip_address
  }
}