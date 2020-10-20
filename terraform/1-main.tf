// Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-k3s"
  location = var.location
}

// Create a virtual network the VM
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-k3s"
  address_space       = ["10.40.0.0/23"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

// Create a subnet for the bastion VM
resource "azurerm_subnet" "bastion" {
  name                 = "snet-k3s-bastion"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.40.0.0/24"]
}

// Create a subnet for the k3s machines
resource "azurerm_subnet" "main" {
  name                 = "snet-k3s-main"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.40.1.0/24"]
}