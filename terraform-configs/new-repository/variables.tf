variable "github_organization" {
  description = "The GitHub organization name"
  type        = string

  validation {
    condition     = length(var.github_organization) > 0
    error_message = "The github_organization value must not be empty."
  }
}

variable "repositories" {
  description = "List of repositories to create and manage"
  type = list(object({
    name                                          = string
    description                                   = string
    visibility                                    = string
    branch_protection_required_approving_review_count = number
  }))

  validation {
    condition = alltrue([
      for repo in var.repositories : can(regex("^[a-zA-Z0-9._-]+$", repo.name))
    ])
    error_message = "Repository names can only contain alphanumeric characters, hyphens, underscores, and periods."
  }

  validation {
    condition = alltrue([
      for repo in var.repositories : contains(["public", "private", "internal"], repo.visibility)
    ])
    error_message = "Repository visibility must be one of: public, private, or internal."
  }

  validation {
    condition = alltrue([
      for repo in var.repositories : repo.branch_protection_required_approving_review_count >= 0 && repo.branch_protection_required_approving_review_count <= 6
    ])
    error_message = "Required approving review count must be between 0 and 6."
  }
}

variable "copilot_firewall_allowlist" {
  description = "Additional domains to add to the Copilot agent firewall allowlist (consistent across all repositories)"
  type        = list(string)
  default = [
    "registry.terraform.io",
    "checkpoint-api.hashicorp.com",
    "api0.prismacloud.io"
  ]
}

variable "enable_copilot_pr_from_actions" {
  description = "Enable GitHub Copilot to raise PRs from GitHub Actions (applies to all repositories)"
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
