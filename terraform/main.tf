# Configure the Azure provider for Terraform
terraform {
  required_version = ">=0.12"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

###################################################################
########################## Logistics ##############################
###################################################################

# Create the resource group for the platform
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_name

  tags = {
    AdminPOC = "Nick Maynard"
  }
}

###################################################################
########################## Networking #############################
###################################################################

# # Create subnet for the platform
# resource "azurerm_subnet" "snet" {
#   name                 = "internal"
#   resource_group_name  = "rg-marauders-Networking"
#   virtual_network_name = "vnet-Marauders"
#   address_prefixes     = ["10.0.0.0/24"]
# }


# Create the network interface for the master machine.
resource "azurerm_network_interface" "nic_master" {
  name                = "nic-${var.project_name}-prod-${var.resource_group_name}-master"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/72e52578-1690-4216-a0a4-b062a6713c29/resourceGroups/rg-marauders-Networking/providers/Microsoft.Network/virtualNetworks/vnet-Marauders/subnets/default"
    private_ip_address_allocation = "Dynamic"
  }
}

# Create the network interfaces for the worker machines.
resource "azurerm_network_interface" "nic_workers" {
  count               = var.n_workers
  name                = "nic-${var.project_name}-prod-${var.resource_group_name}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/72e52578-1690-4216-a0a4-b062a6713c29/resourceGroups/rg-marauders-Networking/providers/Microsoft.Network/virtualNetworks/vnet-Marauders/subnets/default"
    private_ip_address_allocation = "Dynamic"
  }
  
}

###################################################################
####################### Virtual Machines ##########################
###################################################################

# Create the master machine for the hadoop cluster
resource "azurerm_linux_virtual_machine" "master_vm" {
  name                  = "vm-${var.project_name}-prod-${var.resource_group_name}-master"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_master.id]
  size                  = var.master_size

  # Create the OS disk.
  os_disk {
    name                 = "osdisk-${var.project_name}-prod-${var.resource_group_name}-master"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Specify our image for the master node.
  source_image_reference {
    publisher = "procomputers"
    offer     = "redhat-7-9"
    sku       = "redhat-7-9"
    version   = "latest"
  }

  plan {
    publisher = "procomputers"
    product = "redhat-7-9"
    name = "redhat-7-9"
  }

  admin_username = var.admin_name

  # Declare our SSH Key
  admin_ssh_key {
    username   = var.admin_name
    # public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    public_key = file("~/.ssh/dev_key.pub")
  }

  # Store our Diagnostic Data
  # boot_diagnostics {
  #   storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  # }
}

# Create the worker machine for the cluster
resource "azurerm_linux_virtual_machine" "worker_vm" {
  count                 = var.n_workers
  name                  = "vm-${var.project_name}-prod-${var.resource_group_name}-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_workers[count.index].id]
  size                  = var.worker_size

  # Create the OS disk.
  os_disk {
    name                 = "osdisk-${var.project_name}-prod-${var.resource_group_name}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Specify our image for the worker nodes.
  source_image_reference {
    publisher = "procomputers"
    offer     = "redhat-7-9"
    sku       = "redhat-7-9"
    version   = "latest"
  }

  plan {
    publisher = "procomputers"
    product = "redhat-7-9"
    name = "redhat-7-9"
  }

  admin_username = var.admin_name

  admin_ssh_key {
    username   = var.admin_name
    # public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    public_key = file("~/.ssh/dev_key.pub")
  }

  # boot_diagnostics {
  #   storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  # }
}

data "template_file" "ansible_hosts" {
  template = <<-EOT
[all:vars]
ansible_connection=ssh
#ansible_user=root
#ansible_ssh_private_key_file=~/.ssh/ibm_rsa
gather_facts=True
gathering=smart
host_key_checking=False
install_java=True
install_temp_dir=/tmp/ansible-install
install_dir=/opt/install
python_version=2

[master]
${azurerm_linux_virtual_machine.master_vm.name} ansible_host=${azurerm_linux_virtual_machine.master_vm.private_ip_address} private_ip=${azurerm_linux_virtual_machine.master_vm.private_ip_address} index=0

[nodes]
%{ for idx, vm in azurerm_linux_virtual_machine.worker_vm }
${vm.name} ansible_host=${vm.private_ip_address} private_ip=${vm.private_ip_address} index=${idx+1}
%{ endfor }
  EOT

  vars = {
    azurerm_linux_virtual_machine = "test"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "ansible_hosts"
  content  = data.template_file.ansible_hosts.rendered
}