variable "github_owner" {
  type = string
}

variable "github_app_id" {
  type = string
}

variable "github_app_installation_id" {
  type = string
}

variable "github_app_pem_file" {
  type = string
}

variable "template_repositories" {
  description = "List of repositories to create from alz-workload-template with common settings"
  type = list(object({
    name                                              = string
    description                                       = string
    visibility                                        = string
    branch_protection_required_approving_review_count = number
  }))
  default = []

  validation {
    condition = alltrue([
      for repo in var.template_repositories : can(regex("^[a-zA-Z0-9._-]+$", repo.name))
    ])
    error_message = "Repository names can only contain alphanumeric characters, hyphens, underscores, and periods."
  }

  validation {
    condition = alltrue([
      for repo in var.template_repositories : contains(["public", "private", "internal"], repo.visibility)
    ])
    error_message = "Repository visibility must be one of: public, private, or internal."
  }

  validation {
    condition = alltrue([
      for repo in var.template_repositories : repo.branch_protection_required_approving_review_count >= 0 && repo.branch_protection_required_approving_review_count <= 6
    ])
    error_message = "Required approving review count must be between 0 and 6."
  }
}

variable "non_template_repositories" {
  description = "List of repositories to create without template (auto_init with README) with common settings"
  type = list(object({
    name                                              = string
    description                                       = string
    visibility                                        = string
    branch_protection_required_approving_review_count = number
  }))
  default = []

  validation {
    condition = alltrue([
      for repo in var.non_template_repositories : can(regex("^[a-zA-Z0-9._-]+$", repo.name))
    ])
    error_message = "Repository names can only contain alphanumeric characters, hyphens, underscores, and periods."
  }

  validation {
    condition = alltrue([
      for repo in var.non_template_repositories : contains(["public", "private", "internal"], repo.visibility)
    ])
    error_message = "Repository visibility must be one of: public, private, or internal."
  }

  validation {
    condition = alltrue([
      for repo in var.non_template_repositories : repo.branch_protection_required_approving_review_count >= 0 && repo.branch_protection_required_approving_review_count <= 6
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

variable "manage_copilot_firewall_variable" {
  description = "Create COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS repository variable. Requires GitHub App with 'Actions: Read and write' permission."
  type        = bool
  default     = true
}
