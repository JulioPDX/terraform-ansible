output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address1" {
  value = azurerm_linux_virtual_machine.my_terraform_vm1.public_ip_address
}

output "public_ip_address2" {
  value = azurerm_linux_virtual_machine.my_terraform_vm2.public_ip_address
}
