# ============================================================================
# Terraform and Provider Version Constraints
# ============================================================================
# Defines minimum Terraform version and required provider versions

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
  }

  # Optional: Configure remote backend for state management
  # Uncomment and configure one of the following for production use:
  #
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "github-config/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
  #
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatestorage"
  #   container_name       = "tfstate"
  #   key                  = "github-config.tfstate"
  # }
}
