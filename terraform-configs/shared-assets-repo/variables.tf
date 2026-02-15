variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
  default     = "nathlan"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.github_owner))
    error_message = "GitHub owner must contain only alphanumeric characters and hyphens."
  }
}

variable "github_app_id" {
  description = "GitHub App ID for authentication"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
  sensitive   = true
}

variable "github_app_pem_file" {
  description = "GitHub App PEM file content or path"
  type        = string
  sensitive   = true
}

variable "repository_name" {
  description = "Name of the repository to create"
  type        = string
  default     = "shared-assets"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.repository_name))
    error_message = "Repository name can only contain alphanumeric characters, hyphens, underscores, and periods."
  }
}

variable "repository_description" {
  description = "Description of the repository"
  type        = string
  default     = "Shared assets and resources"
}

variable "repository_visibility" {
  description = "Repository visibility (public, private, or internal)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Repository visibility must be one of: public, private, or internal."
  }
}

variable "branch_protection_required_approving_review_count" {
  description = "Number of required approving reviews before merging"
  type        = number
  default     = 1

  validation {
    condition     = var.branch_protection_required_approving_review_count >= 0 && var.branch_protection_required_approving_review_count <= 6
    error_message = "Required approving review count must be between 0 and 6."
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

variable "enable_copilot_pr_from_actions" {
  description = "Enable GitHub Copilot to raise PRs from GitHub Actions"
  type        = bool
  default     = true
}

variable "manage_copilot_firewall_variable" {
  description = "Create COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS repository variable"
  type        = bool
  default     = true
}
