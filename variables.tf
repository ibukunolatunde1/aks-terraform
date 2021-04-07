# Resource Space Variables 
variable location {
  description = "azure location to deploy resources"
  default     = "westeurope"
}

variable resource_group_name {
  description = "name of the resource group to deploy AKS cluster in"
  default     = "deimos-aks"
}

variable "environment" {
  description = "Environment"
  # default = "dev" #Commenting the value for use in Azure DevOps
}

# AKS Variables

variable "ssh_public_key" {
  # default = "~/.ssh/aks-prod-sshkeys/aksprodsshkey.pub" #Commenting the value for use in Azure DevOps
  description = "SSH Key for Linux VMs"
}

variable "node_count" {
  description = "number of nodes to deploy"
  default     = 1
}

variable "min_count" {
  description = "min number of nodes to deploy"
  default     = 1
}

variable "max_count" {
  description = "max number of nodes to deploy"
  default     = 3
}

variable "os_disk_size_gb" {
  description = "Size of VM in GB"
  default     = 30
}

variable "vm_size" {
  description = "size/type of VM to use for nodes"
  default     = "Standard_D2_v2"
}

