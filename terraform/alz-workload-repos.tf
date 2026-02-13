# ============================================================================
# ALZ Workload Repositories Configuration
# ============================================================================
# This file manages workload repositories created from the alz-workload-template
# for the Azure Landing Zone (ALZ) vending system.
#
# These repositories are created by the ALZ provisioning workflow in the
# nathlan/alz-subscriptions repository and use the alz-workload-template
# as their base template.

# Data source to lookup the platform-engineering team
data "github_team" "platform_engineering" {
  slug = "platform-engineering"
}

# ============================================================================
# alz-prod-api-repo
# ============================================================================
# Repository for example-api-prod workload
# Triggered by: Landing zone provisioning commit ae22fe04e5dc79b35929df712fc32f1b1659ca96

resource "github_repository" "alz_prod_api_repo" {
  name        = "alz-prod-api-repo"
  description = "Workload repository for example-api-prod Azure Landing Zone"
  visibility  = "internal"

  # CRITICAL: Use the alz-workload-template as the base template
  template {
    owner                = "nathlan"
    repository           = "alz-workload-template"
    include_all_branches = false
  }

  # Repository features
  has_issues   = true
  has_projects = false
  has_wiki     = false

  # Merge settings - ALZ standards
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_auto_merge       = false
  delete_branch_on_merge = true

  # Security settings
  vulnerability_alerts = true

  # Topics for discoverability and workload identification
  topics = [
    "azure",
    "terraform",
    "example-api-prod"
  ]
}

# Configure GitHub Actions permissions
resource "github_actions_repository_permissions" "alz_prod_api_repo" {
  repository = github_repository.alz_prod_api_repo.name

  # Enable GitHub Actions
  enabled = true

  # Allow all actions to run
  allowed_actions = "all"
}

# Configure workflow permissions
resource "github_workflow_repository_permissions" "alz_prod_api_repo" {
  repository = github_repository.alz_prod_api_repo.name

  # Set default workflow permissions for GITHUB_TOKEN
  default_workflow_permissions = "read"

  # Allow GitHub Actions to create and approve pull requests
  can_approve_pull_request_reviews = true
}

# Team access: platform-engineering with admin permission
# Note: Using admin permission as specified in requirements
resource "github_team_repository" "alz_prod_api_repo_platform_engineering" {
  team_id    = data.github_team.platform_engineering.id
  repository = github_repository.alz_prod_api_repo.name
  permission = "admin"
}

# Branch protection ruleset for main branch
resource "github_repository_ruleset" "alz_prod_api_repo_main_protection" {
  name        = "Protect main branch"
  repository  = github_repository.alz_prod_api_repo.name
  target      = "branch"
  enforcement = "active"

  # Apply to main branch
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # Bypass actors - allow repository admins to bypass for critical updates
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
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
    }

    # Require status checks to pass before merging
    required_status_checks {
      required_check {
        context = "terraform-plan"
      }
      required_check {
        context = "security-scan"
      }
      strict_required_status_checks_policy = true
    }

    # Require linear history (no merge commits from branches)
    required_linear_history = false
  }
}
