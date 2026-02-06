# Example terraform.tfvars file
# Copy this to terraform.tfvars and customize with your values

github_organization = "nathlan"
repository_name     = "example-repo"
repository_description = "Example repository created with Terraform"
repository_visibility = "private"

# Branch protection settings
branch_protection_required_approving_review_count = 1

# Copilot firewall allowlist - these domains will be accessible by the Copilot agent
copilot_firewall_allowlist = [
  "registry.terraform.io",
  "checkpoint-api.hashicorp.com",
  "api0.prismacloud.io"
]

# Enable Copilot to create PRs from GitHub Actions
enable_copilot_pr_from_actions = true
