terraform {
  required_version = ">= 0.13"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 1.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    #Commenting the values for use in Azure DevOps

    # resource_group_name = "storage-rg"
    # storage_account_name = "deimos01storage"
    # container_name = "tfstatefiles"
    # key = "${var.environment}.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "random_pet" "aksrandom" {
}

resource "azurerm_resource_group" "aks_rg" {
    name     = "${var.resource_group_name}-${var.environment}"
    location = var.location
}

data "azurerm_kubernetes_service_versions" "current" {
  location = azurerm_resource_group.aks_rg.location
  include_preview = false
}

# Create Virtual Network
resource "azurerm_virtual_network" "aksvnet" {
  name                = "aks-network"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = ["10.0.0.0/8"]
}

# Create a Subnet for AKS
resource "azurerm_subnet" "aks-default" {
  name                 = "aks-default-subnet"
  virtual_network_name = azurerm_virtual_network.aksvnet.name
  resource_group_name  = azurerm_resource_group.aks_rg.name
  address_prefixes     = ["10.240.0.0/16"]
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${azurerm_resource_group.aks_rg.name}-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${azurerm_resource_group.aks_rg.name}-dns"
  kubernetes_version  = "1.19"
  node_resource_group = "${azurerm_resource_group.aks_rg.name}-nrg"

  default_node_pool {
    name                 = "systempool"
    vm_size              = "Standard_DS2_v2"
    orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
    availability_zones   = [1, 2, 3]
    enable_auto_scaling  = true
    # node_count           = var.node_count
    max_count            = var.max_count
    min_count            = var.min_count
    os_disk_size_gb      = var.os_disk_size_gb
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id        = azurerm_subnet.aks-default.id 
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = var.environment
      "nodepoolos"       = "linux"
      "app"              = "system-apps" 
    } 
   tags = {
      "nodepool-type"    = "system"
      "environment"      = var.environment
      "nodepoolos"       = "linux"
      "app"              = "system-apps" 
   } 
  }

# Identity (System Assigned or Service Principal)
  identity {
    type = "SystemAssigned"
  }

# Add On Profiles - Will remove this also
  # addon_profile {
  #   azure_policy {enabled =  true}
  #   oms_agent {
  #     enabled =  true
  #     log_analytics_workspace_id = azurerm_log_analytics_workspace.insights.id
  #   }
  # }

# RBAC and Azure AD Integration Block
  # role_based_access_control {
  #   enabled = true
  #   azure_active_directory {
  #     managed = true
  #     admin_group_object_ids = [azuread_group.aks_administrators.id]
  #   }
  # }

# Linux Profile
  linux_profile {
    admin_username = "ubuntu"
    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

# Network Profile
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "Standard"
  }

  tags = {
    Environment = "dev"
  }
}

#Need to remove this if switching to Elastic Search
# resource "azurerm_log_analytics_workspace" "insights" {
#   name                = "${var.environment}-logs-${random_pet.aksrandom.id}"
#   location            = azurerm_resource_group.aks_rg.location
#   resource_group_name = azurerm_resource_group.aks_rg.name
#   retention_in_days   = 30
# }

# resource "azuread_group" "aks_administrators" {
#   name        = "${azurerm_resource_group.aks_rg.name}-cluster-administrators"
#   description = "Azure AKS Kubernetes administrators for the ${azurerm_resource_group.aks_rg.name}-cluster."
# }