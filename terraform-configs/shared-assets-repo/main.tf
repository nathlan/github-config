# ============================================================================
# Shared Assets Repository Configuration
# ============================================================================
# This repository is a simple repository initialized with a README and common
# settings. It does NOT use the alz-workload-template and is intended for
# storing shared assets and resources.

resource "github_repository" "shared_assets" {
  name        = var.repository_name
  description = var.repository_description
  visibility  = var.repository_visibility

  # Initialize repository with README
  # This creates a README.md file automatically when the repository is created
  auto_init = true

  # Enable features
  has_issues      = true
  has_discussions = false
  has_projects    = true
  has_wiki        = true

  # Merge settings - common standards
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Squash merge settings
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Security settings
  vulnerability_alerts = true

  # Topics for better discoverability
  topics = ["terraform-managed", "shared-resources"]
}

# Configure GitHub Actions permissions for the repository
resource "github_actions_repository_permissions" "shared_assets" {
  repository = github_repository.shared_assets.name

  # Enable GitHub Actions
  enabled = true

  # Allow all actions to run
  allowed_actions = "all"
}

# Create repository variable for Copilot agent firewall allowlist
# NOTE: Requires GitHub App with "Actions: Read and write" permission
# If you get "403 Resource not accessible by integration" error, set manage_copilot_firewall_variable = false
resource "github_actions_variable" "copilot_firewall_allowlist" {
  count = var.manage_copilot_firewall_variable ? 1 : 0

  repository    = github_repository.shared_assets.name
  variable_name = "COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS"
  value         = join(",", var.copilot_firewall_allowlist)
}

# Configure workflow permissions to allow GitHub Actions to create PRs
resource "github_workflow_repository_permissions" "shared_assets" {
  repository = github_repository.shared_assets.name

  # Set default workflow permissions for GITHUB_TOKEN
  # "read" = read-only access (more secure, recommended)
  # "write" = read-write access
  default_workflow_permissions = "read"

  # Allow GitHub Actions to create and approve pull requests
  can_approve_pull_request_reviews = var.enable_copilot_pr_from_actions
}

# Create branch protection ruleset for main branch
resource "github_repository_ruleset" "main_branch_protection" {
  name        = "Protect main branch"
  repository  = github_repository.shared_assets.name
  target      = "branch"
  enforcement = "active"

  # Apply to main branch
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # Bypass actors - allow GitHub Actions bot to bypass for PR creation
  bypass_actors {
    actor_id    = 5 # Repository admin role
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }

  rules {
    # Prevent deletion of the main branch
    deletion = true

    # Prevent force pushes
    non_fast_forward = true

    # Require pull requests before merging
    pull_request {
      required_approving_review_count   = var.branch_protection_required_approving_review_count
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
    }

    # Require linear history (no merge commits from branches)
    required_linear_history = false
  }
}
