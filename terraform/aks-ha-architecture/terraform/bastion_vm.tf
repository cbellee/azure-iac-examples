locals {
  region1_bas_vm_name     = "${var.prefix}-${var.region1.locationShortName}-bas-vm"
  region2_bas_vm_name     = "${var.prefix}-${var.region2.locationShortName}-bas-vm"
  region1_bas_vm_os_disk  = "${var.prefix}-${var.region1.locationShortName}-bas-vm-os-disk"
  region2_bas_vm_os_disk  = "${var.prefix}-${var.region2.locationShortName}-bas-vm-os-disk"
  region1_bas_vm_pip_name = "${var.prefix}-${var.region1.locationShortName}-bas-vm-pip"
  region2_bas_vm_pip_name = "${var.prefix}-${var.region2.locationShortName}-bas-vm-pip"
  region1_bas_vm_nic_name = "${var.prefix}-${var.region1.locationShortName}-bas-vm-nic"
  region2_bas_vm_nic_name = "${var.prefix}-${var.region2.locationShortName}-bas-vm-nic"
}

resource azurerm_public_ip "region1_bastion_vm_pip" {
  name                = local.region1_bas_vm_pip_name
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource azurerm_network_interface "region1_bastion_vm_nic" {
  name                = local.region1_bas_vm_nic_name
  resource_group_name = azurerm_resource_group.region1_rg.name
  location            = azurerm_resource_group.region1_rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.region1_hub_subnet_3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.region1_bastion_vm_pip.id
  }
}

resource azurerm_virtual_machine "region1_bastion_vm" {
  name                             = local.region1_bas_vm_name
  resource_group_name              = azurerm_resource_group.region1_rg.name
  location                         = azurerm_resource_group.region1_rg.location
  network_interface_ids            = [azurerm_network_interface.region1_bastion_vm_nic.id]
  vm_size                          = var.bastionVmSku
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = local.region1_bas_vm_os_disk
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.region1_bas_vm_name
    admin_username = "localadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = var.sshKey
      path     = "/home/localadmin/.ssh/authorized_keys"
    }
  }

  tags = {
    environment = "staging"
  }
}

# region2

resource azurerm_public_ip "region2_bastion_vm_pip" {
  name                = local.region2_bas_vm_pip_name
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource azurerm_network_interface "region2_bastion_vm_nic" {
  name                = local.region2_bas_vm_nic_name
  resource_group_name = azurerm_resource_group.region2_rg.name
  location            = azurerm_resource_group.region2_rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.region2_hub_subnet_3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.region2_bastion_vm_pip.id
  }
}

resource azurerm_virtual_machine "region2_bastion_vm" {
  name                             = local.region2_bas_vm_name
  resource_group_name              = azurerm_resource_group.region2_rg.name
  location                         = azurerm_resource_group.region2_rg.location
  network_interface_ids            = [azurerm_network_interface.region2_bastion_vm_nic.id]
  vm_size                          = var.bastionVmSku
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = local.region1_bas_vm_os_disk
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.region2_bas_vm_name
    admin_username = "localadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = var.sshKey
      path     = "/home/localadmin/.ssh/authorized_keys"
    }
  }

  tags = {
    environment = "staging"
  }
}
