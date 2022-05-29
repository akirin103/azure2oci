resource "azurerm_resource_group" "this" {
  name     = "${var.system_name}-rg"
  location = var.location
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "2.6.0"
  resource_group_name = azurerm_resource_group.this.name
  vnet_name           = "${var.system_name}-vnet"
  address_space       = var.vnet_address_space
  subnet_prefixes     = var.vnet_subnet_prefixes
  subnet_names        = var.vnet_subnet_names
  vnet_location       = azurerm_resource_group.this.location
  route_tables_ids    = {}
  nsg_ids = {
    public = azurerm_network_security_group.public.id
  }
  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.system_name}-public-sg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "${var.system_name}-bastion-vm"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.virtual_machine_size
  admin_username      = "azureuser"
  custom_data         = data.template_cloudinit_config.config.rendered
  network_interface_ids = [
    azurerm_network_interface.bastion.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "server" {
  name                = "${var.system_name}-server-vm"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = var.virtual_machine_size
  admin_username      = "azureuser"
  custom_data         = data.template_cloudinit_config.config.rendered
  network_interface_ids = [
    azurerm_network_interface.server.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "bastion" {
  name                = "${var.system_name}-bastion-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = module.vnet.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion-pip.id
  }
}

resource "azurerm_network_interface" "server" {
  name                = "${var.system_name}-server-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "private"
    subnet_id                     = module.vnet.vnet_subnets[1]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "${var.system_name}-bastion-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "vngw_ip" {
  name                = "${var.system_name}-vngw-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = "${var.system_name}-vngw"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type = "ExpressRoute"
  sku  = "Standard"

  ip_configuration {
    name                 = "${var.system_name}-vngw-ip-config"
    public_ip_address_id = azurerm_public_ip.vngw_ip.id
    subnet_id            = module.vnet.vnet_subnets[2]
  }
}

resource "azurerm_express_route_circuit" "this" {
  name                  = "${var.system_name}-expressroute"
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  service_provider_name = "Oracle Cloud FastConnect"
  peering_location      = "Tokyo"
  bandwidth_in_mbps     = "100"
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

output "azure_bastion_vm_public_ip" {
  value = azurerm_linux_virtual_machine.bastion.public_ip_address
}

output "azure_server_vm_private_ip" {
  value = azurerm_linux_virtual_machine.server.private_ip_address
}
