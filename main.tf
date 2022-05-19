terraform {
  required_version = ">= 1.1.9"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.5.0"
    }

    oci = {
      source  = "oracle/oci"
      version = "=4.74.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "oci" {}
