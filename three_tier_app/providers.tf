provider "aws" {
  region = var.provider_configs["aws"].region
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.provider_configs["gcp"].project
  region  = var.provider_configs["gcp"].region
  zone    = var.provider_configs["gcp"].zone
}