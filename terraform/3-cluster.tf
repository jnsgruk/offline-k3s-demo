// Setup an NSG and associate with the NIC
resource "azurerm_network_security_group" "cluster" {
  name                = "nsg-k3s-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  // Create a rule that allows SSH traffic *only* from the machine deploying using Terraform
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.40.0.0/24"
    destination_address_prefix = "10.40.1.0/24"
  }
  // Block internet access for cluster VMs
  security_rule {
    name                       = "Internet"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.40.1.0/24"
    destination_address_prefix = "Internet"
  }
}

// Create the  VM NIC and associate with the Public IP
resource "azurerm_network_interface" "cluster" {
  for_each            = var.servers
  name                = "nic-k3s-cluster-${each.value}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "default"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}


// Associate the NSG with the VM's Network Interface
resource "azurerm_network_interface_security_group_association" "cluster" {
  for_each                  = var.servers
  network_interface_id      = azurerm_network_interface.cluster[each.key].id
  network_security_group_id = azurerm_network_security_group.cluster.id
}

// Create the VM
resource "azurerm_linux_virtual_machine" "cluster" {
  for_each              = var.servers
  name                  = each.value
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.cluster[each.key].id]
  size                  = "Standard_D4_v4"
  admin_username        = "azure_user"

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8.0"
    version   = "8.0.201912060"
  }

  os_disk {
    name                 = "disk-k3s-cluster-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "azure_user"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  identity {
    type = "SystemAssigned"
  }
}