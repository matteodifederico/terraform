#region Terraform configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}
#endregion

#region Resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.name}-${var.environment}"
  location = var.region

  tags = {
    environment = "${var.environment}"
    businessimpact = var.businessImpact
    workload = var.name
  }
}
#endregion

#region VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.name}"
  address_space       = var.network.VNETAddressSpace
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
#endregion

#region Subnets
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.network.subNetPrefixes
}
#endregion

#region Public IPs
resource "azurerm_public_ip" "public-ips" {
  name                = "public-ip-${var.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = var.network.publicIpAllocationMethod
}
#endregion

#region Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
#endregion

#region Network Interface Card
resource "azurerm_network_interface" "nic" {
  name = "nic-${var.name}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "ipconfig-${var.name}"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = var.network.privateIpAllocationMethod
    public_ip_address_id = azurerm_public_ip.public-ips.id
  }
}

#region Connect security group to network interface
resource "azurerm_network_interface_security_group_association" "nsg-association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
#endregion

#region Storage account for boot diagnostics
resource "azurerm_storage_account" "storage-account" {
  name = "storage-${var.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  account_tier = var.storage.tier
  account_kind = var.storage.type
  account_replication_type = var.storage.replication
}
#endregion

#region Virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm-${var.name}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm.size
  admin_username        = var.vm.adminUsername
  admin_password        = var.vm.adminPassword
  network_interface_ids = [azurerm_network_interface.nic.id]
  os_disk {
    name              = "osdisk-${var.name}"
    caching           = var.vm.osDisk.caching
    storage_account_type = var.vm.osDisk.storageAccountType
  }
  source_image_reference {
    publisher = var.vm.image.publisher
    offer     = var.vm.image.offer
    sku       = var.vm.image.sku
    version   = var.vm.image.version
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage-account.primary_blob_endpoint
  }
}
#endregion

#region Install IIS
resource "azurerm_virtual_machine_extension" "vm-extension" {
  name                 = "vm-ext-${var.name}"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -Name Web-Server -IncludeManagementTools"
    }
  SETTINGS
}
#endregion