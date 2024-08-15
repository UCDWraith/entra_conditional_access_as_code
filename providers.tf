# Configure Terraform to set the required AzureRM provider
# version and features{} block.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.96.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.52.0"
    }
  }

  backend "azurerm" {
    # intentionally blank. Parameters passed via the DevOps YAML pipeline
  }
}

provider "azurerm" {
  features {}
}