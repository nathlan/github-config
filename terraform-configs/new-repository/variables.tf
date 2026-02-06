variable "github_organization" {
  description = "The GitHub organization name"
  type        = string

  validation {
    condition     = length(var.github_organization) > 0
    error_message = "The github_organization value must not be empty."
  }
}

variable "repository_name" {
  description = "The name of the repository to create"
  type        = string
  default     = "example-repo"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.repository_name))
    error_message = "Repository name can only contain alphanumeric characters, hyphens, underscores, and periods."
  }
}

variable "repository_description" {
  description = "A description of the repository"
  type        = string
  default     = "Repository managed by Terraform"
}

variable "repository_visibility" {
  description = "The visibility of the repository (public, private, or internal)"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Repository visibility must be one of: public, private, or internal."
  }
}

variable "copilot_firewall_allowlist" {
  description = "Additional domains to add to the Copilot agent firewall allowlist"
  type        = list(string)
  default = [
    "registry.terraform.io",
    "checkpoint-api.hashicorp.com",
    "api0.prismacloud.io"
  ]
}

variable "branch_protection_required_approving_review_count" {
  description = "Number of approving reviews required before a pull request can be merged"
  type        = number
  default     = 1

  validation {
    condition     = var.branch_protection_required_approving_review_count >= 0 && var.branch_protection_required_approving_review_count <= 6
    error_message = "Required approving review count must be between 0 and 6."
  }
}

variable "enable_copilot_pr_from_actions" {
  description = "Enable GitHub Copilot to raise PRs from GitHub Actions"
  type        = bool
  default     = true
}

# GitHub App Authentication Variables
# These are mapped from GitHub secrets/variables in the CI/CD workflow:
# - GH_CONFIG_APP_ID → GITHUB_APP_ID
# - GH_CONFIG_INSTALLATION_ID → GITHUB_APP_INSTALLATION_ID
# - GH_CONFIG_PRIVATE_KEY → GITHUB_APP_PEM_FILE
#
# The provider reads these environment variables automatically when app_auth {} is used

variable "app_id" {
  description = "GitHub App ID for authentication. Set via GITHUB_APP_ID environment variable (mapped from GH_CONFIG_APP_ID in workflow)."
  type        = string
  default     = ""
  sensitive   = false
}

variable "app_installation_id" {
  description = "GitHub App Installation ID for authentication. Set via GITHUB_APP_INSTALLATION_ID environment variable (mapped from GH_CONFIG_INSTALLATION_ID in workflow)."
  type        = string
  default     = ""
  sensitive   = false
}

variable "app_pem_file" {
  description = "Path to GitHub App private key PEM file or PEM content. Set via GITHUB_APP_PEM_FILE environment variable (mapped from GH_CONFIG_PRIVATE_KEY in workflow)."
  type        = string
  default     = ""
  sensitive   = true
}
