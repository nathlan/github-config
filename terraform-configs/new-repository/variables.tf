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

# GitHub App Authentication Variables (Optional - Alternative to PAT)
variable "github_app_id" {
  description = "GitHub App ID for authentication (alternative to PAT). Leave empty to use GITHUB_TOKEN."
  type        = string
  default     = ""
  sensitive   = false
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID for authentication. Required if using GitHub App."
  type        = string
  default     = ""
  sensitive   = false
}

variable "github_app_pem_file" {
  description = "Path to GitHub App private key PEM file. Required if using GitHub App."
  type        = string
  default     = ""
  sensitive   = false
}
