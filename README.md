# Terraform and Ansible

This is a quick example to see Terraform and Ansible working together.

## Requirements

This example leverages Azure. A valid Azure account and `az cli` are required to run through this example.

1. Install [Terrform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
2. Install [az cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
3. Authenticate to [Azure using the CLI](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli)
4. `git clone` this repository

## Python requirements

I like to use a virtual environment when leveraging Python. The only specific Python install we need is Ansible core and one galaxy collection.

```shell
python3 -m venv venv
source venv/bin/activate
pip3 install ansible-core
ansible-galaxy collection install cloud.terraform
```

## Build the infrastructure

Run `terraform apply` to deploy the infrastructure.

```shell
❯ terraform apply
...
ansible_host.vm2: Refreshing state... [id=myVM2]
ansible_host.vm1: Refreshing state... [id=myVM1]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

public_ip_address1 = "x.x.x.x"
public_ip_address2 = "x.x.x.x"
resource_group_name = "tf-rg"
```

The new feature here is the addition of the Ansible provider within our `providers.tf` file.

```terraform
terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~>1.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

We can then use this provider to build new "resources" that are leveraged in future Ansible playbook runs.

```terraform
# main.tf
resource "ansible_host" "vm1" {
  name   = azurerm_linux_virtual_machine.my_terraform_vm1.name
  groups = ["linux"]
  variables = {
    ansible_user     = "azureuser"
    ansible_password = "Super123!"
    ansible_host     = azurerm_linux_virtual_machine.my_terraform_vm1.public_ip_address
  }
}

resource "ansible_host" "vm2" {
  name   = azurerm_linux_virtual_machine.my_terraform_vm2.name
  groups = ["linux"]
  variables = {
    ansible_user     = "azureuser"
    ansible_password = "Super123!"
    ansible_host     = azurerm_linux_virtual_machine.my_terraform_vm2.public_ip_address
  }
}
```

The portions above set a few variables required to connect to remote nodes when using Ansible. The `inventory.yml` file then leverages the `cloud.terraform` collection to build an inventory from the Terraform state.

```shell
ansible-galaxy collection install cloud.terraform
```

```yaml
# inventory.yml
---
plugin: cloud.terraform.terraform_provider

```

```shell
ansible-inventory -i inventory.yml --graph --vars
```

```shell
❯ ansible-inventory -i inventory.yml --graph --vars
@all:
  |--@ungrouped:
  |--@linux:
  |  |--myVM1
  |  |  |--{ansible_host = x.x.x.x}
  |  |  |--{ansible_password = Super123!}
  |  |  |--{ansible_user = azureuser}
  |  |--myVM2
  |  |  |--{ansible_host = x.x.x.x}
  |  |  |--{ansible_password = Super123!}
  |  |  |--{ansible_user = azureuser}
```

Once this is all provisioned, we can point our playbook to the `linux` group.

```yaml
# play.yml
---
- name: Checking cloud connectivity
  gather_facts: false
  hosts: linux
  become: true
  tasks:

  - name: Install NGINX
    ansible.builtin.package:
      name: nginx
      state: present
```
