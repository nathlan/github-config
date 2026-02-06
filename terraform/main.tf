# Create GitHub repositories
resource "github_repository" "repos" {
  for_each = { for repo in var.repositories : repo.name => repo }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility

  # Enable features
  has_issues      = true
  has_discussions = false
  has_projects    = true
  has_wiki        = true

  # Auto-initialize the repository with a README
  auto_init = true

  # Merge settings
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
  topics = ["terraform-managed", "infrastructure-as-code"]
}

# Configure GitHub Actions permissions for each repository
resource "github_actions_repository_permissions" "repos" {
  for_each = github_repository.repos

  repository = each.value.name

  # Enable GitHub Actions
  enabled = true

  # Allow all actions to run
  allowed_actions = "all"
}

# Create repository variable for Copilot agent firewall allowlist (consistent across all repos)
resource "github_actions_variable" "copilot_firewall_allowlist" {
  for_each = github_repository.repos

  repository    = each.value.name
  variable_name = "COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS"
  value         = join(",", var.copilot_firewall_allowlist)
}

# Configure workflow permissions to allow GitHub Actions to create PRs
resource "github_workflow_repository_permissions" "repos" {
  for_each = github_repository.repos

  repository = each.value.name

  # Allow GitHub Actions to create and approve pull requests
  can_approve_pull_request_reviews = var.enable_copilot_pr_from_actions
}

# Create branch protection ruleset for main branch on each repository
resource "github_repository_ruleset" "main_branch_protection" {
  for_each = { for repo in var.repositories : repo.name => repo }

  name        = "Protect main branch"
  repository  = github_repository.repos[each.key].name
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
      required_approving_review_count       = each.value.branch_protection_required_approving_review_count
      dismiss_stale_reviews_on_push         = true
      require_code_owner_review             = false
      require_last_push_approval            = false
      required_review_thread_resolution     = false
    }

    # Require linear history (no merge commits from branches)
    required_linear_history = false

    # Optional: Enable Copilot code review for PRs
    # Uncomment if you want automatic Copilot code reviews
    # copilot_code_review {
    #   review_on_push            = true
    #   review_draft_pull_requests = false
    # }
  }
}
