locals {
  bas_vm_name     = "${var.prefix}-bas-vm"
  bas_vm_os_disk  = "${var.prefix}-bas-vm-os-disk"
  bas_vm_nic_name = "${var.prefix}-bas-vm-nic"
  bas_vm_vip_name = "${var.prefix}-bas-vm-vip"
}

resource azurerm_public_ip "bastion-vip" {
  name                = local.bas_vm_vip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku = "Standard"
  tags = var.tags
}

resource azurerm_network_interface "bastion_vm_nic" {
  name                = local.bas_vm_nic_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_5.id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id = azurerm_public_ip.bastion-vip.id
  }
}

resource azurerm_virtual_machine "bastion_vm" {
  name                             = local.bas_vm_name
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  network_interface_ids            = [azurerm_network_interface.bastion_vm_nic.id]
  vm_size                          = var.bastion_vm_sku
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = local.bas_vm_os_disk
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = local.bas_vm_name
    admin_username = "localadmin"
    custom_data    = data.local_file.cloudinit.content
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = var.ssh_key
      path     = "/home/localadmin/.ssh/authorized_keys"
    }
  }

  tags = var.tags
}
