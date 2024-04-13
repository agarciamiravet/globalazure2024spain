terraform {
  backend "azurerm" {
   resource_group_name  = "rg-globalazure-2022-spain-terraform"
   storage_account_name = "stgazspainterraform"
  container_name       = "tfstate"
   key                  = "terraform.remote.tfstate"
 }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.98.0"
    }
  }
}