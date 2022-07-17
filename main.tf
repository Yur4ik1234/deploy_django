
terraform {
  required_version =  " 1.2.1 "
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.30"
    }
  }
}

provider "azurerm" {
  features {}
}

// Creating resource group
resource "azurerm_resource_group" "res-1" {
    name     = "${var.prefix}-resource_group"
    location = "West Europe"
}


// Creating virtual network
resource "azurerm_virtual_network" "vnet-1"{
  name                = "${var.prefix}-vnet" 
  location            = azurerm_resource_group.res-1.location
  resource_group_name = azurerm_resource_group.res-1.name
  address_space       = ["10.0.0.0/16"]
}
// Creating subnet 
resource "azurerm_subnet" "subnet-1"{
    name              = "${var.prefix}-sub" 
    resource_group_name = azurerm_resource_group.res-1.name
    virtual_network_name = azurerm_virtual_network.vnet-1.name 
    address_prefixes    = ["10.0.0.0/24"]
  }

// Creating nsg for network 
resource "azurerm_network_security_group" "nsg-1"{
  name                = "${var.prefix}-nsg" 
  location            = azurerm_resource_group.res-1.location
  resource_group_name = azurerm_resource_group.res-1.name

// Allowing ssh
  security_rule {
    name                       = "SSH"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 340
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTPS"
    priority                   = 360
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}

// Adding nsg to subnet
resource "azurerm_subnet_network_security_group_association" "sub-sec" {
  subnet_id                 = azurerm_subnet.subnet-1.id
  network_security_group_id = azurerm_network_security_group.nsg-1.id
}

// Creating public ip for loadbalancer
resource "azurerm_public_ip" "vip" {
  name                = "test"
  location            = azurerm_resource_group.res-1.location
  resource_group_name = azurerm_resource_group.res-1.name
  allocation_method   = "Static"
  

  tags = {
    environment = "staging"
  }
}




// Creating loadbalancer

resource "azurerm_lb" "lb-1" {
  name                = "lb-1"
  location            = azurerm_resource_group.res-1.location
  resource_group_name = azurerm_resource_group.res-1.name
// Adding public ip to loadbalancer
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.vip.id
  }

}
// Creating backend address pool which will contain our vmss
resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id     = azurerm_lb.lb-1.id
  name                = "BackEndAddressPool"

 
}
// Creating health probe of loadbalancer
resource "azurerm_lb_probe" "hth-1" {
 resource_group_name = azurerm_resource_group.res-1.name
 loadbalancer_id     = azurerm_lb.lb-1.id
 name                = "hth-1"
 port                = 80

}


// Creating loadbalancer rule which allow trafic to balancer from 80 port
resource "azurerm_lb_rule" "lbnatrule" {
   resource_group_name            = azurerm_resource_group.res-1.name
   loadbalancer_id                = azurerm_lb.lb-1.id
   name                           = "http"
   protocol                       = "TCP"
   frontend_port                  = 80
   backend_port                   = 80
   backend_address_pool_ids        = [azurerm_lb_backend_address_pool.bpepool.id]
   frontend_ip_configuration_name = "PublicIPAddress"
   probe_id                       = azurerm_lb_probe.hth-1.id
}

//creat vm
/*resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.res-1.location
  resource_group_name   = azurerm_resource_group.res-1.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
   publisher = "Canonical"
   offer     = "0001-com-ubuntu-server-focal"
   sku       = "20_04-lts-gen2"
   version   = "latest"
 }

  storage_os_disk {
    name              = "disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
   os_profile {
    computer_name        = "testvm"
    admin_username       = "adminuser"
   // admin_password     = "Yura111!"
   }
  os_profile_linux_config {
    disable_password_authentication = true

  ssh_keys {
    path     = "/home/adminuser/.ssh/authorized_keys"
    key_data = file("~/.ssh/id_rsa.pub")
  }
}
}
*/

// Creating vmss
resource "azurerm_virtual_machine_scale_set" "vmss-1" {
  name                = "example-vmss"
  resource_group_name = azurerm_resource_group.res-1.name
  location            = azurerm_resource_group.res-1.location
  upgrade_policy_mode  = "Manual"


  # required when using rolling upgrade policy
  
  
  // capacity it is number of instaneces in our vmss
  sku {
   name     = "Standard_DS1_v2"
   tier     = "Standard"
   capacity = 1

 }

storage_profile_image_reference {
   publisher = "Canonical"
   offer     = "0001-com-ubuntu-server-focal"
   sku       = "20_04-lts-gen2"
   version   = "latest"
 }

 storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 30
  }

   os_profile {
    computer_name_prefix = "testvm"
    admin_username       = "adminuser"
   // admin_password       = "Yura111!"
   }

   os_profile_linux_config {
    disable_password_authentication = true

  ssh_keys {
    path     = "/home/adminuser/.ssh/authorized_keys"
    key_data = file("~/.ssh/id_rsa.pub")
  }

   }
 
  network_profile {
    name    = "vmss-net"
    primary = true


    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet-1.id
     load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bpepool.id]
      
    // adding public dns label for our instances
   public_ip_address_configuration{
      name = "pip"
      domain_name_label = "deploy-vmsc-ubuntu"
      idle_timeout =  4

   }
     
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "auto" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.res-1.name
  location            = azurerm_resource_group.res-1.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss-1.id

  profile {
    name = "Weekends"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss-1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss-1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT1M"
      }
    }

    recurrence {
      timezone  = "Pacific Standard Time"
      days      = ["Saturday", "Sunday"]
      hours     = [12]
      minutes   = [0]
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["admin@contoso.com"]
    }
  }
}
