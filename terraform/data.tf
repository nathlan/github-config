# Data source to reference the existing organization
data "github_organization" "org" {
  name = var.github_organization
}

# Data source to get the GitHub App ID for Copilot (if needed for bypass)
# GitHub Copilot App ID is typically 366842 for github-actions[bot]
# This can be used in bypass_actors if needed
