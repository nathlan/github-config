variable "github_organization" {
  description = "GitHub organization name"
  type        = string
  default     = "nathlan"

  validation {
    condition     = length(var.github_organization) > 0
    error_message = "GitHub organization name must not be empty."
  }
}

variable "repository_name" {
  description = "Name of the repository to manage"
  type        = string
  default     = "alz-workload-template"
}

variable "repository_description" {
  description = "Description of the repository"
  type        = string
  default     = "Template repository for ALZ workload repositories with pre-configured Terraform workflows"
}

variable "repository_visibility" {
  description = "Visibility of the repository (public, private, or internal)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Repository visibility must be public, private, or internal."
  }
}

variable "repository_topics" {
  description = "Topics to add to the repository"
  type        = list(string)
  default     = ["azure", "terraform", "landing-zone", "template"]
}

variable "required_status_checks" {
  description = "List of required status checks for branch protection"
  type        = list(string)
  default     = ["validate", "security", "plan"]
}

variable "team_maintainers" {
  description = "Teams with maintain access to the repository"
  type        = list(string)
  default     = ["platform-engineering"]
}

variable "push_allowance_teams" {
  description = "Teams allowed to push to protected branches"
  type        = list(string)
  default     = ["platform-engineering"]
}
