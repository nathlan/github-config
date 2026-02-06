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
