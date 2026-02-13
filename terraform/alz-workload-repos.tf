# ============================================================================
# ALZ Workload Repositories
# ============================================================================
# This file manages workload repositories created from the alz-workload-template
# for Azure Landing Zone (ALZ) workloads. These repositories are provisioned
# via the ALZ vending system and include pre-configured Terraform workflows.
#
# Pattern: Each workload repository is created from the template and configured
# with team access and branch protection specific to the workload requirements.

# ============================================================================
# Repository: alz-prod-api-repo
# ============================================================================
# Workload: example-api-prod
# Team: platform-engineering
# Triggered by: Landing zone provisioning (nathlan/alz-subscriptions)
# Commit: ae22fe04e5dc79b35929df712fc32f1b1659ca96

resource "github_repository" "alz_prod_api_repo" {
  name        = "alz-prod-api-repo"
  description = "Azure Landing Zone repository for example-api-prod workload"
  visibility  = "internal"

  # CRITICAL: Use template repository
  template {
    owner                = "nathlan"
    repository           = "alz-workload-template"
    include_all_branches = false
  }

  # Repository features
  has_issues   = true
  has_projects = false
  has_wiki     = false

  # Merge settings
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  delete_branch_on_merge = true

  # Security settings
  vulnerability_alerts = true

  # Topics for discoverability
  topics = [
    "azure",
    "terraform",
    "example-api-prod"
  ]

  lifecycle {
    prevent_destroy = false
  }
}

# Team access: platform-engineering (admin)
resource "github_team_repository" "alz_prod_api_repo_platform_admin" {
  team_id    = data.github_team.platform_engineering.id
  repository = github_repository.alz_prod_api_repo.name
  permission = "admin"
}

# Branch protection ruleset for main branch
resource "github_repository_ruleset" "alz_prod_api_repo_main_protection" {
  name        = "main-branch-protection"
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

  # Bypass actors - allow platform-engineering team to bypass for critical updates
  bypass_actors {
    actor_id    = data.github_team.platform_engineering.id
    actor_type  = "Team"
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

    # Require status checks before merging
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
