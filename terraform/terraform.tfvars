# Example terraform.tfvars file
# Copy this to terraform.tfvars and customize with your values

github_organization = "nathlan"

# Define repositories as a list of objects
repositories = [
  {
    name        = "example-repo"
    description = "Example repository created with Terraform"
    visibility  = "private"
    branch_protection_required_approving_review_count = 1
  }
  # Add more repositories here:
  # {
  #   name        = "another-repo"
  #   description = "Another example repository"
  #   visibility  = "private"
  #   branch_protection_required_approving_review_count = 1
  # }
]

# Copilot firewall allowlist - these domains will be accessible by the Copilot agent
copilot_firewall_allowlist = [
  "registry.terraform.io",
  "checkpoint-api.hashicorp.com",
  "api0.prismacloud.io"
]

# Enable Copilot to create PRs from GitHub Actions
enable_copilot_pr_from_actions = true
