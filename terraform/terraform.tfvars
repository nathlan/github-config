# ============================================================================
# Template-based Repositories
# ============================================================================
# Repositories created from alz-workload-template with pre-configured workflows
template_repositories = [
  {
    name                                              = "example-repo"
    description                                       = "Example repository created with Terraform"
    visibility                                        = "public"
    branch_protection_required_approving_review_count = 1
    # Optional: Direct user collaborators with permissions
    collaborators = [
      {
        username   = "nathanjnorris"
        permission = "maintain"
      }
    ]
    # Optional: Team access with permissions
    teams = [
      {
        team_slug  = "platform-engineering"
        permission = "admin"
      }
    ]
  },
  {
    name                                              = "alz-prod-api-repo"
    description                                       = "ALZ workload repository for example-api-prod"
    visibility                                        = "public"
    branch_protection_required_approving_review_count = 1
    # No collaborators or teams specified - using defaults (empty lists)
  },
  {
    name                                              = "client-demo-test"
    description                                       = "Client demo test repository"
    visibility                                        = "public"
    branch_protection_required_approving_review_count = 1
    # No collaborators or teams specified - using defaults (empty lists)
  },
  {
    name                                              = "graphql-repo"
    description                                       = "ALZ workload repository for graphql (Development)"
    visibility                                        = "internal"
    branch_protection_required_approving_review_count = 1
    teams = [
      {
        team_slug  = "app-dev-team"
        permission = "maintain"
      },
      {
        team_slug  = "platform-engineering"
        permission = "admin"
      }
    ]
  }
  # Add more template-based repositories here
]

# ============================================================================
# Non-template Repositories
# ============================================================================
# Repositories initialized with README only (no template files)
non_template_repositories = [
  {
    name                                              = "github-config"
    description                                       = "GitHub repository configuration managed with Terraform"
    visibility                                        = "public"
    branch_protection_required_approving_review_count = 1
    # Optional: Grant platform team admin access
    collaborators = [
      {
        username   = "nathanjnorris"
        permission = "maintain"
      }
    ]
    teams = [
      {
        team_slug  = "platform-engineering"
        permission = "admin"
      }
    ]
  },
  {
    name                                              = "shared-assets"
    description                                       = "Shared assets and resources"
    visibility                                        = "public"
    branch_protection_required_approving_review_count = 1
    collaborators = [
      {
        username   = "nathanjnorris"
        permission = "maintain"
      }
    ]
    teams = [
      {
        team_slug  = "platform-engineering"
        permission = "admin"
      }
    ]
  }
  # Add more non-template repositories here
]

# ============================================================================
#Common Settings
# ============================================================================

# Copilot firewall allowlist - these domains will be accessible by the Copilot agent
copilot_firewall_allowlist = [
  "registry.terraform.io",
  "checkpoint-api.hashicorp.com",
  "api0.prismacloud.io"
]

# Enable Copilot to create PRs from GitHub Actions
enable_copilot_pr_from_actions = true

# Manage Copilot firewall variable (requires GitHub App with Actions: Read and write permission)
# Set to false if you get "403 Resource not accessible by integration" error
manage_copilot_firewall_variable = true

# Source Repo Sync App ID - GitHub App that syncs files from source repositories
# To find the app ID:
# 1. Go to GitHub Organization Settings → GitHub Apps → source-repo-sync
# 2. Or check the repository variable SOURCE_REPO_SYNC_APP_ID value
# Set to the actual app ID number to enable bypass for branch protection
source_repo_sync_app_id = 2791616
