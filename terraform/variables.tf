# Name of the admin user for the system
variable "admin_name" {
  default = "marauder_admin"
}

# Name of the project
variable "project_name" {
  default = "marauder"
}

# Name of the resource group
variable "resource_group_name" {
  default = "rg-marauder-prod"
}

variable "location_name" {
  default = "usgovvirginia"
}

variable "n_workers" {
  default = 2
}

variable "worker_size" {
  default = "Standard_DS1_v2"
}

variable "master_size" {
  default = "Standard_DS1_v2"
}