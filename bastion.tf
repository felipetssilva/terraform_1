provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rs" {
  name     = "rsBastion"
  location = "West Europe"
  tags     = var.bastion_tags
}

resource "azurerm_virtual_network" "vn" {
  name                = "vnBastion"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rs.location
  resource_group_name = azurerm_resource_group.rs.name
}
resource "azurerm_subnet" "sn" {
  name                 = "subnetThatFailed"
  resource_group_name  = azurerm_resource_group.rs.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "snForBastian" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rs.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.1.0/27"]
}

resource "azurerm_public_ip" "bip" {
  name                = "ipBastion"
  location            = azurerm_resource_group.rs.location
  resource_group_name = azurerm_resource_group.rs.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bh" {
  name                = "hostBastion"
  location            = azurerm_resource_group.rs.location
  resource_group_name = azurerm_resource_group.rs.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.snForBastian.id
    public_ip_address_id = azurerm_public_ip.bip.id
  }
}
resource "azurerm_network_interface" "nic" {
  //depends_on          = [azurerm_public_ip.bip]
  name                = "nicBastion"
  location            = azurerm_resource_group.rs.location
  resource_group_name = azurerm_resource_group.rs.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm1" {
  // depends_on = [azurerm_network_interface.nic]

  name                = "winVM"
  resource_group_name = azurerm_resource_group.rs.name
  location            = azurerm_resource_group.rs.location
  size                = "Standard_DS1_v2"
  admin_username      = var.admin1
  admin_password      = var.pass1
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    name                 = "MyOSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h1-pro-g2"
    version   = "latest"
  }
}


resource "azurerm_network_security_group" "nsg" {
  name                = "nsgForBastion"
  location            = azurerm_resource_group.rs.location
  resource_group_name = azurerm_resource_group.rs.name

  security_rule {
    name                       = var.rule_name1
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = var.port_range1
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsga" {
  subnet_id                 = azurerm_subnet.sn.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

output "resource_group_data" {
  value = azurerm_resource_group.rs
}

