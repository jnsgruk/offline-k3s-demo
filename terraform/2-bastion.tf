// Create a public IP for the bastion VM
resource "azurerm_public_ip" "bastion" {
  name                = "pip-k3s-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

// Create the  VM NIC and associate with the Public IP
resource "azurerm_network_interface" "bastion" {
  name                = "nic-k3s-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "default"
    subnet_id                     = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

// Setup an NSG and associate with the NIC
resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-k3s-bastion"
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
    source_address_prefix      = chomp(data.http.client_ip.body)
    destination_address_prefix = "*"
  }
}

// Associate the NSG with the VM's Network Interface
resource "azurerm_network_interface_security_group_association" "bastion" {
  network_interface_id      = azurerm_network_interface.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

// Create the VM
resource "azurerm_linux_virtual_machine" "bastion" {
  name                  = "bastion"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.bastion.id]
  size                  = "Standard_B1s"
  admin_username        = "azure_user"

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8.0"
    version   = "8.0.201912060"
  }

  os_disk {
    name                 = "disk-k3s-bastion"
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